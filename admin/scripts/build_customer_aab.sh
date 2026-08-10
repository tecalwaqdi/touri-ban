#!/usr/bin/env bash
# Build customer Google Play AAB (release).
# Requires: ANDROID_HOME/JAVA_HOME, and android/key.properties + upload .jks
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/ara_oatan_app"
OUT="$ROOT/releases/$(date +%Y-%m-%d)/customer"
mkdir -p "$OUT"

export JAVA_HOME="${JAVA_HOME:-/opt/homebrew/opt/openjdk@17}"
export ANDROID_HOME="${ANDROID_HOME:-/opt/homebrew/share/android-commandlinetools}"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

printf 'sdk.dir=%s\n' "$ANDROID_HOME" > "$APP/android/local.properties"

if [[ ! -f "$APP/android/key.properties" ]]; then
  cat <<EOF
MISSING $APP/android/key.properties

Copy example and fill passwords + place the upload keystore next to it:
  cp $APP/android/key.properties.example $APP/android/key.properties
  # put tutorial-multi-language-app-aavlbx-keystore.jks in android/

Without the SAME upload key registered in Play Console, Google will reject the AAB.
EOF
  exit 2
fi

DEFINES=(
  --dart-define=ENABLE_ONLINE_PAYMENT=true
  --dart-define=PAYMENT_BACKEND=external_api
  --dart-define=PAYMENT_API_BASE_URL=https://touri-ban.onrender.com
  --dart-define=OPEN_PAYMENT_IN_EXTERNAL_BROWSER=true
  --dart-define=TOURY_CLIENT_CASH_FALLBACK=true
)

cd "$APP"
flutter build appbundle --release "${DEFINES[@]}" 2>&1 | tee "$OUT/aab-build.log"

AAB="$APP/build/app/outputs/bundle/release/app-release.aab"
cp -f "$AAB" "$OUT/TouriTaxi-customer.aab"
ls -lah "$OUT/TouriTaxi-customer.aab"
echo "READY: $OUT/TouriTaxi-customer.aab"
