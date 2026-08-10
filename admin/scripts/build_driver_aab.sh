#!/usr/bin/env bash
# Build driver Google Play AAB (release).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/mndob-main"
OUT="$ROOT/releases/$(date +%Y-%m-%d)/driver"
mkdir -p "$OUT"

export JAVA_HOME="${JAVA_HOME:-/opt/homebrew/opt/openjdk@17}"
export ANDROID_HOME="${ANDROID_HOME:-/opt/homebrew/share/android-commandlinetools}"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

printf 'sdk.dir=%s\n' "$ANDROID_HOME" > "$APP/android/local.properties"

if [[ ! -f "$APP/android/key.properties" ]]; then
  cat <<EOF
MISSING $APP/android/key.properties

  cp $APP/android/key.properties.example $APP/android/key.properties
  # put mndob-upload-keystore.jks in android/
EOF
  exit 2
fi

cd "$APP"
flutter build appbundle --release 2>&1 | tee "$OUT/aab-build.log"
AAB="$APP/build/app/outputs/bundle/release/app-release.aab"
cp -f "$AAB" "$OUT/TouriTaxi-driver.aab"
ls -lah "$OUT/TouriTaxi-driver.aab"
echo "READY: $OUT/TouriTaxi-driver.aab"
