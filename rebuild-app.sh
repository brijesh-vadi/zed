#!/usr/bin/env bash

set -euo pipefail

echo "🔨 Rebuilding Zed with single-file diff feature..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Clean previous builds
print_status "Cleaning previous builds..."
rm -rf /Users/brijesh/Desktop/Zed.app
rm -f /Users/brijesh/Desktop/Zed.dmg

# Build release binaries
print_status "Building release binaries..."
if ! cargo build --release --package zed --package cli; then
    print_error "Build failed!"
    exit 1
fi

print_success "Build completed successfully"

# Create app bundle
print_status "Creating app bundle..."
mkdir -p /Users/brijesh/Desktop/Zed.app/Contents/MacOS
mkdir -p /Users/brijesh/Desktop/Zed.app/Contents/Resources

# Copy binaries
cp target/release/zed /Users/brijesh/Desktop/Zed.app/Contents/MacOS/
cp target/release/cli /Users/brijesh/Desktop/Zed.app/Contents/MacOS/

# Copy assets
cp -r assets/* /Users/brijesh/Desktop/Zed.app/Contents/Resources/

# Copy stable release icons
cp crates/zed/resources/app-icon.png /Users/brijesh/Desktop/Zed.app/Contents/Resources/
cp crates/zed/resources/app-icon@2x.png /Users/brijesh/Desktop/Zed.app/Contents/Resources/

# Create icns file
rm -rf /tmp/zed-icons.iconset
mkdir -p /tmp/zed-icons.iconset
cp crates/zed/resources/app-icon.png /tmp/zed-icons.iconset/icon_512x512.png
cp crates/zed/resources/app-icon@2x.png /tmp/zed-icons.iconset/icon_512x512@2x.png
iconutil -c icns /tmp/zed-icons.iconset -o /Users/brijesh/Desktop/Zed.app/Contents/Resources/app-icon.icns

# Create Info.plist
cat > /Users/brijesh/Desktop/Zed.app/Contents/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDisplayName</key>
	<string>Zed</string>
	<key>CFBundleExecutable</key>
	<string>zed</string>
	<key>CFBundleIconFile</key>
	<string>app-icon</string>
	<key>CFBundleIdentifier</key>
	<string>dev.zed.Zed</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>Zed</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>0.157.0</string>
	<key>CFBundleVersion</key>
	<string>157000</string>
	<key>LSMinimumSystemVersion</key>
	<string>10.15.7</string>
	<key>NSHighResolutionCapable</key>
	<true/>
	<key>NSSupportsAutomaticGraphicsSwitching</key>
	<true/>
	<key>CFBundleURLTypes</key>
	<array>
		<dict>
			<key>CFBundleURLName</key>
			<string>zed</string>
			<key>CFBundleURLSchemes</key>
			<array>
				<string>zed</string>
			</array>
		</dict>
	</array>
	<key>CFBundleSupportedPlatforms</key>
	<array>
		<string>MacOSX</string>
	</array>
	<key>CFBundleDocumentTypes</key>
	<array>
		<dict>
			<key>CFBundleTypeIconFile</key>
			<string>Document</string>
			<key>CFBundleTypeRole</key>
			<string>Editor</string>
			<key>LSHandlerRank</key>
			<string>Alternate</string>
			<key>LSItemContentTypes</key>
			<array>
				<string>public.folder</string>
				<string>public.plain-text</string>
				<string>public.text</string>
				<string>public.utf8-plain-text</string>
			</array>
		</dict>
		<dict>
			<key>CFBundleTypeIconFile</key>
			<string>Document</string>
			<key>CFBundleTypeName</key>
			<string>Zed Text Document</string>
			<key>CFBundleTypeRole</key>
			<string>Editor</string>
			<key>CFBundleTypeOSTypes</key>
			<array>
				<string>****</string>
			</array>
			<key>LSHandlerRank</key>
			<string>Default</string>
			<key>CFBundleTypeExtensions</key>
			<array>
				<string>Gemfile</string>
				<string>c</string>
				<string>c++</string>
				<string>cc</string>
				<string>cpp</string>
				<string>css</string>
				<string>erb</string>
				<string>ex</string>
				<string>exs</string>
				<string>go</string>
				<string>h</string>
				<string>h++</string>
				<string>hh</string>
				<string>hpp</string>
				<string>html</string>
				<string>js</string>
				<string>json</string>
				<string>jsx</string>
				<string>md</string>
				<string>py</string>
				<string>rb</string>
				<string>rkt</string>
				<string>rs</string>
				<string>scm</string>
				<string>toml</string>
				<string>ts</string>
				<string>tsx</string>
				<string>txt</string>
			</array>
		</dict>
	</array>
	<key>NSCameraUsageDescription</key>
	<string>Zed uses the camera to take photos for use in comments.</string>
	<key>NSMicrophoneUsageDescription</key>
	<string>Zed uses the microphone to capture audio for use in comments.</string>
</dict>
</plist>
EOF

# Create CLI install script
cat > /Users/brijesh/Desktop/Zed.app/Contents/MacOS/install-cli.sh << 'EOF'
#!/usr/bin/env bash

set -euo pipefail

# Create symlinks for CLI tools in /usr/local/bin
CLI_SOURCE="/Applications/Zed.app/Contents/MacOS/cli"
CLI_TARGET="/usr/local/bin/zed"

if [[ ! -d "/usr/local/bin" ]]; then
    echo "Creating /usr/local/bin directory..."
    sudo mkdir -p /usr/local/bin
fi

if [[ -L "$CLI_TARGET" ]]; then
    echo "Removing existing CLI symlink..."
    sudo rm "$CLI_TARGET"
fi

if [[ -f "$CLI_TARGET" ]]; then
    echo "Removing existing CLI file..."
    sudo rm "$CLI_TARGET"
fi

echo "Creating CLI symlink..."
sudo ln -sf "$CLI_SOURCE" "$CLI_TARGET"

echo "Zed CLI installed successfully!"
echo "You can now use 'zed' command from anywhere in your terminal."
EOF

chmod +x /Users/brijesh/Desktop/Zed.app/Contents/MacOS/install-cli.sh

# Create DMG
print_status "Creating DMG..."
hdiutil create -volname "Zed" -srcfolder /Users/brijesh/Desktop/Zed.app -ov -format UDZO /Users/brijesh/Desktop/Zed.dmg

print_success "🎉 Rebuild completed successfully!"
print_status "Created:"
echo "  📱 /Users/brijesh/Desktop/Zed.app"
echo "  💿 /Users/brijesh/Desktop/Zed.dmg"

# Verify architecture
ARCH=$(file /Users/brijesh/Desktop/Zed.app/Contents/MacOS/zed | grep -o "arm64\|x86_64")
print_status "Architecture: $ARCH"

echo ""
print_status "Ready to install and test your updated Zed with single-file diff feature!"
