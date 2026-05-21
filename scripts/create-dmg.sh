#!/bin/bash
set -e

ARCH="arm64"
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --arch) ARCH="$2"; shift ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

APP_NAME="DockLock-$ARCH.app"
if [ "$ARCH" == "arm64" ]; then
    DMG_LABEL="apple-silicon-mac"
else
    DMG_LABEL="intel-mac"
fi
DMG_NAME="DockLock-$DMG_LABEL.dmg"

# Ensure the app exists
if [ ! -d "$APP_NAME" ]; then
    echo "Error: $APP_NAME not found. Please run ./scripts/build-app.sh --arch $ARCH first."
    exit 1
fi

echo "Creating $DMG_NAME..."

# Remove existing DMG if it exists
if [ -f "$DMG_NAME" ]; then
    rm "$DMG_NAME"
fi

# Use the create-dmg npm package to generate the disk image
npx create-dmg "$APP_NAME" --overwrite --no-code-sign --no-version-in-filename

# create-dmg is stubborn and might just use "DockLock.dmg" 
# or "DockLock-arm64.dmg" depending on its mood.
# Let's find the DMG it just created.
CREATED_DMG=$(ls -t *.dmg 2>/dev/null | head -n 1)

if [ -n "$CREATED_DMG" ] && [ "$CREATED_DMG" != "$DMG_NAME" ]; then
    mv "$CREATED_DMG" "$DMG_NAME"
fi

if [ ! -f "$DMG_NAME" ]; then
    echo "Error: $DMG_NAME was not created."
    exit 1
fi

echo "Done! $DMG_NAME is ready."
