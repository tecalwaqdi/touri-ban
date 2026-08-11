#!/usr/bin/env bash
# Build + export + upload customer + driver IPAs to App Store Connect.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DAY="$ROOT/releases/$(date +%Y-%m-%d)"
CUSTOMER_OUT="$OUT_DAY/customer"
DRIVER_OUT="$OUT_DAY/driver"
KEYS_DIR="${ASC_KEYS_DIR:-$HOME/.appstoreconnect/private_keys}"
ISSUER_ID="${ASC_ISSUER_ID:-33620f9e-4268-4130-a32b-d1ee48bddc41}"
KEY_ID="${ASC_KEY_ID:-Q649FRVDBW}"
KEY_PATH="$KEYS_DIR/AuthKey_${KEY_ID}.p8"

mkdir -p "$CUSTOMER_OUT" "$DRIVER_OUT" "$KEYS_DIR"

if [[ ! -f "$KEY_PATH" ]]; then
  if [[ -f "/Users/ventura/appstoreconnect/private_keys/AuthKey_${KEY_ID}.p8" ]]; then
    cp -f "/Users/ventura/appstoreconnect/private_keys/AuthKey_${KEY_ID}.p8" "$KEY_PATH"
    chmod 600 "$KEY_PATH"
  else
    echo "MISSING ASC key: $KEY_PATH"
    exit 2
  fi
fi

AUTH=(
  -authenticationKeyPath "$KEY_PATH"
  -authenticationKeyID "$KEY_ID"
  -authenticationKeyIssuerID "$ISSUER_ID"
)

echo "Using ASC key: $KEY_ID"
echo "Out: $OUT_DAY"

upload_one() {
  local ipa="$1"
  echo "Uploading $ipa ..."
  xcrun altool --upload-app -f "$ipa" -t ios \
    --apiKey "$KEY_ID" \
    --apiIssuer "$ISSUER_ID" \
    | tee -a "$OUT_DAY/upload.log"
}

# ---------- Customer ----------
CUSTOMER_APP="$ROOT/ara_oatan_app"
DEFINES=(
  --dart-define=ENABLE_ONLINE_PAYMENT=true
  --dart-define=PAYMENT_BACKEND=external_api
  --dart-define=PAYMENT_API_BASE_URL=https://touri-ban.onrender.com
  --dart-define=OPEN_PAYMENT_IN_EXTERNAL_BROWSER=true
  --dart-define=TOURY_CLIENT_CASH_FALLBACK=true
)

cd "$CUSTOMER_APP"
flutter build ios --release --no-codesign "${DEFINES[@]}"

ARCHIVE="$CUSTOMER_APP/build/ios/archive/Runner.xcarchive"
EXPORT_DIR="$CUSTOMER_APP/build/ios/ipa"
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
  archive | tee "$CUSTOMER_OUT/archive.log"

xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportOptionsPlist ios/ExportOptions.plist \
  -exportPath "$EXPORT_DIR" \
  -allowProvisioningUpdates \
  "${AUTH[@]}" \
  | tee "$CUSTOMER_OUT/export.log"

cp -f "$EXPORT_DIR"/*.ipa "$CUSTOMER_OUT/"
CUSTOMER_IPA="$(ls -1 "$CUSTOMER_OUT"/*.ipa | head -1)"
echo "Customer IPA: $CUSTOMER_IPA"
upload_one "$CUSTOMER_IPA"

# ---------- Driver ----------
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
# Normalize name for notes/scripts
if [[ -f "$DRIVER_OUT/MNDOB.ipa" ]]; then
  DRIVER_IPA="$DRIVER_OUT/MNDOB.ipa"
else
  DRIVER_IPA="$(ls -1 "$DRIVER_OUT"/*.ipa | head -1)"
  cp -f "$DRIVER_IPA" "$DRIVER_OUT/MNDOB.ipa"
  DRIVER_IPA="$DRIVER_OUT/MNDOB.ipa"
fi
echo "Driver IPA: $DRIVER_IPA"
upload_one "$DRIVER_IPA"

echo "DONE"
ls -lah "$CUSTOMER_OUT"/*.ipa "$DRIVER_OUT"/*.ipa
