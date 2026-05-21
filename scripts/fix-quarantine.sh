#!/bin/bash
# fix-quarantine.sh - A utility to help users run DockLock if Gatekeeper blocks it.

APP_PATH="/Applications/DockLock.app"

if [ ! -d "$APP_PATH" ]; then
    echo "❌ Error: DockLock.app not found in /Applications."
    echo "Please move the app to your Applications folder first."
    exit 1
fi

echo "🛡️ Removing quarantine attribute from DockLock..."
sudo xattr -rd com.apple.quarantine "$APP_PATH"

echo "✅ Done! You should now be able to open DockLock."
echo "If you still have issues, Right-Click the app and select 'Open'."
