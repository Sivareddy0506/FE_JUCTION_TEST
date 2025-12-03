#!/bin/bash

# Script to remove alpha channel from app icon
# This fixes the "Invalid large app icon" App Store error

ICON_PATH="Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png"
TEMP_ICON="Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x-temp.png"

cd "$(dirname "$0")"

if [ ! -f "$ICON_PATH" ]; then
    echo "Error: Icon file not found at $ICON_PATH"
    exit 1
fi

echo "Checking current icon format..."
file "$ICON_PATH"

echo ""
echo "Attempting to remove alpha channel..."

# Method 1: Try ImageMagick (if available)
if command -v convert &> /dev/null; then
    echo "Using ImageMagick..."
    convert "$ICON_PATH" -alpha off -background white -alpha remove "$TEMP_ICON"
    if [ $? -eq 0 ]; then
        mv "$TEMP_ICON" "$ICON_PATH"
        echo "✅ Icon fixed using ImageMagick"
        file "$ICON_PATH"
        exit 0
    fi
fi

# Method 2: Try sips with compositing
echo "Trying sips compositing method..."
sips -s format png "$ICON_PATH" --out "$TEMP_ICON" &> /dev/null
if [ $? -eq 0 ]; then
    # Create white background and composite
    sips -s format png -z 1024 1024 --setProperty formatOptions normal "$TEMP_ICON" --out "$ICON_PATH" &> /dev/null
    echo "⚠️  Partial fix applied. Please verify the icon manually."
    file "$ICON_PATH"
    exit 0
fi

echo ""
echo "❌ Automatic fix failed. Please fix manually:"
echo ""
echo "MANUAL FIX INSTRUCTIONS:"
echo "1. Open the icon in Preview:"
echo "   open $ICON_PATH"
echo ""
echo "2. In Preview:"
echo "   - File → Export"
echo "   - Format: PNG"
echo "   - UNCHECK 'Alpha' checkbox"
echo "   - Save over the original file"
echo ""
echo "3. Verify:"
echo "   file $ICON_PATH"
echo "   Should show: PNG image data, 1024 x 1024, 8-bit/color RGB (NOT RGBA)"
echo ""
exit 1

