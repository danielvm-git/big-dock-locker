#!/bin/bash
set -e

echo "Building DockLock..."
swift build

BINARY_PATH=$(find .build -name DockLock -type f -perm +111 | grep "debug/DockLock")

echo "Ad-hoc signing binary at $BINARY_PATH..."
codesign -s - -f --entitlements Entitlements.plist "$BINARY_PATH"

echo "Launching DockLock..."
"$BINARY_PATH"
