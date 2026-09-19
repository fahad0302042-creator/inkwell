# Third-party source notices

The host API under `android/app/src/main/kotlin/eu/kanade/tachiyomi/source/`,
`eu/kanade/tachiyomi/util/JsoupExtensions.kt`, and network `Requests.kt`,
`HttpException.kt`, `AndroidCookieJar.kt`, `ProgressListener.kt`, `ProgressResponseBody.kt`
are adapted from the Mihon project and its Tachiyomi contributors.

Upstream: https://github.com/mihonapp/mihon
Pinned commit: 424bbc53b85c19acd3c3b7c03ec6f73f516f25bc
Licence: Apache License 2.0, reproduced in `assets/licenses/Mihon-Apache-2.0.txt`.
Original copyright notices remain in the licensed source where present.
Changes: remove the app-specific String.EMPTY helper and Compose stability annotation;
substitute Inkwell network/context/bootstrap services instead of the full Mihon app graph.
The original sources can be reproduced with `tools/vendor_host_api.py`.

Other runtime, Flutter and font dependencies retain their respective licences.
No Keiyoushi APK or manga content is bundled inside Inkwell.
The integration-test workflow downloads a pinned, hash-checked xkcd extension separately
for device testing; this does not imply all Keiyoushi extensions are compatible.
