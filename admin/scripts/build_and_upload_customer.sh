#!/usr/bin/env bash
# Build + export customer IPA, then upload customer + driver IPAs via ASC API key.
# Requires AuthKey_*.p8 (App Store Connect → Users and Access → Integrations → Keys).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/ara_oatan_app"
OUT_DAY="$ROOT/releases/$(date +%Y-%m-%d)"
CUSTOMER_OUT="$OUT_DAY/customer"
DRIVER_IPA="$OUT_DAY/driver/MNDOB.ipa"
KEYS_DIR="${ASC_KEYS_DIR:-$HOME/.appstoreconnect/private_keys}"
ISSUER_ID="${ASC_ISSUER_ID:-33620f9e-4268-4130-a32b-d1ee48bddc41}"
# Prefer Admin key if present; else first AuthKey_*.p8
KEY_ID="${ASC_KEY_ID:-}"

mkdir -p "$CUSTOMER_OUT" "$KEYS_DIR"

pick_key() {
  if [[ -n "$KEY_ID" && -f "$KEYS_DIR/AuthKey_${KEY_ID}.p8" ]]; then
    echo "$KEY_ID"
    return
  fi
  local f
  for f in "$KEYS_DIR"/AuthKey_*.p8; do
    [[ -f "$f" ]] || continue
    basename "$f" | sed -E 's/^AuthKey_([A-Z0-9]+)\.p8$/\1/'
    return
  done
  return 1
}

if ! KEY_ID="$(pick_key)"; then
  cat <<EOF
MISSING App Store Connect API key (.p8)

1) App Store Connect → Users and Access → Integrations → Team Keys
2) Create Key (Admin or App Manager) → Download AuthKey_XXXX.p8  (once only)
3) Place it here:
   $KEYS_DIR/AuthKey_XXXXXX.p8

Then re-run:
  ASC_KEY_ID=XXXXXX $0

Issuer ID in use: $ISSUER_ID
EOF
  exit 2
fi

KEY_PATH="$KEYS_DIR/AuthKey_${KEY_ID}.p8"
AUTH=(
  -authenticationKeyPath "$KEY_PATH"
  -authenticationKeyID "$KEY_ID"
  -authenticationKeyIssuerID "$ISSUER_ID"
)

echo "Using ASC key: $KEY_ID"
echo "Issuer: $ISSUER_ID"

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

upload_one() {
  local ipa="$1"
  echo "Uploading $ipa ..."
  xcrun altool --upload-app -f "$ipa" -t ios \
    --apiKey "$KEY_ID" \
    --apiIssuer "$ISSUER_ID" \
    | tee -a "$OUT_DAY/upload.log"
}

upload_one "$CUSTOMER_IPA"
if [[ -f "$DRIVER_IPA" ]]; then
  upload_one "$DRIVER_IPA"
else
  echo "Driver IPA missing: $DRIVER_IPA"
fi

echo "DONE"
ls -lah "$CUSTOMER_OUT"/*.ipa "$DRIVER_IPA" 2>/dev/null || true
