#!/usr/bin/env bash
# Archive + export driver App Store IPA using Xcode automatic signing.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/mndob-main"
OUT="$ROOT/releases/$(date +%Y-%m-%d)/driver"
mkdir -p "$OUT"

cd "$APP"
flutter build ios --release --no-codesign

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
