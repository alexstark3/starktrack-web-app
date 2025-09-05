#!/bin/bash

# Build script for Stark Track Marketing Site
echo "Building Stark Track Marketing Site..."

# Clean previous build
echo "Cleaning previous build..."
rm -rf build/marketing

# Build Flutter web app with marketing main
echo "Building Flutter web app..."
flutter build web --target lib/marketing_main.dart --web-renderer html --release

# Copy build output to marketing directory
echo "Copying build output..."
mkdir -p build/marketing
cp -r build/web/* build/marketing/

echo "Marketing site build complete!"
echo "Output directory: build/marketing"
echo ""
echo "To deploy:"
echo "firebase deploy --only hosting:marketing"
