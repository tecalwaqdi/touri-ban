#!/usr/bin/env bash
# Canonical Admin Flutter web build (shared by Render + Firebase packaging).
# Usage:
#   bash scripts/build_admin_web.sh /
#   bash scripts/build_admin_web.sh /admin/
#
# No python/poetry. Absolute pinned Flutter only.
set -euo pipefail

_log() { printf '%s\n' "$*" >&2; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

BASE_HREF="${1:-/}"
case "$BASE_HREF" in
  */) ;;
  *) BASE_HREF="${BASE_HREF}/" ;;
esac

_log "============================================================"
_log "TOURI ADMIN WEB BUILD — TOOLCHAIN PROVENANCE"
_log "============================================================"
_log "pwd: $(pwd)"
_log "git: $(git rev-parse HEAD 2>/dev/null || echo unknown)"
_log "PATH: $PATH"
_log "FLUTTER_ROOT(before): ${FLUTTER_ROOT:-<unset>}"
_log "command -v flutter(before): $(command -v flutter 2>/dev/null || echo none)"

# shellcheck disable=SC1091
source "$ROOT/scripts/ensure_pinned_flutter.sh"

_json_str_field() {
  local key="$1"
  local json="$2"
  printf '%s' "$json" | sed -n "s/.*\"${key}\"[[:space:]]*:[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p" | head -n 1
}

_log "FLUTTER_ROOT(after): $FLUTTER_ROOT"
_log "PINNED_FLUTTER_BIN: $PINNED_FLUTTER_BIN"
_log "---- flutter --version ----"
"$PINNED_FLUTTER_BIN" --version >&2
_log "---- flutter --version --machine ----"
MACHINE_JSON="$("$PINNED_FLUTTER_BIN" --version --machine 2>/dev/null)"
_log "$MACHINE_JSON"
_log "---- dart --version ----"
"$PINNED_FLUTTER_BIN" dart --version >&2 || true

ACTUAL_FLUTTER="$(_json_str_field flutterVersion "$MACHINE_JSON")"
[[ -n "$ACTUAL_FLUTTER" ]] || ACTUAL_FLUTTER="$(_json_str_field frameworkVersion "$MACHINE_JSON")"
ACTUAL_ENGINE="$(_json_str_field engineRevision "$MACHINE_JSON")"
ACTUAL_DART="$(_json_str_field dartSdkVersion "$MACHINE_JSON")"
ACTUAL_FRAMEWORK="$(_json_str_field frameworkRevision "$MACHINE_JSON")"

_log "PARSED_FLUTTER: $ACTUAL_FLUTTER"
_log "PARSED_ENGINE: $ACTUAL_ENGINE"

if [[ "$ACTUAL_FLUTTER" != "$PINNED_FLUTTER_VERSION" ]]; then
  _log "ERROR: WRONG_FLUTTER_TOOLCHAIN"
  _log "EXPECTED_FLUTTER: $PINNED_FLUTTER_VERSION"
  _log "ACTUAL_FLUTTER: $ACTUAL_FLUTTER"
  exit 1
