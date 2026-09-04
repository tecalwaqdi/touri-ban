#!/usr/bin/env bash
# Resolve and export the ABSOLUTE pinned Flutter executable for Admin web builds.
# Must be sourced from a build script: `source scripts/ensure_pinned_flutter.sh`
# Exports:
#   PINNED_FLUTTER_BIN  — absolute path to flutter binary (ALWAYS use this)
#   FLUTTER_ROOT        — absolute SDK root matching the pin
#   PINNED_FLUTTER_VERSION / PINNED_ENGINE_REVISION / PINNED_* helpers
set -euo pipefail

_PIN_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${_PIN_SCRIPT_DIR}/.." && pwd)"
PIN_FILE="$ROOT/tooling/FLUTTER_PIN.json"

if [[ ! -f "$PIN_FILE" ]]; then
  echo "ERROR: WRONG_FLUTTER_TOOLCHAIN — missing $PIN_FILE" >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "ERROR: python3 required to read Flutter pin" >&2
  exit 1
fi

PINNED_FLUTTER_VERSION="$(python3 -c "import json; print(json.load(open('$PIN_FILE'))['flutter'])")"
PINNED_ENGINE_REVISION="$(python3 -c "import json; print(json.load(open('$PIN_FILE'))['engine_revision'])")"
PINNED_DART_VERSION="$(python3 -c "import json; print(json.load(open('$PIN_FILE')).get('dart',''))")"
PINNED_FRAMEWORK_REVISION="$(python3 -c "import json; print(json.load(open('$PIN_FILE')).get('framework_revision',''))")"
PINNED_REF="$(python3 -c "import json; d=json.load(open('$PIN_FILE')); print(d.get('git_ref', d['flutter']))")"

# Dedicated install dir only — never mutate system Flutter.
FLUTTER_DIR="${TOURY_FLUTTER_SDK:-$ROOT/.flutter_sdk/$PINNED_FLUTTER_VERSION}"
PINNED_FLUTTER_BIN=""

_machine_json() {
  local bin="$1"
  "$bin" --version --machine 2>/dev/null || true
}

_bin_matches_pin() {
  local bin="$1"
  [[ -x "$bin" ]] || return 1
  local machine
  machine="$(_machine_json "$bin")"
  [[ -n "$machine" ]] || return 1
  python3 - "$machine" "$PINNED_FLUTTER_VERSION" "$PINNED_ENGINE_REVISION" <<'PY'
import json, sys
raw, expect_v, expect_e = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    data = json.loads(raw)
except Exception:
    sys.exit(1)
ver = str(data.get("flutterVersion") or data.get("frameworkVersion") or "")
eng = str(data.get("engineRevision") or "")
ok_v = ver == expect_v
# Prefer exact full-hash match; allow short (10-char) form only when machine prints short.
ok_e = eng == expect_e or (len(eng) == 10 and expect_e.startswith(eng))
sys.exit(0 if (ok_v and ok_e) else 1)
PY
}

_print_toolchain_mismatch() {
  local bin="$1"
  local machine
  machine="$(_machine_json "$bin")"
  echo "ERROR: WRONG_FLUTTER_TOOLCHAIN" >&2
  echo "EXPECTED_FLUTTER: $PINNED_FLUTTER_VERSION" >&2
  echo "EXPECTED_ENGINE: $PINNED_ENGINE_REVISION" >&2
  if [[ -n "$machine" ]]; then
    python3 - "$machine" <<'PY' >&2
import json, sys
try:
    d = json.loads(sys.argv[1])
except Exception as e:
    print("ACTUAL_FLUTTER: <unparseable>", e)
    raise SystemExit(0)
print("ACTUAL_FLUTTER:", d.get("flutterVersion") or d.get("frameworkVersion"))
print("ACTUAL_ENGINE:", d.get("engineRevision"))
print("ACTUAL_DART:", d.get("dartSdkVersion"))
print("ACTUAL_FRAMEWORK:", d.get("frameworkRevision"))
PY
  else
    echo "ACTUAL_FLUTTER: <flutter --version --machine failed>" >&2
    "$bin" --version >&2 || true
  fi
}

_install_pinned_sdk() {
  echo "==> Installing pinned Flutter $PINNED_FLUTTER_VERSION → $FLUTTER_DIR"
  rm -rf "$FLUTTER_DIR"
  mkdir -p "$(dirname "$FLUTTER_DIR")"
  git clone https://github.com/flutter/flutter.git \
    --branch "$PINNED_REF" \
    --depth 1 \
    "$FLUTTER_DIR"
  # First run downloads dart SDK / creates caches.
  "$FLUTTER_DIR/bin/flutter" --version >/dev/null
}

# Prefer dedicated pin directory when it already matches.
if [[ -x "$FLUTTER_DIR/bin/flutter" ]]; then
  if _bin_matches_pin "$FLUTTER_DIR/bin/flutter"; then
    echo "==> Reusing pinned SDK at $FLUTTER_DIR"
  else
    echo "==> Existing $FLUTTER_DIR does not match pin — recreating"
    _install_pinned_sdk
  fi
else
  _install_pinned_sdk
fi

PINNED_FLUTTER_BIN="$(cd "$(dirname "$FLUTTER_DIR/bin/flutter")" && pwd)/flutter"
export FLUTTER_ROOT="$FLUTTER_DIR"
export PATH="$FLUTTER_DIR/bin:$PATH"
hash -r 2>/dev/null || true

if ! _bin_matches_pin "$PINNED_FLUTTER_BIN"; then
  _print_toolchain_mismatch "$PINNED_FLUTTER_BIN"
  exit 1
fi

# Final gate: never allow callers to "succeed" on a wrong bare flutter.
if ! _bin_matches_pin "$PINNED_FLUTTER_BIN"; then
  _print_toolchain_mismatch "$PINNED_FLUTTER_BIN"
  exit 1
fi

export PINNED_FLUTTER_BIN FLUTTER_ROOT
export PINNED_FLUTTER_VERSION PINNED_ENGINE_REVISION PINNED_DART_VERSION PINNED_FRAMEWORK_REVISION

echo "==> PINNED_FLUTTER_BIN=$PINNED_FLUTTER_BIN"
"$PINNED_FLUTTER_BIN" --version
"$PINNED_FLUTTER_BIN" config --enable-web >/dev/null || true
