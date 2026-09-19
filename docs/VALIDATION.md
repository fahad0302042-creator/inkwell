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

## Not verified

- No physical Android device or Android emulator was used.
- A local Gradle APK build was attempted, but could not complete within the workspace's 2 GB memory limit. **No APK is included and Android compilation is not claimed as passed.**
- The GitHub Actions workflow has been pushed and a run was requested, but its build job did not start. No successful GitHub APK build has been verified. A green workflow run is required before treating APK compilation as verified.
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
