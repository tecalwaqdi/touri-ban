#!/usr/bin/env bash
# Ensure PATH uses the pinned Flutter SDK from tooling/FLUTTER_PIN.json.
# Safe to source or execute. Does not upgrade Flutter arbitrarily.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PIN_FILE="$ROOT/tooling/FLUTTER_PIN.json"

if [[ ! -f "$PIN_FILE" ]]; then
  echo "ERROR: missing $PIN_FILE" >&2
  exit 1
fi

PINNED_VERSION="$(python3 -c "import json; print(json.load(open('$PIN_FILE'))['flutter'])")"
PINNED_ENGINE="$(python3 -c "import json; print(json.load(open('$PIN_FILE'))['engine_revision'])")"
PINNED_ENGINE_SHORT="$(python3 -c "import json; e=json.load(open('$PIN_FILE'))['engine_revision']; print(e[:10])")"
PINNED_REF="$(python3 -c "import json; d=json.load(open('$PIN_FILE')); print(d.get('git_ref', d['flutter']))")"

FLUTTER_DIR="${TOURY_FLUTTER_SDK:-$ROOT/.flutter_sdk/$PINNED_VERSION}"

flutter_matches_pin() {
  local bin="${1:-flutter}"
  command -v "$bin" >/dev/null 2>&1 || return 1
  local ver
  ver="$("$bin" --version 2>/dev/null | tr '\n' ' ' || true)"
  echo "$ver" | grep -q "Flutter ${PINNED_VERSION}" || return 1
  # flutter --version prints a short engine revision (10 chars).
  echo "$ver" | grep -Eq "(revision )?${PINNED_ENGINE_SHORT}" || return 1
  return 0
}

if flutter_matches_pin flutter; then
  echo "==> Using existing Flutter $PINNED_VERSION (engine ${PINNED_ENGINE_SHORT}…)"
elif [[ -x "$FLUTTER_DIR/bin/flutter" ]] && flutter_matches_pin "$FLUTTER_DIR/bin/flutter"; then
  export PATH="$FLUTTER_DIR/bin:$PATH"
  echo "==> Using pinned SDK at $FLUTTER_DIR"
else
  echo "==> Installing pinned Flutter $PINNED_VERSION → $FLUTTER_DIR"
  rm -rf "$FLUTTER_DIR"
  mkdir -p "$(dirname "$FLUTTER_DIR")"
  git clone https://github.com/flutter/flutter.git \
    --branch "$PINNED_REF" \
    --depth 1 \
    "$FLUTTER_DIR"
  export PATH="$FLUTTER_DIR/bin:$PATH"
fi

# Prefer pinned local SDK directory when present and matching.
if [[ -x "$FLUTTER_DIR/bin/flutter" ]] && flutter_matches_pin "$FLUTTER_DIR/bin/flutter"; then
  export PATH="$FLUTTER_DIR/bin:$PATH"
fi

flutter --version
if ! flutter_matches_pin flutter; then
  echo "ERROR: Flutter pin mismatch. Expected Flutter $PINNED_VERSION engine~$PINNED_ENGINE_SHORT" >&2
  flutter --version >&2 || true
  exit 1
fi

flutter config --enable-web >/dev/null || true
