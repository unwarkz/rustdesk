#!/bin/bash
# FixIT Connect Icon Generation Script
# Generates all required icon sizes for all platforms from source SVG/PNG files

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}FixIT Connect Icon Generation Script${NC}"
echo -e "${GREEN}========================================${NC}"

# Source files
ICON_SVG="res/scalable.svg"
ICON_PNG="res/icon.png"

# Check if source files exist
if [ ! -f "$ICON_SVG" ]; then
    echo -e "${RED}Error: Source SVG file not found: $ICON_SVG${NC}"
    exit 1
fi

if [ ! -f "$ICON_PNG" ]; then
    echo -e "${RED}Error: Source PNG file not found: $ICON_PNG${NC}"
    exit 1
fi

# Check for required tools
check_tool() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}Error: $1 is not installed. Please install it first.${NC}"
        exit 1
    fi
}

echo -e "${YELLOW}Checking required tools...${NC}"
check_tool convert  # ImageMagick
if command -v inkscape &> /dev/null; then
    USE_INKSCAPE=true
    echo -e "${GREEN}Using inkscape for SVG conversion${NC}"
else
    USE_INKSCAPE=false
    echo -e "${YELLOW}Warning: inkscape not found, using ImageMagick for SVG (may have lower quality)${NC}"
fi

# Function to generate icon from SVG or PNG
generate_icon() {
    local size=$1
    local output=$2
    local use_svg=${3:-true}
    
    if [ "$use_svg" = true ] && [ "$USE_INKSCAPE" = true ]; then
        inkscape -w $size -h $size "$ICON_SVG" -o "$output" 2>/dev/null
    else
        convert "$ICON_PNG" -resize ${size}x${size} "$output"
    fi
    
    if [ -f "$output" ]; then
        echo -e "${GREEN}  ✓ Generated: $output (${size}x${size})${NC}"
    else
        echo -e "${RED}  ✗ Failed: $output${NC}"
        return 1
    fi
}

# ==========================================
# Windows Icons (.ico)
# ==========================================
echo -e "\n${YELLOW}Generating Windows icons...${NC}"

# Generate individual sizes for Windows
TMP_DIR=$(mktemp -d)
WIN_SIZES=(16 32 48 64 128 256)

for size in "${WIN_SIZES[@]}"; do
    generate_icon $size "$TMP_DIR/win_${size}.png" true
done

# Create .ico file with multiple sizes
convert "$TMP_DIR"/win_*.png -colors 256 "res/icon.ico"
echo -e "${GREEN}  ✓ Created Windows icon: res/icon.ico${NC}"

# Tray icon (smaller sizes)
convert "$TMP_DIR/win_16.png" "$TMP_DIR/win_32.png" "$TMP_DIR/win_48.png" -colors 256 "res/tray-icon.ico"
echo -e "${GREEN}  ✓ Created Windows tray icon: res/tray-icon.ico${NC}"

# ==========================================
# Linux Icons (.desktop integration)
# ==========================================
echo -e "\n${YELLOW}Generating Linux icons...${NC}"

LINUX_SIZES=(16 24 32 48 64 96 128 192 256 512)

for size in "${LINUX_SIZES[@]}"; do
    generate_icon $size "res/${size}x${size}.png" true
done

# Copy scalable SVG
if [ "$ICON_SVG" != "res/scalable.svg" ]; then
    cp "$ICON_SVG" "res/scalable.svg"
    echo -e "${GREEN}  ✓ Copied scalable SVG: res/scalable.svg${NC}"
else
    echo -e "${GREEN}  ✓ Scalable SVG already in place: res/scalable.svg${NC}"
fi

# Generate @2x variants for high DPI
generate_icon 256 "res/128x128@2x.png" true

# ==========================================
# Android Icons (mipmap)
# ==========================================
echo -e "\n${YELLOW}Generating Android icons...${NC}"

ANDROID_BASE_DIR="flutter/android/app/src/main/res"

# Android density buckets
# mdpi: 48x48, hdpi: 72x72, xhdpi: 96x96, xxhdpi: 144x144, xxxhdpi: 192x192
declare -A ANDROID_SIZES=(
    ["mdpi"]=48
    ["hdpi"]=72
    ["xhdpi"]=96
    ["xxhdpi"]=144
    ["xxxhdpi"]=192
)

