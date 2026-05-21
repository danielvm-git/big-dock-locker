#!/bin/bash
set -e

echo "Building BigDockLocker..."
swift build

BINARY_PATH=$(find .build -name BigDockLocker -type f -perm +111 | grep "debug/BigDockLocker")

# Create a stable .app wrapper in the current directory
APP_NAME="BigDockLocker.app"
echo "Packaging $APP_NAME..."
mkdir -p "$APP_NAME/Contents/MacOS"
mkdir -p "$APP_NAME/Contents/Resources"
cp "$BINARY_PATH" "$APP_NAME/Contents/MacOS/BigDockLocker"
cp Info.plist "$APP_NAME/Contents/Info.plist"
cp AppIcon.icns "$APP_NAME/Contents/Resources/AppIcon.icns"

echo "Signing $APP_NAME..."
codesign -s - -f --entitlements Entitlements.plist "$APP_NAME"

echo "BigDockLocker.app is ready."
echo "--------------------------------------------------------"
echo "1. Drag the 'BigDockLocker.app' from this folder into Settings > Accessibility."
echo "2. If it's already there, remove it and add this one."
echo "3. Launching the app now..."
echo "--------------------------------------------------------"

open "$APP_NAME"
