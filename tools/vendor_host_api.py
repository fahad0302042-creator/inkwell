"""Fetch pinned Apache-2.0 source API files; original licences and provenance are retained."""
from pathlib import Path
import urllib.request, json
ROOT=Path(__file__).resolve().parents[1]
SHA='424bbc53b85c19acd3c3b7c03ec6f73f516f25bc'
BASE=f'https://raw.githubusercontent.com/mihonapp/mihon/{SHA}/'
DEST=ROOT/'android/app/src/main/kotlin'
paths=json.load(urllib.request.urlopen(f'https://api.github.com/repos/mihonapp/mihon/git/trees/{SHA}?recursive=1'))['tree']
files=[x['path'] for x in paths if x['path'].startswith('source-api/src/main/kotlin/') and x['path'].endswith('.kt')]
for src in files:
    code=urllib.request.urlopen(BASE+src).read().decode()
    # Host-independent equivalent: avoid importing the full app/Compose graph.
    code=code.replace('import androidx.compose.runtime.Stable\n','').replace('@Stable\n','')
    code=code.replace('import mihon.core.common.extensions.EMPTY\n','').replace('String.EMPTY','""').replace('JsonObject.EMPTY','JsonObject(emptyMap())')
    dst=DEST/src.split('source-api/src/main/kotlin/')[1]
    dst.parent.mkdir(parents=True,exist_ok=True)
    dst.write_text('// Adapted from Mihon (Apache-2.0), commit '+SHA+'.\n// Inkwell changes: remove app-only annotations/app EMPTY helpers. See THIRD_PARTY_NOTICES.md.\n'+code)
for name in ['Requests.kt','HttpException.kt','AndroidCookieJar.kt','ProgressListener.kt','ProgressResponseBody.kt']:
    src='core/common/src/main/kotlin/eu/kanade/tachiyomi/network/'+name
    dst=DEST/'eu/kanade/tachiyomi/network'/name;dst.parent.mkdir(parents=True,exist_ok=True)
    dst.write_text('// From Mihon (Apache-2.0), commit '+SHA+'. See THIRD_PARTY_NOTICES.md.\n'+urllib.request.urlopen(BASE+src).read().decode())
license_dir=ROOT/'assets/licenses';license_dir.mkdir(parents=True,exist_ok=True)
(license_dir/'Mihon-Apache-2.0.txt').write_bytes(urllib.request.urlopen(BASE+'LICENSE').read())
(ROOT/'THIRD_PARTY_NOTICES.md').write_text('''# Third-party source notices

The host API under `android/app/src/main/kotlin/eu/kanade/tachiyomi/source/`,
`eu/kanade/tachiyomi/util/JsoupExtensions.kt`, and network `Requests.kt`,
`HttpException.kt`, `AndroidCookieJar.kt`, `ProgressListener.kt`, `ProgressResponseBody.kt`
are adapted from the Mihon project and its Tachiyomi contributors.

Upstream: https://github.com/mihonapp/mihon
Pinned commit: '''+SHA+'''
Licence: Apache License 2.0, reproduced in `assets/licenses/Mihon-Apache-2.0.txt`.
Original copyright notices remain in the licensed source where present.
Changes: remove the app-specific String.EMPTY helper and Compose stability annotation;
substitute Inkwell network/context/bootstrap services instead of the full Mihon app graph.
The original sources can be reproduced with `tools/vendor_host_api.py`.

Other runtime, Flutter and font dependencies retain their respective licences.
No Keiyoushi APK or manga content is bundled inside Inkwell.
The integration-test workflow downloads a pinned, hash-checked xkcd extension separately
for device testing; this does not imply all Keiyoushi extensions are compatible.
''')