for density in "${!ANDROID_SIZES[@]}"; do
    size=${ANDROID_SIZES[$density]}
    output_dir="$ANDROID_BASE_DIR/mipmap-$density"
    mkdir -p "$output_dir"
    generate_icon $size "$output_dir/ic_launcher.png" true
done

# Also copy to drawable for legacy support
mkdir -p "$ANDROID_BASE_DIR/drawable"
generate_icon 96 "$ANDROID_BASE_DIR/drawable/ic_launcher.png" true

# ==========================================
# iOS Icons (Assets.xcassets)
# ==========================================
echo -e "\n${YELLOW}Generating iOS icons...${NC}"

IOS_ICON_DIR="flutter/ios/Runner/Assets.xcassets/AppIcon.appiconset"
mkdir -p "$IOS_ICON_DIR"

# iOS icon sizes (for iOS 7.0+)
# Reference: https://developer.apple.com/design/human-interface-guidelines/ios/icons-and-images/app-icon/
declare -A IOS_SIZES=(
    ["Icon-App-20x20@1x"]=20
    ["Icon-App-20x20@2x"]=40
    ["Icon-App-20x20@3x"]=60
    ["Icon-App-29x29@1x"]=29
    ["Icon-App-29x29@2x"]=58
    ["Icon-App-29x29@3x"]=87
    ["Icon-App-40x40@1x"]=40
    ["Icon-App-40x40@2x"]=80
    ["Icon-App-40x40@3x"]=120
    ["Icon-App-60x60@2x"]=120
    ["Icon-App-60x60@3x"]=180
    ["Icon-App-76x76@1x"]=76
    ["Icon-App-76x76@2x"]=152
    ["Icon-App-83.5x83.5@2x"]=167
    ["Icon-App-1024x1024@1x"]=1024
)

for name in "${!IOS_SIZES[@]}"; do
    size=${IOS_SIZES[$name]}
    generate_icon $size "$IOS_ICON_DIR/${name}.png" true
done

# Create Contents.json for iOS
cat > "$IOS_ICON_DIR/Contents.json" << 'EOF'
{
  "images" : [
    {
      "size" : "20x20",
      "idiom" : "iphone",
      "filename" : "Icon-App-20x20@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "20x20",
      "idiom" : "iphone",
      "filename" : "Icon-App-20x20@3x.png",
      "scale" : "3x"
    },
    {
      "size" : "29x29",
      "idiom" : "iphone",
      "filename" : "Icon-App-29x29@1x.png",
      "scale" : "1x"
    },
    {
      "size" : "29x29",
      "idiom" : "iphone",
      "filename" : "Icon-App-29x29@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "29x29",
      "idiom" : "iphone",
      "filename" : "Icon-App-29x29@3x.png",
      "scale" : "3x"
    },
    {
      "size" : "40x40",
      "idiom" : "iphone",
      "filename" : "Icon-App-40x40@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "40x40",
      "idiom" : "iphone",
      "filename" : "Icon-App-40x40@3x.png",
      "scale" : "3x"
    },
    {
      "size" : "60x60",
      "idiom" : "iphone",
      "filename" : "Icon-App-60x60@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "60x60",
      "idiom" : "iphone",
      "filename" : "Icon-App-60x60@3x.png",
      "scale" : "3x"
    },
    {
      "size" : "20x20",
      "idiom" : "ipad",
      "filename" : "Icon-App-20x20@1x.png",
      "scale" : "1x"
    },
    {
      "size" : "20x20",
      "idiom" : "ipad",
      "filename" : "Icon-App-20x20@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "29x29",
      "idiom" : "ipad",
      "filename" : "Icon-App-29x29@1x.png",
      "scale" : "1x"
    },
    {
      "size" : "29x29",
      "idiom" : "ipad",
      "filename" : "Icon-App-29x29@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "40x40",
      "idiom" : "ipad",
      "filename" : "Icon-App-40x40@1x.png",
      "scale" : "1x"
    },
    {
      "size" : "40x40",
      "idiom" : "ipad",
      "filename" : "Icon-App-40x40@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "76x76",
      "idiom" : "ipad",
      "filename" : "Icon-App-76x76@1x.png",
      "scale" : "1x"
    },
    {
      "size" : "76x76",
      "idiom" : "ipad",
      "filename" : "Icon-App-76x76@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "83.5x83.5",
      "idiom" : "ipad",
      "filename" : "Icon-App-83.5x83.5@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "1024x1024",
      "idiom" : "ios-marketing",
      "filename" : "Icon-App-1024x1024@1x.png",
      "scale" : "1x"
    }
  ],
  "info" : {
    "version" : 1,
    "author" : "xcode"
  }
}
EOF

