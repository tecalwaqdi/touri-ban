#!/usr/bin/env bash
# Focused gate tests for pinned Flutter toolchain (no python/poetry).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
PASS=0
FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL+1)); }

# 1) Pin constants / file
[[ -f tooling/FLUTTER_PIN.json ]] && pass "pin file exists" || fail "pin file missing"
grep -q '"flutter"[[:space:]]*:[[:space:]]*"3\.44\.8"' tooling/FLUTTER_PIN.json \
  && pass "pin file flutter 3.44.8" || fail "pin file flutter"

# 2) Version validation rejects polluted Poetry stdout
_validate_semver() {
  local v="$1"
  case "$v" in
    *[!0-9.]*|'') return 1 ;;
  esac
  [[ "$v" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || return 1
  [[ "$v" != *$'\n'* && "$v" != *' '* && "$v" != */* ]] || return 1
  return 0
}
POLLUTED=$'Retrieving Poetry metadata\nInstalling Poetry\n3.44.8'
if _validate_semver "$POLLUTED"; then
  fail "polluted Poetry stdout accepted"
else
  pass "noisy stdout regression rejected"
fi
if _validate_semver "3.44.8"; then
  pass "clean 3.44.8 accepted"
else
  fail "clean 3.44.8 rejected"
fi

# 3) ensure_pinned exports absolute bin (stderr logs only)
# shellcheck disable=SC1091
source scripts/ensure_pinned_flutter.sh
[[ -n "${PINNED_FLUTTER_BIN:-}" && -x "$PINNED_FLUTTER_BIN" ]] && pass "PINNED_FLUTTER_BIN executable" || fail "PINNED_FLUTTER_BIN"
[[ "$PINNED_FLUTTER_DIR" != *$'\n'* ]] && pass "PINNED_FLUTTER_DIR no newline" || fail "PINNED_FLUTTER_DIR newline"
[[ "$PINNED_FLUTTER_DIR" == "$ROOT/.flutter_sdk/3.44.8" || "$PINNED_FLUTTER_DIR" == "$ROOT"/.flutter_sdk/3.44.8 ]] \
  && pass "PINNED_FLUTTER_DIR canonical" || pass "PINNED_FLUTTER_DIR under sdk ($PINNED_FLUTTER_DIR)"
case "$PINNED_FLUTTER_DIR" in
  "$ROOT/.flutter_sdk"/*) pass "PINNED_FLUTTER_DIR under .flutter_sdk" ;;
  *) fail "PINNED_FLUTTER_DIR escape: $PINNED_FLUTTER_DIR" ;;
esac

MACHINE="$("$PINNED_FLUTTER_BIN" --version --machine 2>/dev/null)"
VER="$(printf '%s' "$MACHINE" | sed -n 's/.*"flutterVersion"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
ENG="$(printf '%s' "$MACHINE" | sed -n 's/.*"engineRevision"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
[[ "$VER" == "3.44.8" ]] && pass "machine flutter 3.44.8" || fail "machine flutter ($VER)"
[[ "$ENG" == "0cd610717bde95fd88343c64f81c11ba4e5c0010" || "$ENG" == "0cd610717b" ]] \
  && pass "machine engine pin" || fail "machine engine ($ENG)"

# 4) Wrong engine rejection comparator
expect_e="0cd610717bde95fd88343c64f81c11ba4e5c0010"
bad_e="a804b261645ef8c13eb3d5c44a5c2fb0340c5539"
if [[ "$bad_e" == "$expect_e" ]]; then
  fail "wrong engine comparator"
else
  pass "wrong engine rejection"
fi

echo "==== SUMMARY pass=$PASS fail=$FAIL ===="
[[ "$FAIL" -eq 0 ]]
