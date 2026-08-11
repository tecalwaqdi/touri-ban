#!/usr/bin/env bash
# Archive + export customer App Store IPA using Xcode automatic signing.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/ara_oatan_app"
OUT="$ROOT/releases/$(date +%Y-%m-%d)/customer"
mkdir -p "$OUT"

DEFINES=(
  --dart-define=ENABLE_ONLINE_PAYMENT=true
  --dart-define=PAYMENT_BACKEND=external_api
  --dart-define=PAYMENT_API_BASE_URL=https://touri-ban.onrender.com
  --dart-define=OPEN_PAYMENT_IN_EXTERNAL_BROWSER=true
  --dart-define=TOURY_CLIENT_CASH_FALLBACK=true
)

cd "$APP"
flutter build ios --release --no-codesign "${DEFINES[@]}"

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
  -exportOptionsPlist ios/ExportOptions.plist \
  -exportPath "$EXPORT_DIR" \
  -allowProvisioningUpdates \
  | tee "$OUT/export.log"

cp -f "$EXPORT_DIR"/*.ipa "$OUT/" || true
ls -lah "$OUT"
