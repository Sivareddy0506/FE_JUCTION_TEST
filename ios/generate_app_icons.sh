#!/bin/bash

# Script to generate all iOS app icons from assets/logo.png

LOGO_PATH="../assets/logo.png"
ICON_DIR="Runner/Assets.xcassets/AppIcon.appiconset"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🎨 Generating iOS App Icons from logo.png..."
echo ""

# Check if logo exists
if [ ! -f "$LOGO_PATH" ]; then
    echo "❌ Error: Logo file not found at $LOGO_PATH"
    exit 1
fi

# Check if ImageMagick is available
if ! command -v convert &> /dev/null && ! command -v magick &> /dev/null; then
    echo "❌ Error: ImageMagick not found. Please install it:"
    echo "   brew install imagemagick"
    exit 1
fi

# Use magick if available, otherwise convert
if command -v magick &> /dev/null; then
    CONVERT_CMD="magick"
else
    CONVERT_CMD="convert"
fi

echo "✅ Logo found: $LOGO_PATH"
echo "✅ Output directory: $ICON_DIR"
echo ""

# Function to generate icon
generate_icon() {
    local size=$1
    local scale=$2
    local filename=$3
    local actual_size=$((size * scale))
    
    echo -n "  Generating ${filename} (${actual_size}x${actual_size})... "
    
    $CONVERT_CMD "$LOGO_PATH" \
        -resize ${actual_size}x${actual_size} \
        -background white \
        -gravity center \
        -extent ${actual_size}x${actual_size} \
        -alpha off \
        "$ICON_DIR/$filename" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${YELLOW}⚠${NC}"
    fi
}

# iPhone Icons
echo "📱 Generating iPhone icons..."
generate_icon 20 2 "Icon-App-20x20@2x.png"
generate_icon 20 3 "Icon-App-20x20@3x.png"
generate_icon 29 1 "Icon-App-29x29@1x.png"
generate_icon 29 2 "Icon-App-29x29@2x.png"
generate_icon 29 3 "Icon-App-29x29@3x.png"
generate_icon 40 2 "Icon-App-40x40@2x.png"
generate_icon 40 3 "Icon-App-40x40@3x.png"
generate_icon 60 2 "Icon-App-60x60@2x.png"
generate_icon 60 3 "Icon-App-60x60@3x.png"

# iPad Icons
echo ""
echo "📱 Generating iPad icons..."
generate_icon 20 1 "Icon-App-20x20@1x.png"
generate_icon 29 1 "Icon-App-29x29@1x.png"  # Already generated, but needed for iPad
generate_icon 29 2 "Icon-App-29x29@2x.png"  # Already generated, but needed for iPad
generate_icon 40 1 "Icon-App-40x40@1x.png"
generate_icon 40 2 "Icon-App-40x40@2x.png"  # Already generated, but needed for iPad
generate_icon 76 1 "Icon-App-76x76@1x.png"
generate_icon 76 2 "Icon-App-76x76@2x.png"
# 83.5x83.5 @2x = 167x167
echo -n "  Generating Icon-App-83.5x83.5@2x.png (167x167)... "
$CONVERT_CMD "$LOGO_PATH" \
    -resize 167x167 \
    -background white \
    -gravity center \
    -extent 167x167 \
    -alpha off \
    "$ICON_DIR/Icon-App-83.5x83.5@2x.png" 2>/dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠${NC}"
fi

# App Store Icon (1024x1024)
echo ""
echo "🏪 Generating App Store icon..."
generate_icon 1024 1 "Icon-App-1024x1024@1x.png"

echo ""
echo "✅ All app icons generated successfully!"
echo ""
echo "📋 Next steps:"
echo "   1. Open Xcode: open Runner.xcworkspace"
echo "   2. Navigate to: Assets.xcassets → AppIcon"
echo "   3. Verify all icons are showing correctly"
echo "   4. Clean build folder: Product → Clean Build Folder"
echo "   5. Archive: Product → Archive"
echo ""

