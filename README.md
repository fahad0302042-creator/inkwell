# Inkwell 0.2 — experimental Keiyoushi host

Android-first Flutter comic reader with a Kotlin source runtime.

**First real-APK milestone passed:** Keiyoushi **xkcd 1.4.17, English** loaded and served catalogue, details, chapters, cover and comic/text-image pages on an Android 15 emulator. **This is not a blanket claim of compatibility with every Keiyoushi extension.**

## Download and try

- [Verified 0.2 APK build](https://github.com/fahad0302042-creator/inkwell/actions/runs/35476982042) → **Artifacts → Inkwell-test-APKs**.
- Choose `app-arm64-v8a-debug.apk` for most current Android phones. ARM32 and x86-64 builds are also included. Minimum Android version: 7.0 / API 24.
- [Keiyoushi installation and testing guide](docs/KEIYOUSHI_TESTING.md).
- [Passing real-extension emulator tests](https://github.com/fahad0302042-creator/inkwell/actions/runs/35476981105).

These are debug-signed builds. Updating from an older build may require uninstalling it due to changing debug keys; **uninstalling deletes its local data**. Stable release signing is not configured. GitHub artifacts expire after 14 days; workflows can generate new ones.

## Implemented

- Original offline sample library, details, saved titles, filters, history and progress.
- RTL, LTR and vertical reading modes, zoom and dark theme.
- System-installed extension discovery and API 1.4 / 1.6 experimental host targets.
- Explicit trust tied to package, signing certificates, version and exact APK hash; changed APKs require new approval.
- Read-only APK snapshots, Source / SourceFactory loading and required host interfaces/models.
- Context, preferences, JSON, cookies and network services.
- Native popular/latest/search dispatch, details, chapters, page descriptors and image bytes using the source's own client.
- Live-source browse/details/reader screens, pagination, errors/retries and saved chapter positions.
- Certificate inspection, trust revocation and official extension-listing shortcut.
- GitHub APK build and Android emulator testing workflows.

## Verified scope

- **15 Flutter tests** pass; static analysis is clean.
- **1 native networking regression test** passes (preserves Host/encoding/cookie headers through the progress wrapper).
- **2 Android emulator tests** pass, exercising a real installed xkcd APK and negative trust cases.
- xkcd intentionally returns no text-search matches. Use **Popular** for this source; the host does not invent search results.
- API 1.6, other extensions, other languages, interactive xkcd comics and physical phones remain unverified.

See [docs/VALIDATION.md](docs/VALIDATION.md) for pinned versions, hashes and exact evidence.

## Remaining

Remote-title library/database, source preference and custom-filter UI, JavaScript, verification-page interaction, download queue, extension repository/index management, in-app installation/updates, private extension import, background chapter updates and stable production signing.

The main Library tab still manages bundled samples. Live titles are accessed through Browse → Extensions. Source chapter positions are stored locally, but adding those titles to the main library is not implemented.

## Security and distribution

Extension APKs run **in-process with the app's permissions, not in a sandbox**. Only trust publishers you are willing to grant access to app data and networking. Revoking trust blocks new host calls; restart Inkwell to fully unload code already started. There is no automatic trust or APK installation.

`QUERY_ALL_PACKAGES` enables arbitrary system-extension discovery and is restricted by Google Play policy; this prototype is for sideloading/development. Internet permission enables source requests. Package information stays on-device; there is no account/analytics service. Android backup is disabled.

No automatic challenge solving or access-control bypass is implemented. Images are capped at 16 MB and page lists at 2,000 pages in this preview. Expired native session handles require reopening a title from the source.

## Build

Flutter **3.47.5**, Dart **3.13.4**, Java **21** (JVM bytecode target 17). Android toolchain versions are chosen by Flutter.

```sh
flutter pub get --enforce-lockfile
flutter analyze
flutter test
flutter build apk --debug --split-per-abi
```

Workflows:
- `Build Android APK`: analysis, Flutter tests, APK compilation and artifacts.
- `Keiyoushi runtime smoke test`: native networking regression and real installed-extension tests on Android 35. It downloads a pinned, hash-checked xkcd APK into the test runner only.

[Phone-only setup](docs/PHONE_SETUP.md) is available for creating another repository without a PC. No personal token is required by either workflow. Never commit a token, signing password or keystore.

## Architecture and licences

- `lib/core/`: sample state and persistence.
- `lib/features/source_screens.dart`: live browse/details/reader screens.
- `lib/platform/extensions.dart`: typed Dart method-channel contract.
- `android/.../runtime/`: APK inspection, trust, class loading, native object handles and source operations.
- `android/.../eu/kanade/tachiyomi/`: host API, models and network compatibility.

Mihon API sources are pinned and adapted under Apache-2.0; [third-party notices](THIRD_PARTY_NOTICES.md) and licence text are retained. Lora and DM Sans fonts use SIL OFL 1.1; licences are bundled and shown in-app. Other dependencies retain their licences. Original sample PNGs are generated by `tools/draw_samples.py`; no third-party manga scans or extension APKs are bundled in Inkwell.
