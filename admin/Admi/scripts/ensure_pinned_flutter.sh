#!/usr/bin/env bash
# Resolve and export the ABSOLUTE pinned Flutter executable for Admin web builds.
# Must be sourced: `source scripts/ensure_pinned_flutter.sh`
#
# OUTPUT CONTRACT:
#   - Diagnostic logs → STDERR only
#   - Sets shell variables (no "return value" on stdout)
#   - Never invokes python/python3/poetry
#
# Exports:
#   PINNED_FLUTTER_VERSION, PINNED_ENGINE_REVISION, PINNED_DART_VERSION
#   PINNED_FRAMEWORK_REVISION, PINNED_REF
#   PINNED_FLUTTER_DIR, PINNED_FLUTTER_BIN, FLUTTER_ROOT
set -euo pipefail

_pin_log() { printf '%s\n' "$*" >&2; }

_PIN_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${_PIN_SCRIPT_DIR}/.." && pwd)"
SDK_BASE="$ROOT/.flutter_sdk"

# Authoritative pin — shell-safe constants (must match tooling/FLUTTER_PIN.json).
# DO NOT capture these from python/poetry/command stdout.
PINNED_FLUTTER_VERSION="3.44.8"
PINNED_ENGINE_REVISION="0cd610717bde95fd88343c64f81c11ba4e5c0010"
PINNED_DART_VERSION="3.12.2"
PINNED_FRAMEWORK_REVISION="058e0af2c2"
PINNED_REF="3.44.8"

