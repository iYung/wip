#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

LOVE_VERSION="11.5"
LOVE_URL="https://github.com/love2d/love/releases/download/${LOVE_VERSION}/love-${LOVE_VERSION}-macos.zip"
RUNTIME_DIR="dist/runtimes"
RUNTIME_ZIP="${RUNTIME_DIR}/love-${LOVE_VERSION}-macos.zip"
OUT_DIR="dist/mac"
APP_NAME="Frobert Grows Plants With Increasing Speed and Quantity For Profit"
APP_BUNDLE="${OUT_DIR}/${APP_NAME}.app"
ZIP_OUT="dist/frobert-mac.zip"

mkdir -p "$RUNTIME_DIR" "$OUT_DIR"

# Download LÖVE runtime if not cached
if [ ! -f "$RUNTIME_ZIP" ]; then
    echo "Downloading LÖVE ${LOVE_VERSION} for macOS..."
    curl -L "$LOVE_URL" -o "$RUNTIME_ZIP"
fi

echo "Extracting LÖVE runtime..."
rm -rf "${OUT_DIR:?}/"*
unzip -q "$RUNTIME_ZIP" -d "$OUT_DIR"
mv "${OUT_DIR}/love.app" "$APP_BUNDLE"

echo "Building game.love..."
zip -q -r "${APP_BUNDLE}/Contents/Resources/game.love" main.lua conf.lua lua/ assets/

echo "Setting icon..."
python3 scripts/make_icns.py assets/images/icon.png assets/images/icon.icns
cp assets/images/icon.icns "${APP_BUNDLE}/Contents/Resources/OS X AppIcon.icns"
cp assets/images/icon.icns "${APP_BUNDLE}/Contents/Resources/GameIcon.icns"

echo "Patching Info.plist..."
PLIST="${APP_BUNDLE}/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleName '${APP_NAME}'" "$PLIST"
/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName '${APP_NAME}'" "$PLIST" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string '${APP_NAME}'" "$PLIST"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier 'com.ivanyung.frobert'" "$PLIST"
/usr/libexec/PlistBuddy -c "Delete :CFBundleIconName" "$PLIST" 2>/dev/null || true

echo "Zipping..."
rm -f "$ZIP_OUT"
cd dist/mac
zip -q -r "../../$ZIP_OUT" "${APP_NAME}.app"
cd ../..

echo "Done → ${ZIP_OUT}"
