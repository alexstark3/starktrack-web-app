#!/bin/bash
#./scripts/firebase_deploy.sh
echo "🚀 Starting Firebase deployment..."

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ Error: Not in a git repository"
    exit 1
fi

# Get current version
VERSION=$(grep 'version:' pubspec.yaml | cut -d' ' -f2)

if [ -z "$VERSION" ]; then
    echo "❌ Error: Could not find version in pubspec.yaml"
    exit 1
fi

echo "📦 Deploying version: $VERSION"

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

echo "✅ Firebase deployment complete!"
echo "🌐 Your app is live with version $VERSION" 