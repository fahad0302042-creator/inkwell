# Fork notes

**Ktv** — an unofficial Android TV / Google TV fork of [Kotatsu](https://github.com/KotatsuApp/Kotatsu).

## Provenance

| | |
|---|---|
| Upstream | https://github.com/KotatsuApp/Kotatsu |
| Imported tag | `v9.4.1` |
| Upstream commit | `06a0b5829b8d5f214d60d5011d66ec1ccbd5630e` |
| License | GPL-3.0 (unchanged — see [`LICENSE`](LICENSE)) |

Imported as a single snapshot commit; upstream git history is not carried over. Copyright in the
code remains with the Kotatsu contributors. Not affiliated with or endorsed by the Kotatsu project.

## Changes from upstream v9.4.1

**Rebrand**

- `res/values/strings.xml` — app label is `Ktv`.
- `app/build.gradle` — `applicationId` is `app.ktv.reader` (`.debug` suffix for debug builds) so the
  fork installs alongside official Kotatsu. `namespace` stays `org.koitharu.kotatsu` as it maps to
  the Kotlin source tree.
- All launcher artwork replaced: adaptive icon foreground (TV screen + play mark, amber on
  transparent) in every density, legacy launcher and round icons for API < 26,
  `launcher_background` is `#1C2029`, and the upstream `.webp` assets are gone.
- `drawable/avd_splash.xml` — the upstream mascot path is replaced by a play mark drawn in the same
  0..432 coordinate space, so the existing circular-reveal animation still works; the animation
  target names no longer reference the upstream mascot.
- Artwork is generated programmatically (Pillow) and is not derived from upstream's assets.

**Android TV / Google TV (stage 1 — launchable)**

- `AndroidManifest.xml` — `android.software.leanback` and `android.hardware.touchscreen` declared
  `required="false"`, a `LEANBACK_LAUNCHER` intent filter was added to `MainActivity`, and
  `android:banner` points at the new `drawable-xhdpi/tv_banner.png` (320×180).
- Result: Ktv appears on the Android TV / Google TV home screen.

**Android TV / Google TV (stage 2 — partly drivable by remote)**

- `core/ui/RemoteFocus.kt` — new; documents and implements the fork's rule that anything clickable
  must also be focusable, so a remote can select it.
- `core/ui/BaseListAdapter.kt` — overrides `onViewAttachedToWindow` to give clickable rows remote
  focus. Every list screen (browse, explore, chapter list, bookmarks, feed) runs through this
  adapter, so one change covers them all. Non-interactive rows (headers, footers, states) stay
  unfocusable so focus cannot get stuck on them.
- `core/ui/widgets/SlidingBottomNavigationView.kt` — navigation items are focusable while the bar
  is visible and unfocusable while it is slid off-screen, so focus cannot land on a hidden control.
- `drawable/ktv_focus_highlight.xml` + `values/colors_ktv.xml` — an amber focus ring, drawn as a
  **foreground** overlay so an item's own background (ripple / surface colour) keeps working.
  Views that already define a foreground are left untouched.
- **Not yet verified on a real device.** Focus ordering between regions, and how the ring reads on
  every background, are unconfirmed.

**Auto-play (TV)**

- `reader/ui/AutoPlayTimer.kt` — new; ticks on the configured interval and mirrors `ScrollTimer`'s
  assisted-injection design. It deliberately knows nothing about pages: it only ticks.
- `reader/ui/ReaderActivity.kt` — decides what a tick means: next page; at the end of a chapter,
  the next chapter if the setting is on; otherwise auto-play stops.
- `reader/ui/ReaderControlDelegate.kt` — the remote's play/pause key (`KEYCODE_MEDIA_PLAY_PAUSE`,
  `MEDIA_PLAY`, `MEDIA_PAUSE`) toggles auto-play, and a toast confirms it, since on a TV there is
  otherwise no feedback that the press registered.
- Settings: `reader_autoplay_interval` (1–30 s) and `reader_autoplay_continue` in reader settings.
- Note: the reader **already** handled D-pad upstream — left/right turn pages, centre toggles the
  UI, up/down switch chapters — so no key mapping was needed for those.

