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
- **Not yet verified on a real device.** Rely on the framework's default focus highlight
  (API 26+); whether it is visible enough on every row background is unconfirmed.

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

- **D-pad navigation beyond lists.** Rows and the bottom bar are reachable, but dialogs, bottom
  sheets, the search bar and the floating action button have not been adapted, and focus ordering
  between regions is untested on a device.
- **Reader on a remote.** No key mapping for page turns yet; the reader is driven by
  `ViewPager2` swipes and taps.
- **Auto-play / auto-advance.** Upstream has auto-scroll (`readerAutoscrollSpeed`, `ScrollTimer`)
  as a starting point; a paged auto-play option does not exist yet. Agreed behaviour: advance pages
  on a timer, with a setting for whether it continues into the next chapter.
- **App icon and animated TV banner.** Only the launcher banner was added; the icon is still
  upstream's.

## Building

CI uses Android SDK 36 / build-tools 35.0.0, JDK 17 and the Gradle 9.0.0 wrapper. Locally:
`./gradlew assembleDebug`. Dependencies resolve from Google Maven, Maven Central and JitPack; no
binaries are vendored.
