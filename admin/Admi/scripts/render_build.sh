#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
flutter pub get
flutter build web --release --base-href=/ --no-wasm-dry-run
# Hosts that serve 404.html for unknown paths (not Render without Dashboard rewrite).
cp -f build/web/index.html build/web/404.html
