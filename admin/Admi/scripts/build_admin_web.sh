#!/usr/bin/env bash
# Canonical Admin Flutter web build (shared by Render + Firebase packaging).
# Usage:
#   bash scripts/build_admin_web.sh /
#   bash scripts/build_admin_web.sh /admin/
#
# Always uses the absolute pinned Flutter executable from ensure_pinned_flutter.sh.
# Hard-fails on wrong Flutter version/engine before compiling.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

BASE_HREF="${1:-/}"
case "$BASE_HREF" in
  */) ;;
  *) BASE_HREF="${BASE_HREF}/" ;;
esac

echo "============================================================"
echo "TOURI ADMIN WEB BUILD — TOOLCHAIN PROVENANCE"
echo "============================================================"
echo "pwd: $(pwd)"
echo "git: $(git rev-parse HEAD 2>/dev/null || echo unknown)"
echo "PATH: $PATH"
echo "FLUTTER_ROOT(before): ${FLUTTER_ROOT:-<unset>}"
echo "command -v flutter(before): $(command -v flutter 2>/dev/null || echo none)"
echo "which flutter(before): $(which flutter 2>/dev/null || echo none)"

# shellcheck disable=SC1091
source "$ROOT/scripts/ensure_pinned_flutter.sh"

echo "FLUTTER_ROOT(after): $FLUTTER_ROOT"
echo "PINNED_FLUTTER_BIN: $PINNED_FLUTTER_BIN"
echo "command -v flutter(after): $(command -v flutter 2>/dev/null || echo none)"
echo "---- flutter --version ----"
"$PINNED_FLUTTER_BIN" --version
echo "---- flutter --version --machine ----"
MACHINE_JSON="$("$PINNED_FLUTTER_BIN" --version --machine)"
echo "$MACHINE_JSON"
echo "---- dart --version ----"
"$PINNED_FLUTTER_BIN" dart --version || true

python3 - "$MACHINE_JSON" "$PINNED_FLUTTER_VERSION" "$PINNED_ENGINE_REVISION" <<'PY'
import json, sys
raw, expect_v, expect_e = sys.argv[1], sys.argv[2], sys.argv[3]
data = json.loads(raw)
ver = str(data.get("flutterVersion") or data.get("frameworkVersion") or "")
eng = str(data.get("engineRevision") or "")
print("PARSED_FLUTTER:", ver)
print("PARSED_ENGINE:", eng)
ok_v = ver == expect_v
ok_e = eng == expect_e or (len(eng) == 10 and expect_e.startswith(eng))
if not ok_v or not ok_e:
    print("ERROR: WRONG_FLUTTER_TOOLCHAIN", file=sys.stderr)
    print("EXPECTED_FLUTTER:", expect_v, file=sys.stderr)
    print("ACTUAL_FLUTTER:", ver, file=sys.stderr)
    print("EXPECTED_ENGINE:", expect_e, file=sys.stderr)
    print("ACTUAL_ENGINE:", eng, file=sys.stderr)
    sys.exit(1)
print("TOOLCHAIN_GATE: PASS")
PY

echo "==> Cleaning stale build/web"
rm -rf build/web
"$PINNED_FLUTTER_BIN" clean >/dev/null || true

echo "==> flutter pub get (pinned)"
"$PINNED_FLUTTER_BIN" pub get

echo "==> flutter build web (pinned) base-href=${BASE_HREF}"
"$PINNED_FLUTTER_BIN" build web --release \
  --base-href="${BASE_HREF}" \
  --no-web-resources-cdn \
  --no-wasm-dry-run

# Host helpers
cp -f build/web/index.html build/web/404.html
if [[ -f web/_redirects ]]; then
  cp -f web/_redirects build/web/_redirects
fi

# version.json from committed web/version.json (canonical app version)
if [[ -f web/version.json ]]; then
  cp -f web/version.json build/web/version.json
else
  VER_LINE="$(grep -E '^version:' pubspec.yaml | head -1 | awk '{print $2}')"
  VERSION="${VER_LINE%%+*}"
  BUILD="${VER_LINE##*+}"
  printf '%s\n' "{\"app_name\":\"admin_arawatan\",\"version\":\"${VERSION}\",\"build_number\":\"${BUILD}\",\"package_name\":\"admin_arawatan\"}" \
    > build/web/version.json
fi

# Real provenance from the binary that compiled this artifact (not aspirational pin alone).
python3 - "$MACHINE_JSON" "$BASE_HREF" <<'PY'
import json, subprocess, pathlib, sys, datetime
machine = json.loads(sys.argv[1])
base_href = sys.argv[2]
root = pathlib.Path('.')
ver = json.loads((root / 'build' / 'web' / 'version.json').read_text())
pin = json.loads((root / 'tooling' / 'FLUTTER_PIN.json').read_text())
try:
    commit = subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip()
except Exception:
    commit = 'unknown'
out = {
    'app_version': f"{ver['version']}+{ver['build_number']}",
    'build_number': ver['build_number'],
    'git_commit': commit,
    'flutter_version': machine.get('flutterVersion') or machine.get('frameworkVersion'),
    'dart_version': machine.get('dartSdkVersion') or pin.get('dart'),
    'framework_revision': machine.get('frameworkRevision') or pin.get('framework_revision'),
    'engine_revision': machine.get('engineRevision'),
    'base_href': base_href,
    'build_command_id': 'scripts/build_admin_web.sh',
    'build_flags': [
        '--release',
        f'--base-href={base_href}',
        '--no-web-resources-cdn',
        '--no-wasm-dry-run',
    ],
    'generated_at': datetime.datetime.utcnow().replace(microsecond=0).isoformat() + 'Z',
}
# Hard consistency with pin
if out['flutter_version'] != pin['flutter']:
    raise SystemExit(f"provenance flutter mismatch: {out['flutter_version']} != {pin['flutter']}")
eng = out['engine_revision'] or ''
if eng != pin['engine_revision'] and not pin['engine_revision'].startswith(eng[:10]):
    raise SystemExit(f"provenance engine mismatch: {eng} != {pin['engine_revision']}")
path = root / 'build' / 'web' / 'build_provenance.json'
path.write_text(json.dumps(out, indent=2) + '\n', encoding='utf-8')
print('wrote', path)
print(json.dumps(out, indent=2))
PY

# Prove provenance is a real file in the publish directory (SPA must not invent it).
test -f build/web/build_provenance.json
python3 -c "import json; json.load(open('build/web/build_provenance.json')); print('provenance JSON: OK')"
test -f build/web/main.dart.js
test -f build/web/flutter_bootstrap.js
test -f build/web/version.json

echo "==> Artifact SHA256"
python3 <<'PY'
import hashlib, pathlib
root = pathlib.Path('build/web')
names = [
  'main.dart.js', 'flutter_bootstrap.js', 'flutter_service_worker.js',
  'index.html', 'version.json', 'build_provenance.json',
  'assets/AssetManifest.bin', 'assets/AssetManifest.bin.json',
]
report = {}
for n in names:
    p = root / n
    if not p.exists():
        report[n] = None
        continue
    b = p.read_bytes()
    report[n] = {'sha256': hashlib.sha256(b).hexdigest(), 'size': len(b)}
path = root / 'artifact_hashes.json'
path.write_text(__import__('json').dumps(report, indent=2) + '\n')
print(path.read_text())
PY

echo "==> build_admin_web.sh DONE (base-href=${BASE_HREF})"
