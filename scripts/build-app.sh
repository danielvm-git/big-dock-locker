#!/bin/bash
set -e

echo "Building DockLock in Release mode..."
swift build -c release

# Find the binary
BINARY_PATH=$(find .build -name DockLock -type f -perm +111 | grep "release/DockLock")

if [ -z "$BINARY_PATH" ]; then
    echo "Error: Could not find release binary."
    exit 1
fi

APP_NAME="DockLock.app"
echo "Packaging $APP_NAME..."
rm -rf "$APP_NAME"
mkdir -p "$APP_NAME/Contents/MacOS"
mkdir -p "$APP_NAME/Contents/Resources"

cp "$BINARY_PATH" "$APP_NAME/Contents/MacOS/DockLock"
cp Info.plist "$APP_NAME/Contents/Info.plist"
cp AppIcon.icns "$APP_NAME/Contents/Resources/AppIcon.icns"

echo "Signing $APP_NAME..."
codesign -s - -f --entitlements Entitlements.plist "$APP_NAME"

echo "Done! $APP_NAME is ready."
