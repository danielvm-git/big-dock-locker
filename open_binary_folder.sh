#!/bin/bash

# Find the debug binary path
BINARY_PATH=$(find .build -name DockLock -type f -perm +111 | grep "debug/DockLock" | head -n 1)

if [ -n "$BINARY_PATH" ]; then
    BINARY_DIR=$(dirname "$BINARY_PATH")
    echo "Opening folder: $BINARY_DIR"
    open "$BINARY_DIR"
    echo "--------------------------------------------------------"
    echo "1. In the Finder window that just opened, look for 'DockLock'."
    echo "2. If you don't see anything, press Cmd + Shift + . (dot) to show hidden files."
    echo "3. Drag the 'DockLock' file into your Accessibility settings list."
    echo "--------------------------------------------------------"
else
    echo "Binary not found. Please run ./run.sh first to build the project."
fi
