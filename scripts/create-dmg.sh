#!/bin/bash
set -e

APP_NAME="DockLock.app"
DMG_NAME="DockLock.dmg"

# Ensure the app exists
if [ ! -d "$APP_NAME" ]; then
    echo "Error: $APP_NAME not found. Please run ./run.sh first."
    exit 1
fi

echo "Creating $DMG_NAME..."

# Remove existing DMG if it exists
if [ -f "$DMG_NAME" ]; then
    rm "$DMG_NAME"
fi

# Use the create-dmg npm package to generate the disk image
npx create-dmg "$APP_NAME" || true

# The tool often appends version/arch to the name, so let's normalize it back
mv DockLock*.dmg "$DMG_NAME"

echo "Done! $DMG_NAME is ready."
