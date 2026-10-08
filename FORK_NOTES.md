# Fork notes

This repository is an **unofficial fork** of [KotatsuApp/Kotatsu](https://github.com/KotatsuApp/Kotatsu).

## Provenance

| | |
|---|---|
| Upstream | https://github.com/KotatsuApp/Kotatsu |
| Imported tag | `v9.4.1` |
| Upstream commit | `06a0b5829b8d5f214d60d5011d66ec1ccbd5630e` |
| Import method | shallow snapshot of the tag's working tree, committed as a single fresh commit (upstream git history is not carried over) |
| License | GPL-3.0 — unchanged, see [`LICENSE`](LICENSE) |
| Version in source | `versionName 9.4.1`, `versionCode 1033` |

The upstream `LICENSE`, `README.md`, translation metadata (`.weblate/`, `metadata/`) and
contributor docs are preserved as-is. Copyright in the imported code remains with the Kotatsu
contributors.

## What this fork changes

Everything below is intentional divergence from upstream v9.4.1. The repo previously held an
unrelated project ("Inkwell", an experimental Keiyoushi/Flutter host) — that work was removed
before this import; it remains recoverable from git history on the former `main` branch.

- `.github/workflows/build.yml` — new CI that runs unit tests and assembles an installable debug
  APK on every push/PR, verified with `apksigner`.
- `.github/workflows/trigger-site-deploy.yml` — **removed**. Upstream-only, it dispatched to
  `KotatsuApp/website` with a secret this fork does not have.
- `README.md` — added the fork banner above; upstream body untouched.
- `FORK_NOTES.md` — this file.

## Not yet changed (candidates)

- Application id / app name are still upstream's (`org.koitharu.kotatsu`), so this and the official
  app cannot be installed side by side.
- No stable release signing key is configured; only debug-signed builds are produced.
- In-app self-update still points at upstream release channels.

## Building

CI builds on Android SDK 36 / build-tools 35.0.0, JDK 17, Gradle 9.0.0 (wrapper). To build locally:

```sh
./gradlew assembleDebug
```

The release build type is minified and **unsigned**; debug builds are debug-signed and installable.
Dependencies resolve from Google Maven, Maven Central and JitPack — the fork vendors no binaries.
