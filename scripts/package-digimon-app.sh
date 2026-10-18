#!/bin/bash
# Prepare a local candidate. Never publish, install, notarize, or stop a running app.
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ "${DIGITOKEN_SESSION_TESTING:-0}" == "1" || "${DIGITOKEN_FREE_PENDANT:-0}" == "1" ]]; then
    echo "Refusing to package a test-session or free-pendant build." >&2
    exit 1
fi
export DIGITOKEN_CONFIGURATION=release
export DIGITOKEN_OUTPUT_DIR="${DIGITOKEN_OUTPUT_DIR:-build/distribution}"
./scripts/build-digimon-app.sh
APP="$DIGITOKEN_OUTPUT_DIR/DigiTokenBar.app"
PLIST="$APP/Contents/Info.plist"
VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$PLIST")
codesign --verify --deep --strict "$APP"
ARCHS=$(lipo -archs "$APP/Contents/MacOS/DigiTokenBar")
ARCH_LABEL=${ARCHS// /-}
ARCHIVE="$DIGITOKEN_OUTPUT_DIR/DigiTokenBar-$VERSION-macos-$ARCH_LABEL.zip"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ARCHIVE"
(cd "$DIGITOKEN_OUTPUT_DIR" && shasum -a 256 "$(basename "$ARCHIVE")" > "$(basename "$ARCHIVE").sha256")
echo "Local candidate: $ARCHIVE"
echo "Ad-hoc signature only; no notarization or third-party asset clearance is implied."
