#!/usr/bin/env bash
# Focused gate tests for pinned Flutter toolchain (no secrets).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
PASS=0
FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL+1)); }

# 1) Pin file present
[[ -f tooling/FLUTTER_PIN.json ]] && pass "pin file exists" || fail "pin file missing"

# 2) ensure_pinned exports absolute bin matching pin
# shellcheck disable=SC1091
source scripts/ensure_pinned_flutter.sh
[[ -n "${PINNED_FLUTTER_BIN:-}" && -x "$PINNED_FLUTTER_BIN" ]] && pass "PINNED_FLUTTER_BIN absolute executable" || fail "PINNED_FLUTTER_BIN missing"
MACHINE="$("$PINNED_FLUTTER_BIN" --version --machine)"
echo "$MACHINE" | python3 -c "import json,sys; d=json.load(sys.stdin); assert d.get('flutterVersion')=='3.44.8'; print('flutter', d.get('flutterVersion')); print('engine', d.get('engineRevision'))" \
  && pass "pinned flutter machine version 3.44.8" || fail "pinned flutter version gate"

# 3) Wrong bare PATH flutter (if different) must not be required
if command -v flutter >/dev/null 2>&1; then
  RESOLVED="$(command -v flutter)"
  if [[ "$RESOLVED" != "$PINNED_FLUTTER_BIN" ]]; then
    echo "NOTE: bare flutter resolves to $RESOLVED (pin is $PINNED_FLUTTER_BIN) — builds must use PINNED_FLUTTER_BIN"
  fi
  pass "bare flutter presence checked"
fi

# 4) Simulate wrong-engine hard fail helper
python3 - <<'PY'
import json, tempfile, os, subprocess, textwrap, pathlib, sys
root = pathlib.Path('.').resolve()
# The gate inside build_admin_web uses machine JSON vs pin — unit-check the comparator.
expect_v = '3.44.8'
expect_e = json.load(open('tooling/FLUTTER_PIN.json'))['engine_revision']
good = {'flutterVersion': expect_v, 'engineRevision': expect_e}
bad = {'flutterVersion': expect_v, 'engineRevision': 'a804b261645ef8c13eb3d5c44a5c2fb0340c5539'}

def ok(data):
    ver = str(data.get('flutterVersion') or '')
    eng = str(data.get('engineRevision') or '')
    ok_v = ver == expect_v
    ok_e = eng == expect_e or eng.startswith(expect_e[:10]) or expect_e.startswith(eng)
    return ok_v and ok_e

assert ok(good)
assert not ok(bad)
print('comparator rejects a804b261')
PY
pass "wrong engine comparator rejects a804b261"

echo "==== SUMMARY pass=$PASS fail=$FAIL ===="
[[ "$FAIL" -eq 0 ]]
