#!/bin/bash
#h
echo "🚀 Starting version update and sync..."

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ Error: Not in a git repository"
    exit 1
fi

# Check if there are uncommitted changes
if [ -n "$(git status --porcelain)" ]; then
    echo "⚠️  Warning: There are uncommitted changes in your repository"
    echo "   The script will commit all changes with the version update"
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

# Update pubspec.yaml with new build number
echo "📦 Updating version in pubspec.yaml..."
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

# Commit changes and push to GitHub
echo "📝 Committing changes..."
git add .
git commit -m "🚀 Update version to $VERSION+$BUILD_NUMBER

- Updated build number to $BUILD_NUMBER
- Ready for deployment"

echo "📤 Pushing to GitHub..."
git push

if [ $? -ne 0 ]; then
    echo "⚠️  Warning: Git push failed. You may need to pull changes first."
    echo "   Run: git pull origin main"
    exit 1
fi

echo "✅ Version update complete!"
echo "📦 Version $VERSION+$BUILD_NUMBER committed and pushed to GitHub"
echo "🚀 GitHub Actions will automatically build and deploy both apps"
echo "📋 Check deployment status at: https://github.com/alexstark3/starktrack-web-app/actions"
