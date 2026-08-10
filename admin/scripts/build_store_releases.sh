#!/usr/bin/env bash
# Build App Store IPA + Play Store AAB for customer + driver apps.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/releases/$(date +%Y-%m-%d)"
mkdir -p "$OUT/customer" "$OUT/driver"

CUSTOMER_DEFINES=(
  --dart-define=ENABLE_ONLINE_PAYMENT=true
  --dart-define=PAYMENT_BACKEND=external_api
  --dart-define=PAYMENT_API_BASE_URL=https://touri-ban.onrender.com
  --dart-define=OPEN_PAYMENT_IN_EXTERNAL_BROWSER=true
  --dart-define=TOURY_CLIENT_CASH_FALLBACK=true
)

echo "==> Customer iOS IPA"
(
  cd "$ROOT/ara_oatan_app"
  flutter build ipa --release \
    --export-options-plist=ios/ExportOptions.plist \
    "${CUSTOMER_DEFINES[@]}"
  cp -f build/ios/ipa/*.ipa "$OUT/customer/" 2>/dev/null || true
)

echo "==> Driver iOS IPA"
(
  cd "$ROOT/mndob-main"
  flutter build ipa --release \
    --export-options-plist=ios/ExportOptions.plist
  cp -f build/ios/ipa/*.ipa "$OUT/driver/" 2>/dev/null || true
)

if [[ -n "${ANDROID_HOME:-}" || -d "$HOME/Library/Android/sdk" ]]; then
  export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
  echo "==> Customer Android AAB"
  (
    cd "$ROOT/ara_oatan_app"
    if [[ ! -f android/key.properties ]]; then
      echo "WARN: android/key.properties missing — AAB will not be Play-ready"
    fi
    flutter build appbundle --release "${CUSTOMER_DEFINES[@]}"
    cp -f build/app/outputs/bundle/release/*.aab "$OUT/customer/" 2>/dev/null || true
  )
  echo "==> Driver Android AAB"
  (
    cd "$ROOT/mndob-main"
    if [[ ! -f android/key.properties ]]; then
      echo "ERROR: android/key.properties required for driver release signing"
      exit 1
    fi
    flutter build appbundle --release
    cp -f build/app/outputs/bundle/release/*.aab "$OUT/driver/" 2>/dev/null || true
  )
else
  echo "SKIP Android: ANDROID_HOME / SDK not found"
fi

echo "Artifacts in: $OUT"
ls -lah "$OUT/customer" "$OUT/driver" || true
