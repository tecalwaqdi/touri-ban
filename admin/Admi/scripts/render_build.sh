#!/usr/bin/env bash
# Render Admin static site build entrypoint.
# No python/poetry. Absolute pinned Flutter via build_admin_web.sh.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

_log() { printf '%s\n' "$*" >&2; }

_log "============================================================"
_log "RENDER BUILD ENTRY"
_log "============================================================"
_log "pwd: $(pwd)"
_log "git: $(git rev-parse HEAD 2>/dev/null || echo unknown)"
_log "PATH: $PATH"
_log "FLUTTER_ROOT: ${FLUTTER_ROOT:-<unset>}"
_log "command -v flutter: $(command -v flutter 2>/dev/null || echo none)"

bash scripts/build_admin_web.sh /

test -f build/web/build_provenance.json
test -f build/web/main.dart.js
test -f build/web/version.json
head -c 1 build/web/build_provenance.json | grep -q '{'
grep -q '0cd610717b' build/web/build_provenance.json
grep -q '3.44.8' build/web/build_provenance.json
_log "publish provenance OK"

_log "==> Render publish directory ready: build/web"
