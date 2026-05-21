#!/bin/bash
set -e

echo "Building DockLock..."
swift build

BINARY_PATH=$(find .build -name DockLock -type f -perm +111 | grep "debug/DockLock")

# Create a stable .app wrapper in the current directory
APP_NAME="DockLock.app"
echo "Packaging $APP_NAME..."
mkdir -p "$APP_NAME/Contents/MacOS"
mkdir -p "$APP_NAME/Contents/Resources"
cp "$BINARY_PATH" "$APP_NAME/Contents/MacOS/DockLock"
cp Info.plist "$APP_NAME/Contents/Info.plist"
cp AppIcon.icns "$APP_NAME/Contents/Resources/AppIcon.icns"

echo "Signing $APP_NAME..."
codesign -s - -f --entitlements Entitlements.plist "$APP_NAME"

echo "DockLock.app is ready."
echo "--------------------------------------------------------"
echo "1. Drag the 'DockLock.app' from this folder into Settings > Accessibility."
echo "2. If it's already there, remove it and add this one."
echo "3. Launching the app now..."
echo "--------------------------------------------------------"

open "$APP_NAME"
