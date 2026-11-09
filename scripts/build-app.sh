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

echo "Building BigDockLocker for $ARCH in Release mode..."
swift build -c release --arch "$ARCH"

# Ask SwiftPM for the binary directory instead of guessing the layout: newer
# Xcode toolchains emit .build/out/Products/Release, older ones
# .build/<arch>-apple-macosx/release.
BIN_DIR=$(swift build -c release --arch "$ARCH" --show-bin-path)
BINARY_PATH="$BIN_DIR/BigDockLocker"

if [ ! -x "$BINARY_PATH" ]; then
    echo "Error: Could not find release binary for $ARCH at $BINARY_PATH."
    exit 1
fi

APP_NAME="BigDockLocker-$ARCH.app"
echo "Packaging $APP_NAME..."
rm -rf "$APP_NAME"
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

echo "Done! $APP_NAME is ready."
