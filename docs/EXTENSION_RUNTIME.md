# Experimental Keiyoushi host (0.2)

## Implemented, awaiting the device-test matrix below

- Vendored, pinned Mihon source API implementations (not the throwing compile stubs), with Apache-2.0 notices preserved.
- API declarations 1.4 and 1.6 accepted as experimental targets. This does not mean every extension is compatible.
- Android package discovery, Source / SourceFactory class loading, semicolon-separated entry points.
- Explicit trust bound to package, version, signing certificates AND SHA-256 of the APK. Changes require new approval.
- Read-only verified APK snapshot before loading. No extension code is initialized during discovery.
- Source-scoped preferences, Application / Context / Json / NetworkHelper injection, OkHttp networking and cookie support.
- Native popular/latest/search, manga details, chapters, page descriptors and image bytes through the source's own client.
- Live Flutter browse/details/reader screens, retries, pagination and locally saved chapter positions.
- Images are limited to 16 MB and page lists to 2,000 pages for this preview.
- Revocation blocks further host calls. Restart the app to fully unload third-party code already started.

Channel `dev.inkwell/extensions`, protocol version 2:
`listInstalled`, `trustAndLoad`, `revokeTrust`, `sources`, `search`, `details`, `chapters`, `pages`, `image`, `capabilities`, `openAppSettings`, `openExtensionWebsite`.

Source IDs travel as strings. Manga/chapter/page objects stay in native session handles, retaining source-specific metadata. Handles can expire when the app process restarts; reopen the title from the source if that happens.

## Important security boundary

This is **in-process executable APK loading, not a sandbox**. A trusted extension has the app's permissions and can access its data/network. Pinning an APK hash prevents silent replacement; it does not make arbitrary code safe. No APK is automatically trusted and no APK installer is built into Inkwell.

The source client respects its headers, interceptors and cookies. There is no automatic verification-page solving or JavaScript engine; these sources may fail and should be reported as unsupported. The compatibility layer does not bypass source access controls.

## First real-APK test target

- Keiyoushi xkcd `1.4.17`, package `eu.kanade.tachiyomi.extension.all.xkcd`, English source.
- APK SHA-256: `74ef6fb112925b86ec44f30624a0cb5b0451095cfc7f1a34a853132c6cc1da99`.
- The emulator workflow downloads that exact public APK and checks its hash before installation.
- The test must prove: untrusted load rejected; stale trust rejected; trust + SourceFactory load; live search; details; cover; chapter list; page descriptors; actual image bytes; revocation blocks calls.
- Passing the Flutter mocked bridge test alone does NOT prove APK compatibility. Consult `docs/VALIDATION.md` for actual device-test results.

## Not implemented

Extension repository indexing/install/update management (the app opens the official listing in your browser), source settings UI, custom filters UI, JavaScript, verification-page interaction, native non-HttpSource image loading, offline download queue, remote-title library database, background updates, cloud sync and stable production signing.

The new Keiyoushi repository advertises a compressed Protobuf index. The old JSON index now contains app-update notices. Inkwell does not misinterpret those notices as manga sources.

## Provenance

Mihon host API pin: `424bbc53b85c19acd3c3b7c03ec6f73f516f25bc`.
Keiyoushi source inspected at `9137b65daada0b328a05e7c3ce8c4490bbd90dac`.
See `THIRD_PARTY_NOTICES.md` and `tools/vendor_host_api.py`.
