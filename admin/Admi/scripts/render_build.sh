#!/usr/bin/env bash
# Render Admin static site build — MUST use pinned Flutter + same flags as Firebase.
set -euo pipefail
cd "$(dirname "$0")/.."

# shellcheck disable=SC1091
source scripts/ensure_pinned_flutter.sh

flutter pub get
# Match Firebase/canonical web flags (local CanvasKit — Safari/WebKit safe).
flutter build web --release \
  --base-href=/ \
  --no-web-resources-cdn \
  --no-wasm-dry-run

# Hosts that serve 404.html for unknown paths (backup; Dashboard rewrite is SoT).
cp -f build/web/index.html build/web/404.html

if [[ -f web/_redirects ]]; then
  cp -f web/_redirects build/web/_redirects
fi

# Publish version.json from pubspec / committed web/version.json.
VER_LINE="$(grep -E '^version:' pubspec.yaml | head -1 | awk '{print $2}')"
VERSION="${VER_LINE%%+*}"
BUILD="${VER_LINE##*+}"
printf '%s\n' "{\"app_name\":\"admin_arawatan\",\"version\":\"${VERSION}\",\"build_number\":\"${BUILD}\",\"package_name\":\"admin_arawatan\"}" > build/web/version.json
if [[ -f web/version.json ]]; then
  cp -f web/version.json build/web/version.json
fi

# Provenance stamp for live parity checks (not used by the app runtime).
python3 - <<'PY'
import json, subprocess, pathlib
root = pathlib.Path('.')
pin = json.loads((root / 'tooling' / 'FLUTTER_PIN.json').read_text())
ver = json.loads((root / 'build' / 'web' / 'version.json').read_text())
try:
  commit = subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip()
except Exception:
  commit = 'unknown'
out = {
  'app_version': f"{ver['version']}+{ver['build_number']}",
  'git_commit': commit,
  'flutter': pin['flutter'],
  'dart': pin['dart'],
  'engine_revision': pin['engine_revision'],
  'base_href': '/',
  'build_flags': ['--release', '--base-href=/', '--no-web-resources-cdn', '--no-wasm-dry-run'],
}
path = root / 'build' / 'web' / 'build_provenance.json'
path.write_text(json.dumps(out, indent=2) + '\n')
print('wrote', path, out)
PY

echo "==> wrote build/web/version.json $(cat build/web/version.json)"
