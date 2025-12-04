#!/bin/bash
# Generate multi-size ICO file from SVG or PNG source
# Supports inkscape, rsvg-convert, or ImageMagick convert as fallback

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Input file priority: logo.svg > icon.png
INPUT_FILE=""
if [ -f "logo.svg" ]; then
    INPUT_FILE="logo.svg"
elif [ -f "icon.png" ]; then
    INPUT_FILE="icon.png"
else
    echo "Error: Neither logo.svg nor icon.png found in $SCRIPT_DIR"
    exit 1
fi

echo "Using input file: $INPUT_FILE"

# Sizes for the ICO file (including 16x16 for window titlebar)
SIZES="16 32 48 64 128 256"
PNG_FILES=""

# Function to convert SVG to PNG using available tools
convert_svg_to_png() {
    local input=$1
    local size=$2
    local output=$3

    if command -v inkscape &> /dev/null; then
        # Inkscape (modern syntax)
        inkscape "$input" -w "$size" -h "$size" -o "$output" 2>/dev/null || \
        inkscape -z -e "$output" -w "$size" -h "$size" "$input" 2>/dev/null
    elif command -v rsvg-convert &> /dev/null; then
        # rsvg-convert from librsvg
        rsvg-convert -w "$size" -h "$size" "$input" -o "$output"
    elif command -v convert &> /dev/null; then
        # ImageMagick convert
        convert -background none -resize "${size}x${size}" "$input" "$output"
    elif command -v magick &> /dev/null; then
        # ImageMagick 7+ (magick command)
        magick convert -background none -resize "${size}x${size}" "$input" "$output"
    else
        echo "Error: No suitable converter found (inkscape, rsvg-convert, or ImageMagick)"
        exit 1
    fi
}

# Function to convert PNG to PNG (resize)
convert_png_to_png() {
    local input=$1
    local size=$2
    local output=$3

    if command -v convert &> /dev/null; then
        convert "$input" -resize "${size}x${size}" "$output"
    elif command -v magick &> /dev/null; then
        magick convert "$input" -resize "${size}x${size}" "$output"
    else
        echo "Error: ImageMagick not found for PNG resizing"
        exit 1
    fi
}

# Generate PNGs for each size
for size in $SIZES; do
    output_file="icon_${size}.png"
    echo "Generating ${size}x${size} PNG..."
    
    if [[ "$INPUT_FILE" == *.svg ]]; then
        convert_svg_to_png "$INPUT_FILE" "$size" "$output_file"
    else
        convert_png_to_png "$INPUT_FILE" "$size" "$output_file"
    fi
    
    PNG_FILES="$PNG_FILES $output_file"
done

# Create ICO file with all sizes
echo "Creating icon.ico..."
if command -v convert &> /dev/null; then
    convert $PNG_FILES icon.ico
elif command -v magick &> /dev/null; then
    magick convert $PNG_FILES icon.ico
else
    echo "Error: ImageMagick not found for ICO creation"
    exit 1
fi

# Copy ICO to flutter resources
FLUTTER_ICO_PATH="../flutter/windows/runner/resources/app_icon.ico"
if [ -d "$(dirname "$FLUTTER_ICO_PATH")" ]; then
    echo "Copying icon.ico to $FLUTTER_ICO_PATH"
    cp icon.ico "$FLUTTER_ICO_PATH"
else
    echo "Warning: Flutter resources directory not found, skipping copy"
fi

# Clean up temporary PNG files
echo "Cleaning up temporary files..."
for file in $PNG_FILES; do
    rm -f "$file"
done

echo "Done! icon.ico created successfully."
ls -la icon.ico
