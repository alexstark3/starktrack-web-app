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

# Get current version from pubspec.yaml (for reference only)
MAIN_VERSION=$(grep 'version:' pubspec.yaml | cut -d' ' -f2 | cut -d'+' -f1)

if [ -z "$MAIN_VERSION" ]; then
    echo "❌ Error: Could not find version in pubspec.yaml"
    exit 1
fi

# Get commit count and start from 1 (no offset)
COMMIT_COUNT=$(git rev-list --count HEAD)
BUILD_NUMBER=$COMMIT_COUNT

# Create admin version (separate from main app version)
ADMIN_VERSION="${MAIN_VERSION}.${BUILD_NUMBER}"

echo "📦 Admin version will be: $ADMIN_VERSION"
echo "📦 Main app version remains: $MAIN_VERSION+$BUILD_NUMBER"
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

# Create a version file for the admin app
echo "📝 Creating admin version file..."
mkdir -p assets
cat > assets/admin_version.txt << EOF
Stark Track Super Admin
Version: $ADMIN_VERSION
Build: $BUILD_NUMBER
Deployed: $(date)
EOF

# Commit changes and push to GitHub
echo "📝 Committing changes..."
git add .
git commit -m "🚀 Update Super Admin version to $ADMIN_VERSION

- Super Admin version: $ADMIN_VERSION
- Main app version: $MAIN_VERSION+$BUILD_NUMBER
- Built super admin app
- Ready for deployment"

echo "📤 Pushing to GitHub..."
git push

if [ $? -ne 0 ]; then
    echo "⚠️  Warning: Git push failed. You may need to pull changes first."
    echo "   Run: git pull origin main"
    exit 1
fi

# Deploy to Firebase Hosting (admin only)
echo "🚀 Deploying Super Admin to Firebase Hosting..."
firebase deploy --only hosting:admin

if [ $? -eq 0 ]; then
    echo "🎉 Super Admin Deployment completed successfully!"
    echo ""
    echo "📋 Super Admin Domain:"
    echo "Super Admin:  https://admin-starktracklog.web.app (temporary)"
    echo "Super Admin:  https://admin.starktrack.ch (once DNS propagates)"
    echo ""
    echo "📦 Versions:"
    echo "Super Admin: $ADMIN_VERSION"
    echo "Main App: $MAIN_VERSION+$BUILD_NUMBER"
    echo ""
    echo "🔧 Next Steps:"
    echo "1. Test super admin access at: https://admin-starktracklog.web.app"
    echo "2. Wait for DNS propagation (admin.starktrack.ch)"
    echo ""
    echo "🔒 Security Features:"
    echo "- Only super admin users can access admin interface"
    echo "- Complete separation between admin and company data"
else
    echo "❌ Deployment failed!"
    exit 1
fi