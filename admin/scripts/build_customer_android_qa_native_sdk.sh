#!/usr/bin/env bash
# Customer Android — QA Native N-Genius SDK build (NOT for Play production).
#
# Mode: QA_NATIVE_SDK
#   MOBILE_PAYMENT_MODE=sdk
#   OPEN_PAYMENT_IN_EXTERNAL_BROWSER=false
#
# Use for: local install / internal testing track only.
# Does NOT publish to Google Play production.
#
# Production/store AABs must keep PRODUCTION_HPP
# (MOBILE_PAYMENT_MODE=hpp) until SAFE_TO_PROMOTE_SDK=YES.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/ara_oatan_app"
OUT="$ROOT/releases/$(date +%Y-%m-%d)/customer_qa_native_sdk"
mkdir -p "$OUT"

QA_DEFINES=(
  --dart-define=ENABLE_ONLINE_PAYMENT=true
  --dart-define=PAYMENT_BACKEND=external_api
  --dart-define=PAYMENT_API_BASE_URL=https://touri-ban.onrender.com
  --dart-define=MOBILE_PAYMENT_MODE=sdk
  --dart-define=OPEN_PAYMENT_IN_EXTERNAL_BROWSER=false
  --dart-define=TOURY_CLIENT_CASH_FALLBACK=true
)

echo "=== QA_NATIVE_SDK Customer Android (no Play production publish) ==="
echo "Out: $OUT"
echo "Defines: ${QA_DEFINES[*]}"

cd "$APP"
flutter pub get
# APK for sideload QA; also build appbundle for optional internal track.
flutter build apk --release "${QA_DEFINES[@]}"
flutter build appbundle --release "${QA_DEFINES[@]}"

APK="$APP/build/app/outputs/flutter-apk/app-release.apk"
AAB="$APP/build/app/outputs/bundle/release/app-release.aab"
cp -f "$APK" "$OUT/TouriTaxi-QA-NativeSDK.apk" 2>/dev/null || true
cp -f "$AAB" "$OUT/TouriTaxi-QA-NativeSDK.aab" 2>/dev/null || true

{
  echo "mode=QA_NATIVE_SDK"
  echo "platform=android"
  echo "MOBILE_PAYMENT_MODE=sdk"
  echo "OPEN_PAYMENT_IN_EXTERNAL_BROWSER=false"
  echo "play_production_publish=NO"
  echo "built_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
} > "$OUT/QA_MANIFEST_ANDROID.txt"

echo "=== QA Android artifacts under $OUT (do NOT publish production) ==="
ls -lah "$OUT"
