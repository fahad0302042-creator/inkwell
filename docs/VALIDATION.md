# Version 0.2 verification

## Build and source revision

Verified source: `6b6f0f317a2ae3bd3905cd88751be9bb805c910e`.

- [APK build: passed](https://github.com/fahad0302042-creator/inkwell/actions/runs/35476982042)
- [Native and Android emulator tests: passed](https://github.com/fahad0302042-creator/inkwell/actions/runs/35476981105)
- The repository's later documentation-only commit does not change the tested application code.
- ARM64 APK SHA-256: `b8bf6a3a306f3315d39ec5549cc7b68535afb5a5c29ea6f45182330fd88c226f`.
- APK archive integrity and ARM64 Flutter payload verified after downloading from GitHub.
- APK minimum Android API: 24; instrumentation device: API 35 (Android 15), x86-64 emulator. No physical-phone execution is claimed.

## Flutter: 15 passing tests

Original library/reader/history/settings tests, serialization and corrupt-storage recovery, persistence/reset, bridge decoding/errors, string transport for 64-bit source IDs, reviewed APK-identity transmission, and a **mocked** live-source UI flow from catalogue through reader with saved progress.

Flutter analysis: no issues found. Mocked Flutter tests are not used as proof of actual extension compatibility.

## Native JVM: 1 passing networking regression test

A MockWebServer test confirms that the source image progress wrapper preserves the real network request's Host, Cookie and Accept-Encoding headers and reports byte progress. An earlier implementation incorrectly reused the pre-bridge request and received HTTP 421 during real image testing. The final implementation preserves `chain.request()`; the fix is covered by this regression.

## Real Android APK: 2 passing instrumentation tests

The emulator installed the **actual Keiyoushi xkcd 1.4.17 APK**, not a rewritten source or mock:

- Package: `eu.kanade.tachiyomi.extension.all.xkcd`.
- Language exercised: English.
- Extension API: 1.4.
- APK SHA-256: `74ef6fb112925b86ec44f30624a0cb5b0451095cfc7f1a34a853132c6cc1da99`.
- Download URL and hash are pinned in `tools/fetch_smoke_extension.py`.

### Negative trust test

- Installed package detected without executing it.
- Untrusted source loading rejected.
- Stale/mismatched APK-identity approval rejected.

### Real source-flow test

- User-equivalent explicit test trust and real SourceFactory loading.
- English source selection and source-ID handling.
- Search dispatch: xkcd deliberately returns an empty result; this is respected, not replaced with fabricated matches.
- Popular browsing returns a real title.
- Manga details and source-authenticated cover bytes.
- A real chapter list containing more than ten entries.
- Page descriptors for the first comic.
- Both the comic image and extension-generated text-image bytes returned successfully.
- Revocation blocks subsequent host source calls.

The final device report records **2 tests, 0 failures, 0 errors, 0 skipped**. Native runtime behavior was tested directly through the same runtime used by the Flutter channel; physical-device UI interaction remains unverified.

## Not verified / not implemented

- Other Keiyoushi extensions, API 1.6 sources, other xkcd translations, interactive comics, older Android releases and physical devices.
- The source preference/filter UI, JavaScript, verification-page interaction, network downloads, private extension imports and remote-title library/database are not implemented.
- Production signing, long-running background behavior and security isolation are not implemented. Third-party code executes with host app privileges.

## Previous milestone

The older 0.1 APK at [run 35444820603](https://github.com/fahad0302042-creator/inkwell/actions/runs/35444820603) is a sample-reader/discovery-only build. It must not be used to test source execution.
