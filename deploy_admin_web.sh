#!/bin/bash

# Deploy Admin Web App to Firebase Default Domain
# This script builds and deploys the admin-only web app

echo "🚀 Deploying Admin Web App..."

# Build the admin web app
echo "📦 Building admin web app..."
flutter build web --release --web-renderer html

# Check if build was successful
if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo "✅ Build completed successfully!"

# Deploy to Firebase Hosting
echo "🌐 Deploying to Firebase Hosting..."
firebase deploy --only hosting

if [ $? -eq 0 ]; then
    echo "🎉 Admin web app deployed successfully!"
    echo ""
    echo "📋 Next steps:"
    echo "1. Create admin users using: dart run create_admin_user.dart"
    echo "2. Access admin panel at: https://starktracklog.web.app"
    echo "3. Main app remains at: https://starktrack.ch"
    echo ""
    echo "🔒 Security:"
    echo "- Only admin users can access the admin domain"
    echo "- Company users will be redirected to main app"
    echo "- Complete separation between admin and company data"
else
    echo "❌ Deployment failed!"
    exit 1
fi 