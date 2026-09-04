#!/usr/bin/env bash
# Vercel Admin web build — same pinned toolchain as Render/Firebase.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
bash "$ROOT/scripts/build_admin_web.sh" /
echo "==> Build ready at $ROOT/build/web"
