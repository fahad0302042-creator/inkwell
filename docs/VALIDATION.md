# Verification record

## Passed in the development workspace

- Flutter 3.47.5 / Dart 3.13.4 dependency resolution.
- `flutter analyze --no-pub`: **no issues found**.
- `flutter test --no-pub`: **12 tests passed**.
- GitHub workflow syntax checked with `actionlint 1.7.7`: **passed**.

Test coverage:

1. Phone library → reader → page navigation → saved history.
2. Small 320×640 layout and no-match sample search.
3. Wide layout and explicit extension-runtime status.
4. Switching RTL → vertical → LTR preserves the current page.
5. Theme setting and cancelling the reset confirmation.
6. Vertical reading through to the final page.
7. State serialization round trip.
8. Recovery from corrupt preferences.
9. Bookmark/progress/theme/mode persistence and reset.
10. Dart method-channel decoding of Android metadata (mocked native response).
11. Non-Android platforms do not invent extension results.
12. Native bridge errors are surfaced, not silently converted to empty lists.

## Successful GitHub APK build

- Repository: https://github.com/fahad0302042-creator/inkwell
- Run: https://github.com/fahad0302042-creator/inkwell/actions/runs/35444820603
- Built source commit: `cb60c16a4f102cff4be95f54e14523865a385cef`.
- Build completed successfully on 2026-09-19. Dependency installation, analysis, all 12 tests and Android compilation passed.
- Separate ARM64, ARM32 and x86-64 debug APKs were uploaded as **Inkwell-test-APKs**. GitHub retains these artifacts for 14 days; rerun the workflow after expiration.
- ARM64 APK signature verified with Android SDK `apksigner`.
- APK metadata: `dev.inkwell.inkwell`, version `0.1.0`, minimum API 24 (Android 7.0), target API 36.
- ARM64 APK SHA-256: `5daacd4d3acdf0c3ba29408a2ac2e206fe78c91d25d152d93997bd7691b32519`.

These are debug-signed development builds, not production releases. The successful compile does not imply that extension-source execution exists.

## Remaining unverified areas

- No physical Android device or Android emulator was used.
- The earlier local Gradle attempt exceeded the workspace memory limit. Android compilation was subsequently verified on GitHub as recorded above.
- Native installed-extension discovery must still be tested on an Android device with a known extension APK. Dart bridge tests use mock messages, not an installed extension.
- Extension source execution is not implemented, so there is no source compatibility claim.

## Suggested Android acceptance test after the first green GitHub build

1. Install the matching ABI test APK on Android 7.0+.
2. Check both themes and all four navigation destinations.
3. Read a sample, close/reopen the app, and verify the saved page.
4. Try RTL, LTR, vertical scrolling and pinch zoom.
5. Add/remove a sample title and verify filters/history.
6. Browse → Extensions: compare detected packages with those installed on the device.
7. Verify displayed signing fingerprints independently before any future trust implementation.
8. Install/remove an extension using Android's installer, return to the Extensions screen and rescan.
9. Test clear-data confirmation. Uninstalling the app or using Reset deletes local reading state.

Production readiness additionally requires stable signing, a source engine, security/licence review, database-backed storage, durable downloads, accessibility testing and broader Android device testing.
