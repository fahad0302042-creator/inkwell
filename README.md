# Inkwell

An Android-first Flutter comic-reader **development starter**, with a Kotlin bridge for inspecting system-installed Mihon/Tachiyomi-style extension APKs.

**Not a complete Mihon replacement. It cannot run extension sources yet.** This milestone has no live manga search, remote chapter fetching, download engine or extension repository installer. No third-party extension code is executed.

## What works

- Adaptive library with saved titles and All / Reading / Unread / Finished filters.
- Search over bundled sample titles and genres.
- Title details and save/remove actions.
- Four original concept covers and **one shared four-page illustrated story**, included offline and explicitly labelled as samples.
- Right-to-left, left-to-right and vertical readers, pinch zoom, page navigation and control hiding.
- Persistent reading position, recently read list, theme and reader preferences.
- Confirmation before clearing local data.
- Native discovery of system-installed APKs declaring `tachiyomi.extension`.
- Extension package/version/entry-point metadata and SHA-256 signing-certificate fingerprints. These are informational; **no trust has been granted**.
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
  Native package inspection; no source execution
```

Channel: `dev.inkwell/extensions`. Implemented calls: `listInstalled`, `openAppSettings`, `capabilities`. Source calls deliberately return `RUNTIME_NOT_IMPLEMENTED`. See [docs/EXTENSION_RUNTIME.md](docs/EXTENSION_RUNTIME.md).

## Permissions and distribution

`QUERY_ALL_PACKAGES` is requested to discover arbitrary extension package names. This broad visibility is restricted by Google Play policy; approval is not guaranteed. This is a sideload/development design. A future import-based design may avoid this permission. Package information stays on the device. Backups are disabled; there is no analytics or account service.

The app does not download/install extensions, request APK-install permission, or automatically trust discovered packages. Install only APKs from developers you trust.

CI produces **debug-signed test APKs**. Clean runners can create different debug signing keys. Installing over an earlier build may fail; uninstalling removes its library and progress. Production releases need a stable private keystore and a deliberate release-signing setup. Never commit a keystore, personal token or signing password.

## Next milestone

1. Select one openly licensed extension and host API version as a compatibility target.
2. Implement its JVM host API and expected dependencies, including Source and SourceFactory.
3. Add explicit certificate-based trust and re-validation on update.
4. Test source listing, search, details, chapters, pages and authenticated image requests on Android.
5. Add a database-backed library, persistent downloads, cancellation/retries and background updates.
6. Expand a tested compatibility matrix rather than promising every extension.

See [docs/VALIDATION.md](docs/VALIDATION.md) for verification and remaining limitations.

## Notices

Lora and DM Sans fonts use SIL Open Font License 1.1. Their licence files are in `assets/fonts/` and registered on the in-app licence page. Flutter packages retain their own licences.

Original sample artwork/story: `tools/draw_samples.py` (Pillow and DejaVu fonts are needed only to regenerate PNGs). No manga scans, extension binaries or Mihon runtime source code are bundled. Consult upstream licences before reusing source-engine code.
