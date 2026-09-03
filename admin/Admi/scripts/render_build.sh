#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
flutter pub get
flutter build web --release --base-href=/ --no-wasm-dry-run
# Hosts that serve 404.html for unknown paths (not Render without Dashboard rewrite).
cp -f build/web/index.html build/web/404.html
# Publish version.json from pubspec for SOURCE=FIREBASE=RENDER parity.
python3 - <<'PY'
from pathlib import Path
import re, json
text = Path('pubspec.yaml').read_text(encoding='utf-8')
m = re.search(r'^version:\s*([0-9.]+)\+([0-9]+)', text, re.M)
if not m:
    raise SystemExit('pubspec version not found')
ver = {
    'app_name': 'admin_arawatan',
    'version': m.group(1),
    'build_number': m.group(2),
    'package_name': 'admin_arawatan',
}
Path('build/web/version.json').write_text(json.dumps(ver), encoding='utf-8')
print('wrote build/web/version.json', ver)
PY
