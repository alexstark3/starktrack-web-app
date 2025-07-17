#!/bin/bash

echo "🚀 Starting deployment..."

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ Error: Not in a git repository"
    exit 1
fi

# Get current version (without build number)
VERSION=$(grep 'version:' pubspec.yaml | cut -d' ' -f2 | cut -d'+' -f1)

if [ -z "$VERSION" ]; then
    echo "❌ Error: Could not find version in pubspec.yaml"
    exit 1
fi

# Get commit count and add offset to start from 521
COMMIT_COUNT=$(git rev-list --count HEAD)
BUILD_NUMBER=$((COMMIT_COUNT + 521))

# Update pubspec.yaml
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s/version: .*/version: $VERSION+$BUILD_NUMBER/" pubspec.yaml
else
    # Linux/Windows (Git Bash)
    sed -i "s/version: .*/version: $VERSION+$BUILD_NUMBER/" pubspec.yaml
fi

echo "📦 Updated version to: $VERSION+$BUILD_NUMBER"
echo "   (Commit count: $COMMIT_COUNT + offset: 521)"

# Get Flutter dependencies
echo "📥 Getting Flutter dependencies..."
flutter pub get

# Build the web app
echo "🔨 Building web app..."
flutter build web

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

# Deploy to Firebase
echo "🚀 Deploying to Firebase..."
firebase deploy

if [ $? -ne 0 ]; then
    echo "❌ Firebase deployment failed!"
    exit 1
fi

echo "✅ Deployment complete!"
echo "🌐 Your app is live with version $VERSION+$BUILD_NUMBER"
