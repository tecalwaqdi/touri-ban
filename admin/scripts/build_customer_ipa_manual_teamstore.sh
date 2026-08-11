#!/usr/bin/env bash
# Build customer App Store IPA with Manual signing + Xcode Team Store profiles
# (works when Xcode has No Accounts / Automatic cannot refresh profiles).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/ara_oatan_app"
PBX="$APP/ios/Runner.xcodeproj/project.pbxproj"
OUT="$ROOT/releases/$(date +%Y-%m-%d)/customer"
mkdir -p "$OUT"

PROFILE_APP='iOS Team Store Provisioning Profile: com.mycompany.araoatanapp2'
PROFILE_EXT='iOS Team Store Provisioning Profile: com.mycompany.araoatanapp2.ImageNotification'

EXPORT_PLIST="$OUT/ExportOptions.teamstore.plist"
cat > "$EXPORT_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key>
	<string>app-store-connect</string>
	<key>teamID</key>
	<string>7XPP94HATF</string>
	<key>signingStyle</key>
	<string>manual</string>
	<key>uploadSymbols</key>
	<true/>
	<key>destination</key>
	<string>export</string>
	<key>manageAppVersionAndBuildNumber</key>
	<false/>
	<key>signingCertificate</key>
	<string>Apple Distribution</string>
	<key>provisioningProfiles</key>
	<dict>
		<key>com.mycompany.araoatanapp2</key>
		<string>${PROFILE_APP}</string>
		<key>com.mycompany.araoatanapp2.ImageNotification</key>
		<string>${PROFILE_EXT}</string>
	</dict>
</dict>
</plist>
EOF

DEFINES=(
  --dart-define=ENABLE_ONLINE_PAYMENT=true
  --dart-define=PAYMENT_BACKEND=external_api
  --dart-define=PAYMENT_API_BASE_URL=https://touri-ban.onrender.com
  --dart-define=OPEN_PAYMENT_IN_EXTERNAL_BROWSER=true
  --dart-define=TOURY_CLIENT_CASH_FALLBACK=true
)

cd "$APP"
cp "$PBX" "$OUT/project.pbxproj.pre-manual"

python3 - "$PBX" "$PROFILE_APP" "$PROFILE_EXT" <<'PY'
import pathlib, sys
pbx = pathlib.Path(sys.argv[1])
profile_app, profile_ext = sys.argv[2], sys.argv[3]
lines = pbx.read_text().splitlines(keepends=True)
out = []
in_build = False
bundle = None
cfg_name = None
buf = []

def flush(buf, bundle, cfg_name):
    text = ''.join(buf)
    if cfg_name in ('Release', 'Profile') and bundle in (
        'com.mycompany.araoatanapp2',
        'com.mycompany.araoatanapp2.ImageNotification',
    ):
        profile = profile_app if bundle == 'com.mycompany.araoatanapp2' else profile_ext
        new = []
        for line in buf:
            if 'CODE_SIGN_STYLE = Automatic;' in line:
                indent = line[: len(line) - len(line.lstrip())]
                new.append(f'{indent}CODE_SIGN_STYLE = Manual;\n')
                new.append(f'{indent}CODE_SIGN_IDENTITY = "Apple Distribution";\n')
                new.append(f'{indent}PROVISIONING_PROFILE_SPECIFIER = "{profile}";\n')
            else:
                new.append(line)
        return new
    return buf

i = 0
while i < len(lines):
    line = lines[i]
    if 'buildSettings = {' in line:
        in_build = True
        bundle = None
        cfg_name = None
        buf = [line]
        i += 1
        continue
    if in_build:
        buf.append(line)
        if 'PRODUCT_BUNDLE_IDENTIFIER' in line:
            bundle = line.split('=', 1)[1].strip().rstrip(';').strip()
        if line.strip().startswith('name = '):
            cfg_name = line.split('=', 1)[1].strip().rstrip(';').strip()
            out.extend(flush(buf, bundle, cfg_name))
            in_build = False
            buf = []
        i += 1
        continue
    out.append(line)
    i += 1
if buf:
    out.extend(buf)

text = ''.join(out)
# Project-level Release/Profile identity → Distribution
text = text.replace(
    '"CODE_SIGN_IDENTITY[sdk=iphoneos*]" = "iPhone Developer";\n\t\t\t\tCOPY_PHASE_STRIP = NO;\n\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";',
    '"CODE_SIGN_IDENTITY[sdk=iphoneos*]" = "Apple Distribution";\n\t\t\t\tCOPY_PHASE_STRIP = NO;\n\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";',
)
pbx.write_text(text)
print('Patched project.pbxproj for Manual Team Store signing')
PY

restore_pbx() {
  if [[ -f "$OUT/project.pbxproj.pre-manual" ]]; then
    cp "$OUT/project.pbxproj.pre-manual" "$PBX"
    echo "Restored project.pbxproj"
  fi
}
trap restore_pbx EXIT

flutter build ios --release --no-codesign "${DEFINES[@]}"

ARCHIVE="$APP/build/ios/archive/Runner.xcarchive"
EXPORT_DIR="$APP/build/ios/ipa"
rm -rf "$ARCHIVE" "$EXPORT_DIR"
mkdir -p "$(dirname "$ARCHIVE")" "$EXPORT_DIR"

set +e
xcodebuild -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE" \
  DEVELOPMENT_TEAM=7XPP94HATF \
  archive 2>&1 | tee "$OUT/archive-teamstore.log"
ARC_RC=${PIPESTATUS[0]}
set -e

if [[ "$ARC_RC" -ne 0 ]]; then
  echo "ARCHIVE_FAILED rc=$ARC_RC" | tee "$OUT/STATUS.txt"
  exit "$ARC_RC"
fi

set +e
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportOptionsPlist "$EXPORT_PLIST" \
  -exportPath "$EXPORT_DIR" \
  2>&1 | tee "$OUT/export-teamstore.log"
EXP_RC=${PIPESTATUS[0]}
set -e

shopt -s nullglob
ipas=("$EXPORT_DIR"/*.ipa)
if ((${#ipas[@]})); then
  cp -f "${ipas[@]}" "$OUT/"
fi
ls -lah "$OUT"/*.ipa 2>/dev/null || echo "NO_IPA"
if [[ "$EXP_RC" -ne 0 ]]; then
  echo "EXPORT_FAILED rc=$EXP_RC" | tee "$OUT/STATUS.txt"
  exit "$EXP_RC"
fi
echo "READY" | tee "$OUT/STATUS.txt"
ls -lah "$OUT"
