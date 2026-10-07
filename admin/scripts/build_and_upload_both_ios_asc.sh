#!/usr/bin/env bash
# Build + export + upload Customer + Driver IPAs to App Store Connect.
# Uses ASC_KEY_ID / ASC_ISSUER_ID from env (defaults to CXA8LB4ADH).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DAY="$ROOT/releases/$(date +%Y-%m-%d)"
CUSTOMER_OUT="$OUT_DAY/customer"
DRIVER_OUT="$OUT_DAY/driver"
KEYS_DIR="${ASC_KEYS_DIR:-$HOME/.appstoreconnect/private_keys}"
ISSUER_ID="${ASC_ISSUER_ID:-33620f9e-4268-4130-a32b-d1ee48bddc41}"
KEY_ID="${ASC_KEY_ID:-CXA8LB4ADH}"
KEY_PATH="$KEYS_DIR/AuthKey_${KEY_ID}.p8"

mkdir -p "$CUSTOMER_OUT" "$DRIVER_OUT"

if [[ ! -f "$KEY_PATH" ]]; then
  echo "MISSING ASC key: $KEY_PATH"
  exit 2
fi

# altool looks for AuthKey in ~/.appstoreconnect/private_keys or ~/.private_keys
mkdir -p "$HOME/.appstoreconnect/private_keys"
mkdir -p "$HOME/.private_keys" 2>/dev/null || true
cp -f "$KEY_PATH" "$HOME/.private_keys/AuthKey_${KEY_ID}.p8" 2>/dev/null || true
chmod 600 "$HOME/.private_keys/AuthKey_${KEY_ID}.p8" 2>/dev/null || true

AUTH=(
  -authenticationKeyPath "$KEY_PATH"
  -authenticationKeyID "$KEY_ID"
  -authenticationKeyIssuerID "$ISSUER_ID"
)

echo "Using ASC key: $KEY_ID"
echo "Out: $OUT_DAY"
echo "Apple Distribution identity check:"
security find-identity -v -p codesigning | grep "Apple Distribution" || {
  echo "NO Apple Distribution identity"
  exit 3
}

upload_one() {
  local ipa="$1"
  echo "Uploading $ipa ..."
  # Prefer iTMSTransporter via xcrun altool when available
  if xcrun altool --help >/dev/null 2>&1; then
    xcrun altool --upload-app -f "$ipa" -t ios \
      --apiKey "$KEY_ID" \
      --apiIssuer "$ISSUER_ID" \
      | tee -a "$OUT_DAY/upload.log"
  else
    xcrun iTMSTransporter -m upload -assetFile "$ipa" \
      -apiKey "$KEY_ID" -apiIssuer "$ISSUER_ID" \
      | tee -a "$OUT_DAY/upload.log"
  fi
}

archive_export() {
  local app="$1"
  local outdir="$2"
  local log_prefix="$3"

  cd "$app"
  local ARCHIVE="$app/build/ios/archive/Runner.xcarchive"
  local EXPORT_DIR="$app/build/ios/ipa"
  rm -rf "$ARCHIVE" "$EXPORT_DIR"
  mkdir -p "$(dirname "$ARCHIVE")" "$EXPORT_DIR"

  set +o pipefail
  xcodebuild -workspace ios/Runner.xcworkspace \
    -scheme Runner \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    -archivePath "$ARCHIVE" \
    DEVELOPMENT_TEAM=7XPP94HATF \
    CODE_SIGN_STYLE=Automatic \
    -allowProvisioningUpdates \
    "${AUTH[@]}" \
    archive 2>&1 | tee "$outdir/${log_prefix}-archive.log"
  local rc=${PIPESTATUS[0]}
  set -o pipefail
  if [[ $rc -ne 0 ]]; then
    echo "ARCHIVE FAILED rc=$rc"
    exit $rc
  fi

  set +o pipefail
  xcodebuild -exportArchive \
    -archivePath "$ARCHIVE" \
    -exportOptionsPlist ios/ExportOptions.plist \
    -exportPath "$EXPORT_DIR" \
    -allowProvisioningUpdates \
    "${AUTH[@]}" \
    2>&1 | tee "$outdir/${log_prefix}-export.log"
  rc=${PIPESTATUS[0]}
  set -o pipefail
  if [[ $rc -ne 0 ]]; then
    echo "EXPORT FAILED rc=$rc"
    exit $rc
  fi

  local ipa
  ipa="$(ls -1 "$EXPORT_DIR"/*.ipa | head -1)"
  cp -f "$ipa" "$outdir/"
  echo "$ipa"
}

# ---------- Customer ----------
CUSTOMER_APP="$ROOT/ara_oatan_app"
cd "$CUSTOMER_APP"
flutter build ios --release --no-codesign \
  --dart-define=ENABLE_ONLINE_PAYMENT=true \
  --dart-define=PAYMENT_BACKEND=external_api \
  --dart-define=PAYMENT_API_BASE_URL=https://touri-ban.onrender.com \
  --dart-define=MOBILE_PAYMENT_MODE=hpp \
  --dart-define=OPEN_PAYMENT_IN_EXTERNAL_BROWSER=false \
  --dart-define=TOURY_CLIENT_CASH_FALLBACK=true

CUSTOMER_BUILT="$(archive_export "$CUSTOMER_APP" "$CUSTOMER_OUT" "customer")"
CUSTOMER_IPA="$(ls -1t "$CUSTOMER_OUT"/*.ipa | head -1)"
echo "Customer IPA: $CUSTOMER_IPA"
upload_one "$CUSTOMER_IPA"

# ---------- Driver ----------
DRIVER_APP="$ROOT/mndob-main"
cd "$DRIVER_APP"
flutter build ios --release --no-codesign

DRIVER_BUILT="$(archive_export "$DRIVER_APP" "$DRIVER_OUT" "driver")"
SRC_IPA="$(ls -1t "$DRIVER_OUT"/*.ipa | head -1)"
if [[ "$(basename "$SRC_IPA")" != "MNDOB.ipa" ]]; then
  cp -f "$SRC_IPA" "$DRIVER_OUT/MNDOB.ipa"
fi
DRIVER_IPA="$DRIVER_OUT/MNDOB.ipa"
echo "Driver IPA: $DRIVER_IPA"
upload_one "$DRIVER_IPA"

echo "DONE"
ls -lah "$CUSTOMER_OUT"/*.ipa "$DRIVER_OUT"/*.ipa
echo "CUSTOMER_IPA=$CUSTOMER_IPA"
echo "DRIVER_IPA=$DRIVER_IPA"
