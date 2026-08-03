#!/usr/bin/env bash
# Build iOS IPA on macOS (requires Xcode + CocoaPods + Flutter).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "==> Flutter pub get"
flutter pub get

echo "==> CocoaPods"
cd ios
if ! command -v pod >/dev/null 2>&1; then
  echo "ERROR: install CocoaPods first: sudo gem install cocoapods"
  exit 1
fi
pod install --repo-update
cd "$ROOT"

echo "==> Build IPA (open Xcode first if signing is not configured)"
echo "    Xcode: ios/Runner.xcworkspace -> Signing & Capabilities -> Team"
flutter build ipa --release

IPA_DIR="$ROOT/build/ios/ipa"
if compgen -G "$IPA_DIR/*.ipa" >/dev/null; then
  echo ""
  echo "SUCCESS. IPA files:"
  ls -lh "$IPA_DIR"/*.ipa
  echo ""
  echo "Install options:"
  echo "  1) TestFlight: upload via Xcode Organizer or Transporter app"
  echo "  2) Ad-hoc: flutter build ipa --export-method ad-hoc (register device UDID in Apple Developer)"
  echo "  3) USB: flutter run --release -d <iphone-id> with phone connected to this Mac"
else
  echo "Build finished; check build/ios/ for output."
fi
