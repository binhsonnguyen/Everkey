#!/bin/bash
set -e

cd "$(dirname "$0")/.."

APP_DIR="./Everkey.app"
CONTENTS="$APP_DIR/Contents"

# Build
cd app && swift build -c debug 2>&1 && cd ..

# Create .app bundle
mkdir -p "$CONTENTS/MacOS"
cp app/.build/arm64-apple-macosx/debug/Everkey "$CONTENTS/MacOS/"
cp app/Resources/Info.plist "$CONTENTS/"

# Code sign (ad-hoc)
codesign -s - -f "$APP_DIR" 2>/dev/null

echo "✅ Everkey.app ready. Run: open ./Everkey.app"