**Reader chrome on a remote**

- `core/ui/RemoteFocus.kt` — `enableRemoteFocusRecursively()` walks a container, makes interactive
  descendants remote-focusable and returns the first one.
- `reader/ui/ReaderActivity.kt` — when the chrome becomes visible its controls are made focusable
  and focus is handed to the first control, so the D-pad has a starting point; hiding the chrome
  clears focus so page-turn keys are not swallowed.
- `reader/ui/ReaderActivity.kt` — **TV-only** BACK handling: back closes the reader chrome before
  leaving the reader. Without it, once focus is inside the bar there is no way out short of
  clicking something. Gated on the `leanback` feature, so phone back behaviour is unchanged.
- `res/layout/layout_reader_actions.xml` — the page slider is focusable, so it can be reached and
  adjusted with the D-pad.

**Self-update**

- `core/os/AppValidator.kt` — the trusted certificate is now this fork's release certificate, so
  signed Ktv builds are treated as official by the update system (and upstream APKs can no longer
  be installed over the app).
- `res/values/constants.xml` — `github_updates_repo` points at this fork, and sync provider
  authorities were moved off the upstream ids.
- `app/build.gradle` — release builds are signed from `KEYSTORE_FILE` / `KEYSTORE_PASSWORD` /
  `KEY_ALIAS` / `KEY_PASSWORD` env vars when present; otherwise the release stays unsigned.
- Version stamping via `-PktvVersionName` / `-PktvVersionCode`.

**Build infrastructure**

- `.github/workflows/build.yml` — **added**: unit tests and APK assembly on every push/PR, with
  apksigner verification plus a package-name assertion (this must be the Ktv fork, not upstream).
- `.github/workflows/release.yml` — **added**: builds a signed release APK and publishes it as a
  GitHub Release, which is what the in-app updater reads. Requires the four signing secrets.
- `.github/workflows/trigger-site-deploy.yml` — **removed**: upstream-only, dispatched to
  `KotatsuApp/website` with a secret this fork does not have.

## Required one-time setup (not done by the agent)

Add these repository secrets under **Settings → Secrets and variables → Actions**:

| Secret | Value |
|---|---|
| `KEYSTORE_BASE64` | base64 of the fork's `.p12` keystore |
| `KEYSTORE_PASSWORD` | keystore password |
| `KEY_ALIAS` | `ktv` |
| `KEY_PASSWORD` | same as `KEYSTORE_PASSWORD` |

Until they exist, `Release` fails on purpose with a message pointing here. The `Build` workflow
needs no secrets.

## Installing and updating

1. Install the **release APK** from the repo's Releases page on the TV
   (`adb install ktv.apk`, or a sideload launcher). Debug APKs cannot update a release install —
   different signing key.
2. Later releases install over it in place: Ktv checks
   `github.com/fahad0302042-creator/inkwell/releases` and offers the update.
3. **Release names must be plain numeric semver** (`v9.5.0`). `VersionId` treats a suffix such as
   `-ktv1` as an unstable variant, and unstable releases are hidden unless the user enables
   unstable updates — a suffixed release would never be offered.

## Not done yet

- **Dialogs and bottom sheets.** Lists, the bottom bar and the reader chrome are remote-reachable;
  dialogs, bottom sheets (including the reader config sheet), the search bar and the floating
  action button have not been adapted.
- **Auto-play has no on-screen button.** It is toggled by the remote's play/pause key, which the
  current TV remote has; an on-screen control would need the reader chrome to stay visible.
- **App icon and TV banner** — replaced with fork artwork (see "Rebrand" above). The TV banner
  itself cannot be animated: the Android TV home screen only accepts a static 320×180 image.
  The launch splash *is* animated.
- **Nothing has been verified on a real device yet.** Focus ordering between regions, how the focus
  ring reads on each background, and whether the chrome's default focus target feels right are all
  unconfirmed.

## Building

CI uses Android SDK 36 / build-tools 35.0.0, JDK 17 and the Gradle 9.0.0 wrapper. Locally:
`./gradlew assembleDebug`. Dependencies resolve from Google Maven, Maven Central and JitPack; no
binaries are vendored.