fi
if [[ "$ACTUAL_ENGINE" != "$PINNED_ENGINE_REVISION" ]]; then
  if ! [[ ${#ACTUAL_ENGINE} -eq 10 && "$PINNED_ENGINE_REVISION" == "$ACTUAL_ENGINE"* ]]; then
    _log "ERROR: WRONG_FLUTTER_TOOLCHAIN"
    _log "EXPECTED_ENGINE: $PINNED_ENGINE_REVISION"
    _log "ACTUAL_ENGINE: $ACTUAL_ENGINE"
    exit 1
  fi
fi
_log "TOOLCHAIN_GATE=PASS"

_log "==> Cleaning stale build/web"
rm -rf build/web
"$PINNED_FLUTTER_BIN" clean >/dev/null 2>&1 || true

_log "==> flutter pub get (pinned)"
"$PINNED_FLUTTER_BIN" pub get

_log "==> flutter build web (pinned) base-href=${BASE_HREF}"
"$PINNED_FLUTTER_BIN" build web --release \
  --base-href="${BASE_HREF}" \
  --no-web-resources-cdn \
  --no-wasm-dry-run

cp -f build/web/index.html build/web/404.html
if [[ -f web/_redirects ]]; then
  cp -f web/_redirects build/web/_redirects
fi

if [[ -f web/version.json ]]; then
  cp -f web/version.json build/web/version.json
else
  VER_LINE="$(grep -E '^version:' pubspec.yaml | head -1 | awk '{print $2}')"
  VERSION="${VER_LINE%%+*}"
  BUILD="${VER_LINE##*+}"
  printf '%s\n' "{\"app_name\":\"admin_arawatan\",\"version\":\"${VERSION}\",\"build_number\":\"${BUILD}\",\"package_name\":\"admin_arawatan\"}" \
    > build/web/version.json
fi

APP_VERSION="$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' build/web/version.json | head -1)"
BUILD_NUMBER="$(sed -n 's/.*"build_number"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' build/web/version.json | head -1)"
GIT_COMMIT="$(git rev-parse HEAD 2>/dev/null || echo unknown)"
GENERATED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
ENGINE_OUT="$ACTUAL_ENGINE"
if [[ ${#ENGINE_OUT} -eq 10 ]]; then
  ENGINE_OUT="$PINNED_ENGINE_REVISION"
fi
DART_OUT="${ACTUAL_DART:-$PINNED_DART_VERSION}"
FRAMEWORK_OUT="${ACTUAL_FRAMEWORK:-$PINNED_FRAMEWORK_REVISION}"

cat > build/web/build_provenance.json <<EOF
{
  "app_version": "${APP_VERSION}+${BUILD_NUMBER}",
  "build_number": "${BUILD_NUMBER}",
  "git_commit": "${GIT_COMMIT}",
  "flutter_version": "${ACTUAL_FLUTTER}",
  "dart_version": "${DART_OUT}",
  "framework_revision": "${FRAMEWORK_OUT}",
  "engine_revision": "${ENGINE_OUT}",
  "base_href": "${BASE_HREF}",
  "build_command_id": "scripts/build_admin_web.sh",
  "build_flags": [
    "--release",
    "--base-href=${BASE_HREF}",
    "--no-web-resources-cdn",
    "--no-wasm-dry-run"
  ],
  "generated_at": "${GENERATED_AT}"
}
EOF

test -f build/web/build_provenance.json
head -c 1 build/web/build_provenance.json | grep -q '{'
grep -q "\"engine_revision\": \"${PINNED_ENGINE_REVISION}\"" build/web/build_provenance.json \
  || grep -q "\"engine_revision\": \"${ACTUAL_ENGINE}\"" build/web/build_provenance.json
test -f build/web/main.dart.js
test -f build/web/flutter_bootstrap.js
test -f build/web/version.json
_log "provenance JSON: OK"

_log "==> Artifact SHA256"
: > build/web/artifact_hashes.json
{
  printf '{\n'
  first=1
  for n in \
    main.dart.js flutter_bootstrap.js flutter_service_worker.js \
    index.html version.json build_provenance.json \
    assets/AssetManifest.bin assets/AssetManifest.bin.json
  do
    p="build/web/$n"
    if [[ ! -f "$p" ]]; then
      continue
    fi
    if command -v shasum >/dev/null 2>&1; then
      h="$(shasum -a 256 "$p" | awk '{print $1}')"
    else
      h="$(sha256sum "$p" | awk '{print $1}')"
    fi
    sz="$(wc -c < "$p" | tr -d ' ')"
    if [[ "$first" -eq 1 ]]; then first=0; else printf ',\n'; fi
    printf '  "%s": {"sha256": "%s", "size": %s}' "$n" "$h" "$sz"
  done
  printf '\n}\n'
} | tee build/web/artifact_hashes.json >&2

_log "==> build_admin_web.sh DONE (base-href=${BASE_HREF})"
