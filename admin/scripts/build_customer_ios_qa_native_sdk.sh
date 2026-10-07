#!/usr/bin/env bash
# Customer iOS — QA Native N-Genius SDK build (NOT for App Store production).
#
# Mode: QA_NATIVE_SDK
#   MOBILE_PAYMENT_MODE=sdk
#   OPEN_PAYMENT_IN_EXTERNAL_BROWSER=false
#
# Use for: local device / TestFlight internal QA only.
# Does NOT upload to App Store Connect. Does NOT submit for review.
#
# Production/store builds must keep using PRODUCTION_HPP scripts
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

echo "=== QA_NATIVE_SDK Customer iOS (no App Store upload) ==="
echo "Out: $OUT"
echo "Defines: ${QA_DEFINES[*]}"

cd "$APP"
flutter pub get
flutter build ios --release --no-codesign "${QA_DEFINES[@]}"

ARCHIVE="$APP/build/ios/archive/Runner.xcarchive"
EXPORT_DIR="$APP/build/ios/ipa"
rm -rf "$ARCHIVE" "$EXPORT_DIR"
mkdir -p "$(dirname "$ARCHIVE")" "$EXPORT_DIR"

xcodebuild -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE" \
  DEVELOPMENT_TEAM=7XPP94HATF \
  CODE_SIGN_STYLE=Automatic \
  -allowProvisioningUpdates \
  archive | tee "$OUT/archive.log"

xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist ios/ExportOptions.plist \
  -allowProvisioningUpdates \
  | tee "$OUT/export.log"

cp -f "$EXPORT_DIR"/*.ipa "$OUT/" 2>/dev/null || true
{
  echo "mode=QA_NATIVE_SDK"
  echo "platform=ios"
  echo "MOBILE_PAYMENT_MODE=sdk"
  echo "OPEN_PAYMENT_IN_EXTERNAL_BROWSER=false"
  echo "store_upload=NO"
  echo "built_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
} > "$OUT/QA_MANIFEST.txt"

echo "=== QA IPA ready under $OUT (do NOT App Store submit from this script) ==="
ls -lah "$OUT"
