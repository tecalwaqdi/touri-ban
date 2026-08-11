#!/usr/bin/env bash
# Build + export + upload driver IPA only.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DAY="$ROOT/releases/$(date +%Y-%m-%d)"
DRIVER_OUT="$OUT_DAY/driver"
KEYS_DIR="${ASC_KEYS_DIR:-$HOME/.appstoreconnect/private_keys}"
ISSUER_ID="${ASC_ISSUER_ID:-33620f9e-4268-4130-a32b-d1ee48bddc41}"
KEY_ID="${ASC_KEY_ID:-Q649FRVDBW}"
KEY_PATH="$KEYS_DIR/AuthKey_${KEY_ID}.p8"

mkdir -p "$DRIVER_OUT"

if [[ ! -f "$KEY_PATH" ]]; then
  echo "MISSING ASC key: $KEY_PATH"
  exit 2
fi

AUTH=(
  -authenticationKeyPath "$KEY_PATH"
  -authenticationKeyID "$KEY_ID"
  -authenticationKeyIssuerID "$ISSUER_ID"
)

echo "Using ASC key: $KEY_ID"
echo "Out: $DRIVER_OUT"

DRIVER_APP="$ROOT/mndob-main"
cd "$DRIVER_APP"
flutter build ios --release --no-codesign

ARCHIVE="$DRIVER_APP/build/ios/archive/Runner.xcarchive"
EXPORT_DIR="$DRIVER_APP/build/ios/ipa"
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
  "${AUTH[@]}" \
  archive | tee "$DRIVER_OUT/archive.log"

xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportOptionsPlist ios/ExportOptions.plist \
  -exportPath "$EXPORT_DIR" \
  -allowProvisioningUpdates \
  "${AUTH[@]}" \
  | tee "$DRIVER_OUT/export.log"

cp -f "$EXPORT_DIR"/*.ipa "$DRIVER_OUT/"
if [[ ! -f "$DRIVER_OUT/MNDOB.ipa" ]]; then
  cp -f "$(ls -1 "$DRIVER_OUT"/*.ipa | head -1)" "$DRIVER_OUT/MNDOB.ipa"
fi
DRIVER_IPA="$DRIVER_OUT/MNDOB.ipa"
echo "Driver IPA: $DRIVER_IPA"

xcrun altool --upload-app -f "$DRIVER_IPA" -t ios \
  --apiKey "$KEY_ID" \
  --apiIssuer "$ISSUER_ID" \
  | tee -a "$OUT_DAY/upload-driver.log"

echo "DONE"
ls -lah "$DRIVER_OUT"/*.ipa
