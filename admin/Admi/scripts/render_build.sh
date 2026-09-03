#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
flutter pub get
flutter build web --release --base-href=/ --no-wasm-dry-run
# Hosts that serve 404.html for unknown paths (not Render without Dashboard rewrite).
cp -f build/web/index.html build/web/404.html
# Publish version.json from pubspec for SOURCE=FIREBASE=RENDER parity (no python required).
VER_LINE="$(grep -E '^version:' pubspec.yaml | head -1 | awk '{print $2}')"
VERSION="${VER_LINE%%+*}"
BUILD="${VER_LINE##*+}"
printf '%s\n' "{\"app_name\":\"admin_arawatan\",\"version\":\"${VERSION}\",\"build_number\":\"${BUILD}\",\"package_name\":\"admin_arawatan\"}" > build/web/version.json
# Prefer committed web/version.json when present (copied by flutter build).
if [[ -f web/version.json ]]; then
  cp -f web/version.json build/web/version.json
fi
echo "==> wrote build/web/version.json $(cat build/web/version.json)"
