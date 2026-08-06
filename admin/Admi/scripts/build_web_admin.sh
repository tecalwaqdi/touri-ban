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

echo "==> Done. Deploy folder: $HOSTING_DIR"
