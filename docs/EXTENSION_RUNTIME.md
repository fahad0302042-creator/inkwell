# Extension runtime: implementation boundary

## Implemented

Kotlin reads installed-package metadata through Android's PackageManager on a worker thread. A package must declare the `tachiyomi.extension` feature. Flutter receives primitives through `dev.inkwell/extensions`:

```text
listInstalled -> [{name, packageName, version, entryPoint,
                   fingerprints: [SHA256], nsfw, runtimeAvailable: false}]
openAppSettings({packageName}) -> null
capabilities -> {discovery: true, sourceExecution: false,
                 privateExtensions: false, protocolVersion: 1}
```

Entry-point lookup: `tachiyomi.extension.class`, then `tachiyomi.extension.factory`. The inspector reports declarations; it does not instantiate them or claim supported API compatibility. Multiple entry points/factory behavior are not interpreted. No fingerprint is automatically trusted.

`search`, `chapters`, `pages`, `sources` explicitly return `RUNTIME_NOT_IMPLEMENTED`. Unknown methods receive the standard not-implemented response.

## Not implemented

- Extension class loading, Source/SourceFactory instantiation, host libraries or API-version validation.
- OkHttp/Jsoup/RxJava/coroutine/service-locator compatibility dependencies.
- Preferences, cookies, WebView verification, source interceptors or authenticated image requests.
- Certificate trust store, repository verification, APK installation or private extension storage.
- Live source search/details/chapters/pages, network downloads or background updates.
- A real-device compatibility matrix.

A Flutter bridge alone cannot solve these. Source-interface stubs do not provide the extension's complete host environment.

## Planned source protocol

Before exposing live sources, version a protocol for source listing, search with pagination, manga details, chapters, page descriptors, authenticated image bytes/native cache URIs, and request cancellation. Keep 64-bit source identities as **strings** across transports. Preserve source-specific headers, cookies and referers rather than asking Dart to re-fetch a naked image URL.

## Security requirements before executing an APK

1. Verify manifest, supported host API, package version and signing identity before class loading.
2. Require explicit certificate-based trust; recheck updates. Never transfer trust by display name alone.
3. Pin the host ABI and test one openly licensed extension end-to-end before expanding.
4. A JVM class loader is **not a sandbox**: loaded code normally has the app's privileges. An Android isolated process is a separate architecture with IPC and networking trade-offs.
5. Private APK support needs safe paths, signature continuity, read-only dynamic code where Android requires it, and replacement/uninstall cleanup.
6. Do not log auth credentials/cookies, redistribute copyrighted content or bypass source access controls.
7. Audit reused runtime code and dependency licences before distribution.

## Reference

The scanner was independently implemented using Android APIs and public extension-manifest conventions visible in the upstream loader:
https://github.com/mihonapp/mihon/blob/main/app/src/main/java/eu/kanade/tachiyomi/extension/util/ExtensionLoader.kt

No upstream source engine is bundled or claimed as implemented.
