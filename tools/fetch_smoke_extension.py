"""Download one explicitly chosen public extension for the test emulator, verifying SHA-256."""
from pathlib import Path
import hashlib, urllib.request, sys
URL = 'https://github.com/keiyoushi/extensions/releases/download/6ca40f6-0/tachiyomi-all.xkcd-v1.4.17.apk'
SHA256 = '74ef6fb112925b86ec44f30624a0cb5b0451095cfc7f1a34a853132c6cc1da99'
output = Path(sys.argv[1] if len(sys.argv) > 1 else '/tmp/inkwell-xkcd.apk')
data = urllib.request.urlopen(URL, timeout=60).read()
assert hashlib.sha256(data).hexdigest() == SHA256, 'Unexpected extension bytes; refusing to install.'
output.parent.mkdir(parents=True, exist_ok=True)
output.write_bytes(data)
print(f'Pinned xkcd extension verified: {output}')
