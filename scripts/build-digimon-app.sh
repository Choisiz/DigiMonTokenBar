#!/bin/bash
# Build a local, ad-hoc signed fork without installing or terminating any app.
set -euo pipefail
cd "$(dirname "$0")/.."
python3 scripts/check-digimon-artwork-distribution.py
CONFIGURATION="${DIGITOKEN_CONFIGURATION:-release}"
SCRATCH_PATH="${DIGITOKEN_SCRATCH_PATH:-.build}"
swift build -c "$CONFIGURATION" --scratch-path "$SCRATCH_PATH"
BIN_DIR="$(swift build -c "$CONFIGURATION" --scratch-path "$SCRATCH_PATH" --show-bin-path)"
APP="${DIGITOKEN_OUTPUT_DIR:-build}/DigiTokenBar.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/PokeTokenBar" "$APP/Contents/MacOS/DigiTokenBar"
# Remove debug/local symbols that can embed the builder's home directory.
strip -S -x "$APP/Contents/MacOS/DigiTokenBar"
# Carry resources in the normal app resource directory (no build-directory dependency).
# Remove the prior resource directory when reusing an output path: cp -R alone leaves stale art.
rm -rf "$APP/Contents/Resources/Digimon"
cp -R Sources/PokeTokenBar/Resources/Digimon "$APP/Contents/Resources/"
python3 scripts/check-digimon-artwork-distribution.py --resources "$APP/Contents/Resources/Digimon"
cp Sources/PokeTokenBar/Resources/Digimon/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
cp LICENSE NOTICE.md THIRD_PARTY_NOTICES.md "$APP/Contents/Resources/"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>local.digitokenbar.app</string>
<key>CFBundleName</key><string>DigiTokenBar</string>
<key>CFBundleExecutable</key><string>DigiTokenBar</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.1.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>LSUIElement</key><true/>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
# Preserve optional login support under the fork's own identifier.
mkdir -p "$APP/Contents/Library/LaunchAgents"
cat > "$APP/Contents/Library/LaunchAgents/io.github.chattymin.digitokenbar.login.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>Label</key><string>io.github.chattymin.digitokenbar.login</string>
<key>ProgramArguments</key><array><string>/Applications/DigiTokenBar.app/Contents/MacOS/DigiTokenBar</string></array>
<key>RunAtLoad</key><true/>
<key>KeepAlive</key><dict><key>SuccessfulExit</key><false/></dict>
<key>LimitLoadToSessionType</key><string>Aqua</string>
</dict></plist>
PLIST
codesign --force -s - "$APP"
echo "Built: $PWD/$APP"
