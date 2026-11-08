#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "==> Building WarpBar in release mode..."
swift build -c release

BIN_DIR=$(swift build -c release --show-bin-path)
APP_BUNDLE="$SCRIPT_DIR/build/WarpBar.app"

echo "==> Packaging into $APP_BUNDLE..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BIN_DIR/WarpBar" "$APP_BUNDLE/Contents/MacOS/WarpBar"
chmod +x "$APP_BUNDLE/Contents/MacOS/WarpBar"

# Copy Resources
if [ -d "$SCRIPT_DIR/Resources" ]; then
    cp -R "$SCRIPT_DIR/Resources/"* "$APP_BUNDLE/Contents/Resources/"
fi

# Copy AppIcon if available
if [ -f "/Applications/Cloudflare WARP.app/Contents/Resources/AppIcon.icns" ]; then
    cp "/Applications/Cloudflare WARP.app/Contents/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi

# Write Info.plist
cat << 'EOF' > "$APP_BUNDLE/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>WarpBar</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.zero8dotdev.WarpBar</string>
    <key>CFBundleName</key>
    <string>WarpBar</string>
    <key>CFBundleDisplayName</key>
    <string>WarpBar</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
</dict>
</plist>
EOF

echo "==> Installing to /Applications/WarpBar.app..."
rm -rf "/Applications/WarpBar.app"
cp -R "$APP_BUNDLE" "/Applications/WarpBar.app"

echo "==> Successfully installed WarpBar to /Applications/WarpBar.app!"

