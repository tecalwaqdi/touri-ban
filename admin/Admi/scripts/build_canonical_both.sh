#!/usr/bin/env bash
# Produce BOTH host artifacts from the same pinned Flutter toolchain.
# 1) Firebase: base-href=/admin/ → firebase/hosting_public
# 2) Render:   base-href=/      → build/web
# Verifies main.dart.js SHA match (base href lives in index.html only).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

bash scripts/build_web_admin.sh /admin/
# Preserve Firebase artifact before Render overwrites build/web
rm -rf /tmp/touri_admin_firebase_web
mkdir -p /tmp/touri_admin_firebase_web
cp -R firebase/hosting_public/admin/. /tmp/touri_admin_firebase_web/

bash scripts/render_build.sh

# Restore Firebase hosting (render_build does not touch it, but be explicit)
rm -rf firebase/hosting_public/admin
mkdir -p firebase/hosting_public/admin
cp -R /tmp/touri_admin_firebase_web/. firebase/hosting_public/admin/

python3 - <<'PY'
import hashlib, pathlib, sys
r = pathlib.Path('build/web/main.dart.js').read_bytes()
f = pathlib.Path('firebase/hosting_public/admin/main.dart.js').read_bytes()
hr, hf = hashlib.sha256(r).hexdigest(), hashlib.sha256(f).hexdigest()
print('RENDER main.dart.js', hr)
print('FIREBASE main.dart.js', hf)
if hr != hf:
    print('ERROR: main.dart.js SHA mismatch between host builds', file=sys.stderr)
    sys.exit(1)
print('PASS: main.dart.js SHA match')
PY

echo "==> Canonical both-host artifacts ready"
echo "    Render publish:  build/web"
echo "    Firebase public: firebase/hosting_public"
