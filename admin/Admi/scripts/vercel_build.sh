#!/usr/bin/env bash
# Build Toury Admin Flutter Web for Vercel (site root /).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! command -v flutter >/dev/null 2>&1; then
  echo "==> Flutter not found — installing stable SDK for CI"
  FLUTTER_DIR="${FLUTTER_HOME:-$ROOT/.flutter_sdk}"
  if [[ ! -x "$FLUTTER_DIR/bin/flutter" ]]; then
    git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$FLUTTER_DIR"
  fi
  export PATH="$FLUTTER_DIR/bin:$PATH"
fi

flutter --version
flutter config --enable-web
flutter pub get
flutter build web --release \
  --base-href=/ \
  --no-web-resources-cdn \
  --no-wasm-dry-run

echo "==> Build ready at $ROOT/build/web"
