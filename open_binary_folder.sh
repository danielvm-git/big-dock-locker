#!/bin/bash

# Find the debug binary path
BINARY_PATH=$(find .build -name BigDockLocker -type f -perm +111 | grep "debug/BigDockLocker" | head -n 1)

if [ -n "$BINARY_PATH" ]; then
    BINARY_DIR=$(dirname "$BINARY_PATH")
    echo "Opening folder: $BINARY_DIR"
    open "$BINARY_DIR"
    echo "--------------------------------------------------------"
    echo "1. In the Finder window that just opened, look for 'BigDockLocker'."
    echo "2. If you don't see anything, press Cmd + Shift + . (dot) to show hidden files."
    echo "3. Drag the 'BigDockLocker' file into your Accessibility settings list."
    echo "--------------------------------------------------------"
else
    echo "Binary not found. Please run ./run.sh first to build the project."
fi