echo -e "${GREEN}  ✓ Created iOS Contents.json${NC}"

# ==========================================
# macOS Icons (Assets.xcassets)
# ==========================================
echo -e "\n${YELLOW}Generating macOS icons...${NC}"

MACOS_ICON_DIR="flutter/macos/Runner/Assets.xcassets/AppIcon.appiconset"
mkdir -p "$MACOS_ICON_DIR"

# macOS icon sizes
declare -A MACOS_SIZES=(
    ["app_icon_16"]=16
    ["app_icon_32"]=32
    ["app_icon_64"]=64
    ["app_icon_128"]=128
    ["app_icon_256"]=256
    ["app_icon_512"]=512
    ["app_icon_1024"]=1024
)

for name in "${!MACOS_SIZES[@]}"; do
    size=${MACOS_SIZES[$name]}
    generate_icon $size "$MACOS_ICON_DIR/${name}.png" true
done

# Create Contents.json for macOS
cat > "$MACOS_ICON_DIR/Contents.json" << 'EOF'
{
  "images" : [
    {
      "size" : "16x16",
      "idiom" : "mac",
      "filename" : "app_icon_16.png",
      "scale" : "1x"
    },
    {
      "size" : "16x16",
      "idiom" : "mac",
      "filename" : "app_icon_32.png",
      "scale" : "2x"
    },
    {
      "size" : "32x32",
      "idiom" : "mac",
      "filename" : "app_icon_32.png",
      "scale" : "1x"
    },
    {
      "size" : "32x32",
      "idiom" : "mac",
      "filename" : "app_icon_64.png",
      "scale" : "2x"
    },
    {
      "size" : "128x128",
      "idiom" : "mac",
      "filename" : "app_icon_128.png",
      "scale" : "1x"
    },
    {
      "size" : "128x128",
      "idiom" : "mac",
      "filename" : "app_icon_256.png",
      "scale" : "2x"
    },
    {
      "size" : "256x256",
      "idiom" : "mac",
      "filename" : "app_icon_256.png",
      "scale" : "1x"
    },
    {
      "size" : "256x256",
      "idiom" : "mac",
      "filename" : "app_icon_512.png",
      "scale" : "2x"
    },
    {
      "size" : "512x512",
      "idiom" : "mac",
      "filename" : "app_icon_512.png",
      "scale" : "1x"
    },
    {
      "size" : "512x512",
      "idiom" : "mac",
      "filename" : "app_icon_1024.png",
      "scale" : "2x"
    }
  ],
  "info" : {
    "version" : 1,
    "author" : "xcode"
  }
}
EOF

echo -e "${GREEN}  ✓ Created macOS Contents.json${NC}"

# Also copy mac-icon.png for legacy support
cp "$ICON_PNG" "res/mac-icon.png"
echo -e "${GREEN}  ✓ Copied macOS icon: res/mac-icon.png${NC}"

# Clean up temporary directory
rm -rf "$TMP_DIR"

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}Icon generation complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${YELLOW}Summary:${NC}"
echo -e "  • Windows: res/icon.ico, res/tray-icon.ico"
echo -e "  • Linux: res/XXxXX.png (multiple sizes), res/scalable.svg"
echo -e "  • Android: flutter/android/app/src/main/res/mipmap-*/ic_launcher.png"
echo -e "  • iOS: flutter/ios/Runner/Assets.xcassets/AppIcon.appiconset/"
echo -e "  • macOS: flutter/macos/Runner/Assets.xcassets/AppIcon.appiconset/"
echo ""
