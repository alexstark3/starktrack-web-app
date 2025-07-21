#!/bin/bash

# Simple Admin Deployment - Single Hosting Site
# This approach doesn't require multi-site hosting

echo "🚀 Deploying Simple Admin Setup"

# Step 1: Build the main web app
echo "📦 Building main web app..."
flutter build web --release --web-renderer html --output-dir build/web

# Check if build was successful
if [ $? -ne 0 ]; then
    echo "❌ Main build failed!"
    exit 1
fi

echo "✅ Main build completed successfully!"

# Step 2: Build the admin web app to a subdirectory
echo "📦 Building admin web app..."
flutter build web --release --web-renderer html --target lib/admin_main.dart --output-dir build/web/admin

# Check if build was successful
if [ $? -ne 0 ]; then
    echo "❌ Admin build failed!"
    exit 1
fi

echo "✅ Admin build completed successfully!"

# Step 3: Deploy to Firebase Hosting
echo "🌐 Deploying to Firebase Hosting..."
firebase deploy --only hosting

if [ $? -eq 0 ]; then
    echo "🎉 Deployment completed successfully!"
    echo ""
    echo "📋 Access URLs:"
    echo "Main App:     https://starktrack.ch"
    echo "Admin App:    https://starktrack.ch/admin"
    echo ""
    echo "🔧 Next Steps:"
    echo "1. Create admin users: dart run create_admin_user.dart"
    echo "2. Test admin access at: https://starktrack.ch/admin"
    echo ""
    echo "🔒 Security Features:"
    echo "- Only admin users can access /admin"
    echo "- Company users will be redirected to main app"
    echo "- Complete separation between admin and company data"
    echo ""
    echo "💰 Cost:"
    echo "- No Firebase upgrade required"
    echo "- Uses existing hosting plan"
    echo "- Same Firestore database"
else
    echo "❌ Deployment failed!"
    exit 1
fi 