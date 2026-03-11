#!/bin/bash
set -euo pipefail

# Build the executable
swift build -c release 2>&1

# Create .app bundle
APP_DIR="build/UpTo.app/Contents"
mkdir -p "$APP_DIR/MacOS"

# Copy executable
cp .build/release/UpTo "$APP_DIR/MacOS/UpTo"

# Create Info.plist
cat > "$APP_DIR/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>UpTo</string>
    <key>CFBundleDisplayName</key>
    <string>UpTo</string>
    <key>CFBundleIdentifier</key>
    <string>com.upto.app</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleExecutable</key>
    <string>UpTo</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
    </dict>
</dict>
</plist>
PLIST

echo ""
echo "Built: build/UpTo.app"
echo "Run:   open build/UpTo.app"
