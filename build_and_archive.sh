#!/bin/bash

# Build and Archive Script for Shoply v1.1.0+4

echo "🚀 Starting build process for Shoply..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
flutter pub get

# Build iOS release
echo "📱 Building iOS release..."
flutter build ios --release --no-codesign

# Create archive (requires Xcode)
echo "📦 Creating archive..."
echo "⚠️  Please complete the archive in Xcode:"
echo "   1. Open Xcode: open ios/Runner.xcworkspace"
echo "   2. Select 'Any iOS Device (arm64)'"
echo "   3. Product → Archive"
echo "   4. Follow the upload steps in Xcode Organizer"

echo "✅ Build preparation complete!"