# Reject polluted / injected version strings before any path construction.
_validate_semver() {
  local v="$1"
  case "$v" in
    *[!0-9.]*|'') return 1 ;;
  esac
  [[ "$v" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || return 1
  [[ "$v" != *$'\n'* && "$v" != *' '* && "$v" != */* ]] || return 1
  return 0
}

if ! _validate_semver "$PINNED_FLUTTER_VERSION"; then
  _pin_log "ERROR: INVALID_PINNED_FLUTTER_VERSION"
  _pin_log "VALUE=<<$PINNED_FLUTTER_VERSION>>"
  exit 1
fi
if [[ "$PINNED_FLUTTER_VERSION" != "3.44.8" ]]; then
  _pin_log "ERROR: INVALID_PINNED_FLUTTER_VERSION (must be exactly 3.44.8)"
  exit 1
fi

# Consistency check vs repo pin file (grep only — no JSON parsers / python).
PIN_FILE="$ROOT/tooling/FLUTTER_PIN.json"
if [[ -f "$PIN_FILE" ]]; then
  if ! grep -q '"flutter"[[:space:]]*:[[:space:]]*"3\.44\.8"' "$PIN_FILE"; then
    _pin_log "ERROR: tooling/FLUTTER_PIN.json flutter field does not match 3.44.8"
    exit 1
  fi
  if ! grep -q '0cd610717bde95fd88343c64f81c11ba4e5c0010' "$PIN_FILE"; then
    _pin_log "ERROR: tooling/FLUTTER_PIN.json engine_revision mismatch"
    exit 1
  fi
fi

PINNED_FLUTTER_DIR="${TOURY_FLUTTER_SDK:-$SDK_BASE/$PINNED_FLUTTER_VERSION}"
PINNED_FLUTTER_BIN=""

# Refuse path escape / newline injection.
case "$PINNED_FLUTTER_DIR" in
  "$SDK_BASE"/*) ;;
  *)
    _pin_log "ERROR: PINNED_FLUTTER_DIR must be under $SDK_BASE"
    _pin_log "GOT: $PINNED_FLUTTER_DIR"
    exit 1
    ;;
esac
if [[ "$PINNED_FLUTTER_DIR" == *$'\n'* || "$PINNED_FLUTTER_DIR" == *$'\r'* ]]; then
  _pin_log "ERROR: PINNED_FLUTTER_DIR contains newline"
  exit 1
fi

# Extract "key":"value" from flutter --version --machine (single-line JSON).
_json_str_field() {
  local key="$1"
  local json="$2"
  printf '%s' "$json" | sed -n "s/.*\"${key}\"[[:space:]]*:[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p" | head -n 1
}

_machine_json() {
  local bin="$1"
  # Keep machine JSON on stdout of this helper only; discard flutter stderr noise.
  "$bin" --version --machine 2>/dev/null || true
}

_bin_matches_pin() {
  local bin="$1"
  [[ -x "$bin" ]] || return 1
  local machine ver eng
  machine="$(_machine_json "$bin")"
  [[ -n "$machine" ]] || return 1
  # Prefer flutterVersion; fall back to frameworkVersion.
  ver="$(_json_str_field flutterVersion "$machine")"
  if [[ -z "$ver" ]]; then
    ver="$(_json_str_field frameworkVersion "$machine")"
  fi
  eng="$(_json_str_field engineRevision "$machine")"
  [[ "$ver" == "$PINNED_FLUTTER_VERSION" ]] || return 1
  if [[ "$eng" == "$PINNED_ENGINE_REVISION" ]]; then
    return 0
  fi
  # Allow short 10-char form only.
  if [[ ${#eng} -eq 10 && "$PINNED_ENGINE_REVISION" == "$eng"* ]]; then
    return 0
  fi
  return 1
}

_print_toolchain_mismatch() {
  local bin="$1"
  local machine ver eng
  machine="$(_machine_json "$bin")"
  ver="$(_json_str_field flutterVersion "$machine")"
  [[ -n "$ver" ]] || ver="$(_json_str_field frameworkVersion "$machine")"
  eng="$(_json_str_field engineRevision "$machine")"
  _pin_log "ERROR: WRONG_FLUTTER_TOOLCHAIN"
  _pin_log "EXPECTED_FLUTTER: $PINNED_FLUTTER_VERSION"
  _pin_log "ACTUAL_FLUTTER: ${ver:-<unknown>}"
  _pin_log "EXPECTED_ENGINE: $PINNED_ENGINE_REVISION"
  _pin_log "ACTUAL_ENGINE: ${eng:-<unknown>}"
}

_safe_rm_sdk_dir() {
  local target="$1"
  case "$target" in
    "$SDK_BASE"/"$PINNED_FLUTTER_VERSION"|"$SDK_BASE"/"$PINNED_FLUTTER_VERSION".tmp)
      rm -rf "$target"
      ;;
    *)
      _pin_log "ERROR: refusing to delete path outside dedicated SDK slot: $target"
      exit 1
      ;;
  esac
}

_install_pinned_sdk() {
  local tmp_dir="$SDK_BASE/${PINNED_FLUTTER_VERSION}.tmp"
  _pin_log "==> Installing Flutter ${PINNED_FLUTTER_VERSION} → ${PINNED_FLUTTER_DIR}"
  mkdir -p "$SDK_BASE"
  _safe_rm_sdk_dir "$tmp_dir"
  git clone https://github.com/flutter/flutter.git \
    --branch "$PINNED_REF" \
    --depth 1 \
    "$tmp_dir" >&2
  # First run downloads Dart SDK (logs → stderr).
  "$tmp_dir/bin/flutter" --version >&2
  _safe_rm_sdk_dir "$PINNED_FLUTTER_DIR"
  mv "$tmp_dir" "$PINNED_FLUTTER_DIR"
}

if [[ -x "$PINNED_FLUTTER_DIR/bin/flutter" ]]; then
  if _bin_matches_pin "$PINNED_FLUTTER_DIR/bin/flutter"; then
    _pin_log "==> Reusing pinned SDK at $PINNED_FLUTTER_DIR"
  else
    _pin_log "==> Existing SDK does not match pin — recreating"
    _install_pinned_sdk
  fi
else
  _install_pinned_sdk
fi

PINNED_FLUTTER_BIN="$PINNED_FLUTTER_DIR/bin/flutter"
if [[ ! -x "$PINNED_FLUTTER_BIN" ]]; then
  _pin_log "ERROR: pinned flutter binary missing: $PINNED_FLUTTER_BIN"
  exit 1
fi

export FLUTTER_ROOT="$PINNED_FLUTTER_DIR"
export PATH="$PINNED_FLUTTER_DIR/bin:$PATH"
hash -r 2>/dev/null || true

if ! _bin_matches_pin "$PINNED_FLUTTER_BIN"; then
  _print_toolchain_mismatch "$PINNED_FLUTTER_BIN"
  exit 1
fi

export PINNED_FLUTTER_BIN FLUTTER_ROOT PINNED_FLUTTER_DIR
export PINNED_FLUTTER_VERSION PINNED_ENGINE_REVISION PINNED_DART_VERSION
export PINNED_FRAMEWORK_REVISION PINNED_REF

_pin_log "PINNED_FLUTTER_VERSION=$PINNED_FLUTTER_VERSION"
_pin_log "PINNED_FLUTTER_DIR=$PINNED_FLUTTER_DIR"
_pin_log "PINNED_FLUTTER_BIN=$PINNED_FLUTTER_BIN"
"$PINNED_FLUTTER_BIN" --version >&2
"$PINNED_FLUTTER_BIN" config --enable-web >/dev/null 2>&1 || true
