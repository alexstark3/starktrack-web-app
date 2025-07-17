#!/bin/bash
echo "🚀 Starting deployment..."

# Get current version (without build number)
VERSION=$(grep 'version:' pubspec.yaml | cut -d' ' -f2 | cut -d'+' -f1)

# Get commit count and add offset to start from 521
COMMIT_COUNT=$(git rev-list --count HEAD)
BUILD_NUMBER=$((COMMIT_COUNT + 521))

# Update pubspec.yaml
sed -i.bak "s/version: .*/version: $VERSION+$BUILD_NUMBER/" pubspec.yaml

echo "📦 Updated version to: $VERSION+$BUILD_NUMBER"

# Build and deploy
flutter build web
firebase deploy

echo "✅ Deployment complete!"