#!/usr/bin/env bash
# Build Toury Admin as a production Web Dashboard under /admin/
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

BASE_HREF="${1:-/admin/}"
# Ensure trailing slash (required by Flutter --base-href)
case "$BASE_HREF" in
  */) ;;
  *) BASE_HREF="${BASE_HREF}/" ;;
esac

echo "==> Building admin web (base-href=${BASE_HREF})"
# shellcheck disable=SC1091
source "$ROOT/scripts/ensure_pinned_flutter.sh"
flutter pub get
flutter build web --release \
  --base-href="${BASE_HREF}" \
  --no-web-resources-cdn \
  --no-wasm-dry-run

HOSTING_DIR="$ROOT/build/web_hosting"
rm -rf "$HOSTING_DIR"
mkdir -p "$HOSTING_DIR"

# Serve under /admin/ → copy build into hosting/admin/
# When BASE_HREF is "/", copy to hosting root instead.
if [[ "$BASE_HREF" == "/" ]]; then
  cp -R "$ROOT/build/web/." "$HOSTING_DIR/"
  echo "==> Output: $HOSTING_DIR/  (site root)"
else
  # Strip leading/trailing slashes for folder name, keep nested path support
  REL="${BASE_HREF#/}"
  REL="${REL%/}"
  mkdir -p "$HOSTING_DIR/$REL"
  cp -R "$ROOT/build/web/." "$HOSTING_DIR/$REL/"
  # Convenience redirect from / → /admin/
  cat > "$HOSTING_DIR/index.html" <<EOF
<!DOCTYPE html>
<html lang="ar">
<head>
  <meta charset="UTF-8">
  <meta http-equiv="refresh" content="0;url=${BASE_HREF}">
  <script>location.replace('${BASE_HREF}');</script>
  <title>لوحة التحكم</title>
</head>
<body>
  <p><a href="${BASE_HREF}">فتح لوحة التحكم</a></p>
</body>
</html>
EOF
  echo "==> Output: $HOSTING_DIR/$REL/  (URL path ${BASE_HREF})"
fi


# Sync into firebase/hosting_public for `firebase deploy --only hosting`
FIREBASE_HOSTING="$ROOT/firebase/hosting_public"
rm -rf "$FIREBASE_HOSTING"
mkdir -p "$FIREBASE_HOSTING"
cp -R "$HOSTING_DIR/." "$FIREBASE_HOSTING/"
echo "==> Synced for Firebase: $FIREBASE_HOSTING"

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
for rel in ('build/web/version.json', 'build/web_hosting/admin/version.json', 'firebase/hosting_public/admin/version.json'):
    p = Path(rel)
    if p.parent.exists():
        p.write_text(json.dumps(ver), encoding='utf-8')
        print('wrote', rel, ver)
PY

echo "==> Done. Deploy folder: $HOSTING_DIR"

# Render / Netlify SPA fallback (PathUrlStrategy deep links)
if [[ -f "$ROOT/web/_redirects" ]]; then
  cp "$ROOT/web/_redirects" "$ROOT/build/web/_redirects"
  if [[ -d "$HOSTING_DIR" ]]; then
    find "$HOSTING_DIR" -name index.html -exec dirname {} \; | while read -r dir; do
      cp "$ROOT/web/_redirects" "$dir/_redirects"
    done
  fi
  echo "==> Copied web/_redirects for SPA hosting"
fi

# Provenance for live parity (same pin as Render).
python3 - <<PY
import json, subprocess, pathlib
root = pathlib.Path('$ROOT')
pin = json.loads((root / 'tooling' / 'FLUTTER_PIN.json').read_text())
ver = json.loads((root / 'web' / 'version.json').read_text())
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
  'base_href': '${BASE_HREF}',
  'build_flags': ['--release', '--base-href=${BASE_HREF}', '--no-web-resources-cdn', '--no-wasm-dry-run'],
}
for rel in ('build/web', 'build/web_hosting/admin', 'firebase/hosting_public/admin'):
  d = root / rel
  if d.is_dir():
    p = d / 'build_provenance.json'
    p.write_text(json.dumps(out, indent=2) + '\n')
    print('wrote', p)
PY

# Provenance for live parity (same pin as Render).
python3 - <<PY
import json, subprocess, pathlib
root = pathlib.Path(r"$ROOT")
pin = json.loads((root / "tooling" / "FLUTTER_PIN.json").read_text())
ver = json.loads((root / "web" / "version.json").read_text())
try:
    commit = subprocess.check_output(["git", "rev-parse", "HEAD"], text=True, cwd=root).strip()
except Exception:
    commit = "unknown"
out = {
    "app_version": f"{ver['version']}+{ver['build_number']}",
    "git_commit": commit,
    "flutter": pin["flutter"],
    "dart": pin["dart"],
    "engine_revision": pin["engine_revision"],
    "base_href": "$BASE_HREF",
    "build_flags": [
        "--release",
        "--base-href=$BASE_HREF",
        "--no-web-resources-cdn",
        "--no-wasm-dry-run",
    ],
}
targets = [
    root / "build" / "web" / "build_provenance.json",
    root / "firebase" / "hosting_public" / "admin" / "build_provenance.json",
    root / "firebase" / "hosting_public" / "build_provenance.json",
]
for p in targets:
    if p.parent.exists():
        p.write_text(json.dumps(out, indent=2) + "\\n")
        print("wrote", p)
PY
