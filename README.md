# Inkwell

An Android-first Flutter comic-reader **development starter**, with a Kotlin bridge for inspecting system-installed Mihon/Tachiyomi-style extension APKs.

**Version 0.2 is an experimental source host, not a complete Mihon replacement.** It adds trust-gated extension execution, live source browsing and reading. Compatibility must be established per extension; see `docs/VALIDATION.md`. Source filters/settings UI, downloads and the remote-title library are not implemented.

## Previous 0.1 APK (no source execution)

[Successful Android build and APK artifacts](https://github.com/fahad0302042-creator/inkwell/actions/runs/35444820603)

Open **Artifacts → Inkwell-test-APKs**, extract the ZIP, and use `app-arm64-v8a-debug.apk` for most current Android phones. Android 7.0+ is required. ARM32 and x86-64 builds are also included. Artifacts expire after 14 days; the workflow can generate new builds.

The linked build is the older 0.1 starter. Do not use it to test the new 0.2 runtime. See the latest Actions run for a new APK and `docs/VALIDATION.md` for its verified status.

## What works

- Adaptive library with saved titles and All / Reading / Unread / Finished filters.
- Search over bundled sample titles and genres.
- Title details and save/remove actions.
- Four original concept covers and **one shared four-page illustrated story**, included offline and explicitly labelled as samples.
- Right-to-left, left-to-right and vertical readers, pinch zoom, page navigation and control hiding.
- Persistent reading position, recently read list, theme and reader preferences.
- Confirmation before clearing local data.
- Discovery and explicit trust-gated loading of installed APKs declaring `tachiyomi.extension`.
- Experimental live source browsing, details, chapter lists and source-authenticated image reading.
- Source reading positions saved independently of the bundled sample library.
- Extension package/version/entry-point metadata and SHA-256 signing-certificate fingerprints. Trust is granted only after an explicit APK-specific approval.
- Android system-settings shortcut, rescan button and rescan when returning to the extension screen.
- GitHub Actions: static analysis, tests, and separate debug APKs for ARM64, ARM32 and x86-64.

## Phone-only build — no PC or token required

Read **[docs/PHONE_SETUP.md](docs/PHONE_SETUP.md)**. Upload `inkwell-source.zip` unchanged to GitHub, then create one workflow file in the browser. The workflow extracts the ZIP on GitHub's runner. GitHub does **not** automatically extract uploaded ZIPs into a repository.

No personal access token or repository secret is required. The workflow uses GitHub's automatically provided read-only repository token. It does not edit your repository or publish a release.

## Toolchain

- Flutter **3.47.5**, Dart **3.13.4** (pinned in CI).
- Java **21** for Gradle; app JVM bytecode target 17.
- Android SDK/NDK versions selected by this Flutter version.
- Minimum Android **7.0 / API 24**.
- Riverpod for state; SharedPreferences for the small starter's local state.

A production catalogue and download queue should migrate to SQLite/Drift; preferences are not a production catalogue database.

### Optional local commands

```sh
flutter pub get --enforce-lockfile
flutter analyze
flutter test
flutter run
flutter build apk --debug --split-per-abi
```

APK outputs: `build/app/outputs/flutter-apk/`.

## Architecture

```text
lib/
  core/catalog.dart       Original sample catalogue
  core/store.dart         Library / history / reader persistence
  features/shell.dart     Library, Browse, History, adaptive navigation
  features/details.dart   Title details and library actions
  features/reader.dart    Paged/vertical reading and zoom
  features/extensions_screen.dart
  features/settings.dart
  platform/extensions.dart     Typed Dart-side discovery bridge
android/app/src/main/kotlin/dev/inkwell/inkwell/MainActivity.kt
  Method-channel dispatch to the experimental native runtime
```

Channel: `dev.inkwell/extensions`. Implemented calls: `listInstalled`, `openAppSettings`, `capabilities`. Source execution uses native session handles; errors and missing host APIs are surfaced explicitly. See [docs/EXTENSION_RUNTIME.md](docs/EXTENSION_RUNTIME.md).

## Permissions and distribution

`QUERY_ALL_PACKAGES` is requested to discover arbitrary extension package names. This broad visibility is restricted by Google Play policy; approval is not guaranteed. This is a sideload/development design. A future import-based design may avoid this permission. Package information stays on the device. Backups are disabled; there is no analytics or account service.

The app does not download/install extensions, request APK-install permission, or automatically trust discovered packages. Install only APKs from developers you trust.

CI produces **debug-signed test APKs**. Clean runners can create different debug signing keys. Installing over an earlier build may fail; uninstalling removes its library and progress. Production releases need a stable private keystore and a deliberate release-signing setup. Never commit a keystore, personal token or signing password.

## Remaining after the 0.2 runtime prototype

1. Establish the real-APK Android test matrix, starting with Keiyoushi xkcd.
2. Add source settings, custom filters and interactive verification where appropriate.
3. Add a database-backed remote library, persistent downloads and background updates.
4. Expand compatibility using device evidence, rather than promising every extension.
5. Configure stable private release signing and physical-device testing.

See [docs/VALIDATION.md](docs/VALIDATION.md) for verification and remaining limitations.

## Notices

Lora and DM Sans fonts use SIL Open Font License 1.1. Their licence files are in `assets/fonts/` and registered on the in-app licence page. Flutter packages retain their own licences.

Original sample artwork/story: `tools/draw_samples.py` (Pillow and DejaVu fonts are needed only to regenerate PNGs). No manga scans or extension binaries are bundled. Selected Mihon source API implementations are included under Apache-2.0; see `THIRD_PARTY_NOTICES.md`.
