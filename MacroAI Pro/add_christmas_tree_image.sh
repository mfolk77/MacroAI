#!/bin/bash

echo "🎄 Christmas Tree Image Setup Helper"
echo "====================================="

# Check if image exists in current directory
if [ -f "christmas_tree_with_sunglasses.png" ]; then
    echo "✅ Found christmas_tree_with_sunglasses.png"
    cp "christmas_tree_with_sunglasses.png" "MacroAI Pro/Assets.xcassets/christmas_tree_with_sunglasses.imageset/"
    echo "✅ Copied to assets folder"
elif [ -f "christmas_tree_with_sunglasses.jpg" ]; then
    echo "✅ Found christmas_tree_with_sunglasses.jpg"
    cp "christmas_tree_with_sunglasses.jpg" "MacroAI Pro/Assets.xcassets/christmas_tree_with_sunglasses.imageset/"
    echo "✅ Copied to assets folder"
else
    echo "❌ No christmas_tree_with_sunglasses image found in current directory"
    echo ""
    echo "📋 To add your image:"
    echo "1. Place your Christmas tree image in this directory"
    echo "2. Name it 'christmas_tree_with_sunglasses.png' or 'christmas_tree_with_sunglasses.jpg'"
    echo "3. Run this script again"
    echo ""
    echo "🔄 Or manually:"
    echo "- Drag your image into Xcode's Assets.xcassets"
    echo "- Name it 'christmas_tree_with_sunglasses'"
fi

echo ""
echo "🎯 Next steps:"
echo "1. Add the image to assets (see above)"
echo "2. Build the project to test"
echo "3. The animation will automatically use your image!" 