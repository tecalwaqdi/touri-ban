#!/usr/bin/env bash
# Build Toury Admin as a production Web Dashboard under /admin/ (Firebase) or /.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

BASE_HREF="${1:-/admin/}"
case "$BASE_HREF" in
  */) ;;
  *) BASE_HREF="${BASE_HREF}/" ;;
esac

bash "$ROOT/scripts/build_admin_web.sh" "$BASE_HREF"

HOSTING_DIR="$ROOT/build/web_hosting"
rm -rf "$HOSTING_DIR"
mkdir -p "$HOSTING_DIR"

if [[ "$BASE_HREF" == "/" ]]; then
  cp -R "$ROOT/build/web/." "$HOSTING_DIR/"
  echo "==> Output: $HOSTING_DIR/  (site root)"
else
  REL="${BASE_HREF#/}"
  REL="${REL%/}"
  mkdir -p "$HOSTING_DIR/$REL"
  cp -R "$ROOT/build/web/." "$HOSTING_DIR/$REL/"
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

FIREBASE_HOSTING="$ROOT/firebase/hosting_public"
rm -rf "$FIREBASE_HOSTING"
mkdir -p "$FIREBASE_HOSTING"
cp -R "$HOSTING_DIR/." "$FIREBASE_HOSTING/"
echo "==> Synced for Firebase: $FIREBASE_HOSTING"

# Ensure version.json mirrors pubspec/web pin in all publish trees.
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
for rel in (
    'build/web/version.json',
    'build/web_hosting/admin/version.json',
    'firebase/hosting_public/admin/version.json',
):
    p = Path(rel)
    if p.parent.exists():
        p.write_text(json.dumps(ver), encoding='utf-8')
        print('wrote', rel, ver)
PY

echo "==> Done. Deploy folder: $HOSTING_DIR"
