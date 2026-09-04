#!/usr/bin/env bash
# Build Toury Admin Flutter Web for Vercel (site root /).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Never float to latest stable — pin matches Firebase Safari-proven toolchain.
# shellcheck disable=SC1091
source "$ROOT/scripts/ensure_pinned_flutter.sh"

flutter pub get
flutter build web --release \
  --base-href=/ \
  --no-web-resources-cdn \
  --no-wasm-dry-run

echo "==> Build ready at $ROOT/build/web"
