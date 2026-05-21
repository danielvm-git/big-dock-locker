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

echo "Building DockLock for $ARCH in Release mode..."
swift build -c release --arch "$ARCH"

# Find the binary
BINARY_PATH=$(find .build/"$ARCH"-apple-macosx/release -name DockLock -type f -perm +111 2>/dev/null | head -n 1)

if [ -z "$BINARY_PATH" ]; then
    echo "Error: Could not find release binary for $ARCH."
    exit 1
fi

APP_NAME="DockLock-$ARCH.app"
echo "Packaging $APP_NAME..."
rm -rf "$APP_NAME"
mkdir -p "$APP_NAME/Contents/MacOS"
mkdir -p "$APP_NAME/Contents/Resources"

cp "$BINARY_PATH" "$APP_NAME/Contents/MacOS/DockLock"
cp Info.plist "$APP_NAME/Contents/Info.plist"
cp AppIcon.icns "$APP_NAME/Contents/Resources/AppIcon.icns"

echo "Signing $APP_NAME..."
codesign --force --digest-algorithm=sha256 -s - --entitlements Entitlements.plist "$APP_NAME"

echo "Done! $APP_NAME is ready."
