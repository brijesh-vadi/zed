#!/bin/bash

# Custom Zed Update Script
# Updates your custom build with latest Zed changes

set -e  # Exit on error

echo "🔄 Updating Custom Zed Build..."

# Switch to main branch (which now has your feature)
echo "📥 Pulling latest Zed updates..."
git checkout main

# Stash any uncommitted changes
git stash push -m "Auto-stash before update"

# Create a temporary branch from upstream
git fetch upstream
git checkout -b temp-upstream upstream/main

# Switch back to main and merge upstream changes
git checkout main
git merge temp-upstream

# Clean up temporary branch
git branch -d temp-upstream

# Push updated main to your fork
git push origin main

# Restore any stashed changes
git stash pop 2>/dev/null || echo "No stashed changes to restore"

# Clean and rebuild (Metal shaders now work!)
echo "🏗️  Building updated Zed with Metal support..."
rm -rf target/
cargo build --release

# Export new build as .app bundle
BUILD_DATE=$(date +%Y%m%d-%H%M%S)
EXPORT_PATH="$HOME/Downloads/Zed-Custom-$BUILD_DATE.app"
echo "📦 Creating .app bundle at $EXPORT_PATH"

# Create app bundle structure
mkdir -p "$EXPORT_PATH/Contents/"{MacOS,Resources}

# Copy binary
cp target/release/zed "$EXPORT_PATH/Contents/MacOS/"
chmod +x "$EXPORT_PATH/Contents/MacOS/zed"

# Create Info.plist
cat > "$EXPORT_PATH/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDisplayName</key>
    <string>Zed Custom</string>
    <key>CFBundleExecutable</key>
    <string>zed</string>
    <key>CFBundleIconFile</key>
    <string>app-icon</string>
    <key>CFBundleIdentifier</key>
    <string>dev.zed.Zed-Custom</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Zed Custom</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.206.0-custom</string>
    <key>CFBundleVersion</key>
    <string>0.206.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.15.7</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>© 2024 Zed Industries, Inc. (Custom Build)</string>
</dict>
</plist>
EOF

# Create app icon
mkdir -p /tmp/zed-icon.iconset
cp crates/zed/resources/app-icon.png /tmp/zed-icon.iconset/icon_512x512.png
cp crates/zed/resources/app-icon@2x.png /tmp/zed-icon.iconset/icon_512x512@2x.png
iconutil -c icns /tmp/zed-icon.iconset -o "$EXPORT_PATH/Contents/Resources/app-icon.icns"
rm -rf /tmp/zed-icon.iconset

echo "✅ Update Complete! New .app bundle available at $EXPORT_PATH"
echo "🚀 You can run it by double-clicking or: open '$EXPORT_PATH'"
