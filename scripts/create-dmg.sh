#!/bin/bash
set -e

APP_NAME="DockLock.app"
DMG_NAME="DockLock.dmg"

# Ensure the app exists
if [ ! -d "$APP_NAME" ]; then
    echo "Error: $APP_NAME not found. Please run ./scripts/build-app.sh first."
    exit 1
fi

# Ensure Info.plist exists inside the app
if [ ! -f "$APP_NAME/Contents/Info.plist" ]; then
    echo "Error: $APP_NAME/Contents/Info.plist not found. App bundle is incomplete."
    exit 1
fi

echo "Creating $DMG_NAME..."

# Remove existing DMG if it exists
if [ -f "$DMG_NAME" ]; then
    rm "$DMG_NAME"
fi

# Use the create-dmg npm package to generate the disk image
# We use --identity=- to explicitly sign the DMG ad-hoc
npx create-dmg "$APP_NAME" --overwrite --identity=-

# The tool often appends version/arch to the name, so let's normalize it back
NEW_DMG=$(ls DockLock*.dmg | head -n 1)
if [ -n "$NEW_DMG" ]; then
    mv "$NEW_DMG" "$DMG_NAME"
else
    echo "Error: DMG file was not created."
    exit 1
fi

echo "Done! $DMG_NAME is ready and ad-hoc signed."
