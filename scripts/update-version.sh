#!/bin/bash
VERSION=$1
echo "Bumping version to $VERSION in Info.plist..."

# Update CFBundleShortVersionString (Marketing Version)
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" Info.plist

# Update CFBundleVersion (Build Version) - using the same for simplicity or you can use a timestamp/counter
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" Info.plist
