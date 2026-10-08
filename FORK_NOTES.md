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
code remains with the Kotatsu contributors. This fork is **not affiliated with or endorsed by**
the Kotatsu project — report fork bugs here, not upstream.

## Changes from upstream v9.4.1

Required by the rebrand:

- `app/src/main/res/values/strings.xml` — app label is now `Ktv`.
- `app/build.gradle` — `applicationId` is `app.ktv.reader` (`.debug` suffix for debug builds), so
  this app can be installed alongside official Kotatsu. `namespace` intentionally remains
  `org.koitharu.kotatsu` because it maps to the Kotlin source tree.
- `app/src/main/res/values/constants.xml` — sync provider authorities moved to the new id to avoid
  colliding with official Kotatsu.

Build infrastructure:

- `.github/workflows/build.yml` — **added**. Unit tests and APK assembly on every push/PR, with
  `apksigner` verification and APK artifacts.
- `.github/workflows/trigger-site-deploy.yml` — **removed**. Upstream-only; it dispatched to
  `KotatsuApp/website` with a secret this fork does not have.

## Known consequences of the rebrand (not yet handled)

- **In-app updater**: `github_updates_repo` still points at `KotatsuApp/Kotatsu`, and update
  checks on release builds are gated behind `AppValidator` requiring upstream's signing
  certificate. Until both are addressed, self-update cannot work here.
- **Signing**: CI currently produces debug-signed builds from a per-run debug keystore, so a new
  build cannot install over an older one. A stable keystore is required for updates to work.
- **No TV support yet**: no `leanback` launcher entry, no banner, and the UI is touch-oriented.
  See the TV port stages in the project plan.

## Building

CI builds with Android SDK 36 / build-tools 35.0.0, JDK 17 and the Gradle 9.0.0 wrapper.
Locally: `./gradlew assembleDebug`. Dependencies come from Google Maven, Maven Central and
JitPack; no binaries are vendored.
