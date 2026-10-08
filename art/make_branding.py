#!/usr/bin/env python3
"""Fork (Ktv): regenerate every branding asset from art/mascot.png.

Run from the repository root:

    python3 art/make_branding.py

Writes:
  app/src/main/res/mipmap-*/ic_launcher.png, ic_launcher_round.png, ic_launcher_foreground.png
  app/src/nightly/res/mipmap-*/   (same three files)
  app/src/main/res/drawable-xhdpi/tv_banner.png        320x180 Android TV home screen banner

The Android 12+ splash icon is not generated here: it points at @mipmap/ic_launcher, so it reuses
the adaptive icon above.

Requires: Pillow, numpy, scipy.

Notes for whoever edits this next:
  * The adaptive icon foreground must keep the mascot inside the middle 66/108 of the canvas or the
    system's mask clips it. That is the FOREGROUND_SCALE factor below.
  * Legacy icons for API < 26 are not masked by the system, so the background is baked in there.
    The gradient therefore exists twice: here and in drawable/ktv_icon_background.xml. Change both.
"""

from PIL import Image, ImageDraw, ImageFont
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, "app", "src", "main", "res")

NAVY = (28, 32, 41)
NAVY_DARK = (16, 18, 24)
CREAM = (232, 226, 212)
AMBER = (255, 213, 79)

# density -> (legacy icon px, adaptive foreground px)
DENSITIES = {
    "mdpi": (48, 108),
    "hdpi": (72, 162),
    "xhdpi": (96, 216),
    "xxhdpi": (144, 324),
    "xxxhdpi": (192, 432),
}

FOREGROUND_SCALE = 0.60  # of the 108-unit adaptive canvas, inside the 66-unit safe zone
LEGACY_SCALE = 0.74
BADGE_SCALE = 0.22  # corner radius of the legacy rounded-square, as a fraction of its size
TV_BANNER_SCALE = 0.78

FONT_BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
FONT_REGULAR = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"


def gradient(size, top, bottom):
    w, h = size
    strip = Image.new("RGB", (1, h))
    draw = ImageDraw.Draw(strip)
    for y in range(h):
        t = y / max(1, h - 1)
        draw.point((0, y), fill=tuple(round(top[i] + (bottom[i] - top[i]) * t) for i in range(3)))
    return strip.resize((w, h), Image.BILINEAR)


def fit(image, size):
    """Scale to fit inside a square of `size` px, preserving aspect ratio."""
    scale = min(size / image.width, size / image.height)
    return image.resize(
        (max(1, round(image.width * scale)), max(1, round(image.height * scale))),
        Image.LANCZOS,
    )


def paste_center(canvas, image):
    canvas.alpha_composite(image, ((canvas.width - image.width) // 2, (canvas.height - image.height) // 2))


def load_font(size, bold=True):
    try:
        return ImageFont.truetype(FONT_BOLD if bold else FONT_REGULAR, size)
    except OSError:
        return ImageFont.load_default()


def masked_background(size, radius_ratio, circle=False, supersample=4):
    """Navy gradient background, masked to the legacy icon's shape."""
    w, h = size
    s = w * supersample
    mask = Image.new("L", (s, s), 0)
    draw = ImageDraw.Draw(mask)
    if circle:
        draw.ellipse([0, 0, s - 1, s - 1], fill=255)
    else:
        draw.rounded_rectangle([0, 0, s - 1, s - 1], radius=round(s * radius_ratio), fill=255)
    mask = mask.resize((w, h), Image.LANCZOS)
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    out.paste(gradient((w, h), NAVY, NAVY_DARK).convert("RGBA"), (0, 0), mask)
    return out


def main():
    mascot = Image.open(os.path.join(ROOT, "art", "mascot.png")).convert("RGBA")

    for density, (legacy_size, foreground_size) in DENSITIES.items():
        target = os.path.join(RES, f"mipmap-{density}")
        os.makedirs(target, exist_ok=True)
        for stale in os.listdir(target):
            if stale.startswith("ic_launcher"):
                os.remove(os.path.join(target, stale))

        foreground = Image.new("RGBA", (foreground_size, foreground_size), (0, 0, 0, 0))
        paste_center(foreground, fit(mascot, round(foreground_size * FOREGROUND_SCALE)))
        foreground.save(os.path.join(target, "ic_launcher_foreground.png"))

        for name, circle in (("ic_launcher.png", False), ("ic_launcher_round.png", True)):
            canvas = masked_background((legacy_size, legacy_size), BADGE_SCALE, circle=circle)
            paste_center(canvas, fit(mascot, round(legacy_size * LEGACY_SCALE)))
            canvas.save(os.path.join(target, name))

        nightly = os.path.join(ROOT, "app", "src", "nightly", "res", f"mipmap-{density}")
        os.makedirs(nightly, exist_ok=True)
        for name in ("ic_launcher.png", "ic_launcher_round.png", "ic_launcher_foreground.png"):
            Image.open(os.path.join(target, name)).save(os.path.join(nightly, name))
            webp = os.path.join(nightly, name.replace(".png", ".webp"))
            if os.path.exists(webp):
                os.remove(webp)
        print(f"  {density}: legacy {legacy_size}px, foreground {foreground_size}px")

    # Android TV home screen banner: static 320x180, the only size the launcher accepts
    width, height = 320, 180
    banner = gradient((width, height), NAVY, NAVY_DARK).convert("RGBA")
    mark = fit(mascot, round(height * TV_BANNER_SCALE))
    banner.alpha_composite(mark, (round(width * 0.045), (height - mark.height) // 2))
    draw = ImageDraw.Draw(banner)
    text_x = round(width * 0.045) + mark.width + round(width * 0.035)
    big, small = load_font(58), load_font(19)
    box = draw.textbbox((0, 0), "Ktv", font=big)
    draw.text((text_x, (height - (box[3] - box[1])) / 2 - box[1] - 12), "Ktv", font=big, fill=CREAM)
    draw.text((text_x + 4, height * 0.63), "MANGA FOR TV", font=small, fill=AMBER)
    banner.convert("RGB").save(os.path.join(RES, "drawable-xhdpi", "tv_banner.png"))
    print("  tv_banner.png: 320x180")


if __name__ == "__main__":
    main()
