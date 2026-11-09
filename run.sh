#!/bin/bash
set -e

echo "Building BigDockLocker..."
swift build

# Ask SwiftPM where the binary is; the .build layout differs between toolchains.
BINARY_PATH="$(swift build --show-bin-path)/BigDockLocker"

# Create a stable .app wrapper in the current directory
APP_NAME="BigDockLocker.app"
echo "Packaging $APP_NAME..."
mkdir -p "$APP_NAME/Contents/MacOS"
mkdir -p "$APP_NAME/Contents/Resources"
cp "$BINARY_PATH" "$APP_NAME/Contents/MacOS/BigDockLocker"
cp Info.plist "$APP_NAME/Contents/Info.plist"
cp AppIcon.icns "$APP_NAME/Contents/Resources/AppIcon.icns"

echo "Signing $APP_NAME..."
# TCC keys an Accessibility grant to the app's *designated requirement*. Ad-hoc
# signing without --requirements embeds `cdhash H"..."`, so every rebuild
# invalidates the user's grant (tccd logs: "Failed to match existing code
# requirement for subject com.danielvm.BigDockLocker"). Pin the requirement to
# the bundle identifier so the grant survives updates.
codesign --force --digest-algorithm=sha256 -s - \
    --identifier com.danielvm.BigDockLocker \
    --requirements '=designated => identifier "com.danielvm.BigDockLocker"' \
    --entitlements Entitlements.plist "$APP_NAME"

codesign -d -r- "$APP_NAME" 2>&1 | grep -q 'designated => identifier "com.danielvm.BigDockLocker"' || {
    echo "Error: designated requirement is not pinned; the Accessibility grant would break on update."
    exit 1
}

echo "BigDockLocker.app is ready."
echo "--------------------------------------------------------"
echo "1. Drag the 'BigDockLocker.app' from this folder into Settings > Accessibility."
echo "2. If it's already there, remove it and add this one."
echo "3. Launching the app now..."
echo "--------------------------------------------------------"

open "$APP_NAME"
