#!/bin/bash
# fix-quarantine.sh - A utility to help users run DockLock if Gatekeeper blocks it.

TARGET_PATH="${1:-/Applications/DockLock.app}"

if [ ! -e "$TARGET_PATH" ]; then
    echo "❌ Error: '$TARGET_PATH' not found."
    echo "Usage: $0 [path_to_app_or_dmg]"
    echo "Default: /Applications/DockLock.app"
    exit 1
fi

echo "🛡️ Removing quarantine attribute from $TARGET_PATH..."
# We use sudo only if needed, and -r for recursive if it's a directory
if [ -d "$TARGET_PATH" ]; then
    sudo xattr -rd com.apple.quarantine "$TARGET_PATH"
else
    sudo xattr -d com.apple.quarantine "$TARGET_PATH"
fi

echo "✅ Done! You should now be able to open it."
echo "If you still have issues, Right-Click the file and select 'Open'."
