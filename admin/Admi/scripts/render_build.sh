#!/usr/bin/env bash
# Render Admin static site build entrypoint.
# Delegates to the canonical pinned builder — never invokes bare `flutter`.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

echo "============================================================"
echo "RENDER BUILD ENTRY"
echo "============================================================"
echo "pwd: $(pwd)"
echo "git: $(git rev-parse HEAD 2>/dev/null || echo unknown)"
echo "PATH: $PATH"
echo "FLUTTER_ROOT: ${FLUTTER_ROOT:-<unset>}"
echo "command -v flutter: $(command -v flutter 2>/dev/null || echo none)"

bash scripts/build_admin_web.sh /

# Final publish-dir assertions (staticPublishPath: build/web)
test -f build/web/build_provenance.json
test -f build/web/main.dart.js
test -f build/web/version.json
# Must be JSON, not HTML (guards SPA-fallback mistakes in packaging)
head -c 1 build/web/build_provenance.json | grep -q '{'
python3 -c "import json; d=json.load(open('build/web/build_provenance.json')); assert d.get('engine_revision'); print('publish provenance OK', d['flutter_version'], d['engine_revision'][:12])"

echo "==> Render publish directory ready: build/web"
