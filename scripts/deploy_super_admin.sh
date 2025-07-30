#!/bin/bash
echo "🚀 Starting Super Admin version update and deployment..."

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

# Get commit count and start from 1 (no offset)
COMMIT_COUNT=$(git rev-list --count HEAD)
BUILD_NUMBER=$COMMIT_COUNT

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
echo "   (Commit count: $COMMIT_COUNT)"

# Get Flutter dependencies
echo "📥 Getting Flutter dependencies..."
flutter pub get

# Build super admin web app
echo "🏗️  Building super admin web app..."
flutter build web --release --target lib/super_admin/main.dart --output-dir build/admin

# Check if build was successful
if [ $? -ne 0 ]; then
    echo "❌ Super admin build failed!"
    exit 1
fi

echo "✅ Super admin build completed successfully!"

# Build main web app (if needed)
echo "🏗️  Building main web app..."
flutter build web --release --output-dir build/web

# Check if build was successful
if [ $? -ne 0 ]; then
    echo "❌ Main build failed!"
    exit 1
fi

echo "✅ Main build completed successfully!"

# Commit changes and push to GitHub
echo "📝 Committing changes..."
git add .
git commit -m "🚀 Update version to $VERSION+$BUILD_NUMBER

- Updated build number to $BUILD_NUMBER
- Built super admin and main apps
- Ready for deployment"

echo "📤 Pushing to GitHub..."
git push

if [ $? -ne 0 ]; then
    echo "⚠️  Warning: Git push failed. You may need to pull changes first."
    echo "   Run: git pull origin main"
    exit 1
fi

# Deploy to Firebase Hosting
echo "🚀 Deploying to Firebase Hosting..."
firebase deploy --only hosting

if [ $? -eq 0 ]; then
    echo "🎉 Deployment completed successfully!"
    echo ""
    echo "📋 Domain Setup:"
    echo "Main App:     https://starktrack.ch"
    echo "Super Admin:  https://admin-starktracklog.web.app (temporary)"
    echo "Super Admin:  https://admin.starktrack.ch (once DNS propagates)"
    echo ""
    echo "📦 Version: $VERSION+$BUILD_NUMBER"
    echo ""
    echo "🔧 Next Steps:"
    echo "1. Test super admin access at: https://admin-starktracklog.web.app"
    echo "2. Wait for DNS propagation (admin.starktrack.ch)"
    echo ""
    echo "🔒 Security Features:"
    echo "- Only super admin users can access admin interface"
    echo "- Company users will be redirected to main app"
    echo "- Complete separation between admin and company data"
else
    echo "❌ Deployment failed!"
    exit 1
fi