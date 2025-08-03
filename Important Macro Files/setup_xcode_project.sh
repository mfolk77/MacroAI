#!/bin/bash

# SerenaLite Xcode Project Setup Script
# This script helps you set up the Xcode project once you've created it manually

echo "🚀 SerenaLite Xcode Project Setup"
echo "=================================="

# Check if user provides project path
if [ $# -eq 0 ]; then
    echo "Usage: $0 <path_to_xcode_project_directory>"
    echo ""
    echo "Example: $0 ~/Desktop/SerenaLite"
    echo ""
    echo "Steps to follow:"
    echo "1. Create new iOS project in Xcode with these settings:"
    echo "   - Product Name: SerenaLite"
    echo "   - Bundle Identifier: com.folktech.serenalite"
    echo "   - Language: Swift"
    echo "   - Interface: SwiftUI"
    echo "   - Minimum Deployment: iOS 17.0"
    echo ""
    echo "2. Run this script with the project path"
    echo "3. Add files to Xcode target manually"
    exit 1
fi

XCODE_PROJECT_DIR="$1"
SOURCE_DIR="/Volumes/Folk_DAS/Apps/MarcoAI/SerenaLiteApp/SerenaLite"

# Verify source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "❌ Source directory not found: $SOURCE_DIR"
    exit 1
fi

# Verify target directory exists
if [ ! -d "$XCODE_PROJECT_DIR" ]; then
    echo "❌ Xcode project directory not found: $XCODE_PROJECT_DIR"
    echo "💡 Make sure you've created the Xcode project first"
    exit 1
fi

# Find the main app directory in the Xcode project
APP_DIR=$(find "$XCODE_PROJECT_DIR" -name "*.swift" -exec dirname {} \; | head -1)
if [ -z "$APP_DIR" ]; then
    echo "❌ Could not find Swift files in Xcode project"
    echo "💡 Make sure the Xcode project was created properly"
    exit 1
fi

echo "📁 Source: $SOURCE_DIR"
echo "📁 Target: $APP_DIR"
echo ""

# Backup original files
echo "💾 Creating backup of original files..."
mkdir -p "$APP_DIR/Original_Backup"
cp "$APP_DIR"/*.swift "$APP_DIR/Original_Backup/" 2>/dev/null

# Copy main app file
echo "📝 Copying SerenaLiteApp.swift..."
cp "$SOURCE_DIR/SerenaLiteApp.swift" "$APP_DIR/"

# Create directories and copy files
echo "📁 Creating directory structure..."
mkdir -p "$APP_DIR/Views"
mkdir -p "$APP_DIR/Models"
mkdir -p "$APP_DIR/Managers"

echo "📝 Copying Views..."
cp "$SOURCE_DIR/Views/"*.swift "$APP_DIR/Views/"

echo "📝 Copying Models..."
cp "$SOURCE_DIR/Models/"*.swift "$APP_DIR/Models/"

echo "📝 Copying Managers..."
cp "$SOURCE_DIR/Managers/"*.swift "$APP_DIR/Managers/"

# Copy assets if they exist
if [ -d "$SOURCE_DIR/Assets.xcassets" ]; then
    echo "🎨 Copying Assets..."
    cp -r "$SOURCE_DIR/Assets.xcassets/"* "$APP_DIR/Assets.xcassets/" 2>/dev/null
fi

echo ""
echo "✅ Files copied successfully!"
echo ""
echo "🔧 Manual steps in Xcode:"
echo "1. Add all Swift files to your target:"
echo "   - Select files in Project Navigator"
echo "   - Check 'Target Membership' in File Inspector"
echo "   - Ensure SerenaLite target is checked"
echo ""
echo "2. Verify build settings:"
echo "   - iOS Deployment Target: 17.0"
echo "   - Bundle Identifier: com.folktech.serenalite"
echo ""
echo "3. Add required capabilities:"
echo "   - In-App Purchase"
echo "   - StoreKit Configuration (for testing)"
echo ""
echo "4. Test the app:"
echo "   - Build and run in simulator"
echo "   - Check Settings → Developer Mode"
echo "   - Verify premium features are unlocked"
echo ""
echo "🔑 Developer backdoor code: SERENA_DEV_2024"
echo "📚 See README_SerenaLite_Setup.md for detailed instructions"