#!/bin/bash
VERSION=$1
echo "Bumping version to $VERSION in Info.plist and README.md..."

# Update Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" Info.plist

# Update README.md (vX.Y pattern)
# Specifically looking for "**v1.1 Signature Edition**" or similar and replacing the version
# We use a more flexible pattern for the version number
sed -i '' "s/\*\*v[0-9]*\.[0-9]*[^\*]*\*\*/\*\*v$VERSION Signature Edition\*\*/g" README.md

echo "Done."
