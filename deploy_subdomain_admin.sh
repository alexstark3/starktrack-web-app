#!/bin/bash

echo "🚀 Setting up Super Admin Subdomain: admin.starktrack.ch"

# Step 1: Build the super admin web app
echo "📦 Building super admin web app..."
flutter build web --release --target lib/super_admin/main.dart --output-dir build/admin

# Check if build was successful
if [ $? -ne 0 ]; then
    echo "❌ Super admin build failed!"
    exit 1
fi

echo "✅ Super admin build completed successfully!"

# Step 2: Build the main web app (if needed)
echo "📦 Building main web app..."
flutter build web --release --output-dir build/web

# Check if build was successful
if [ $? -ne 0 ]; then
    echo "❌ Main build failed!"
    exit 1
fi

echo "✅ Main build completed successfully!"

# Step 3: Deploy to Firebase Hosting
echo "🌐 Deploying to Firebase Hosting..."
firebase deploy --only hosting

if [ $? -eq 0 ]; then
    echo "🎉 Deployment completed successfully!"
    echo ""
    echo "📋 Domain Setup:"
    echo "Main App:     https://starktrack.ch"
    echo "Super Admin:  https://admin-starktracklog.web.app (temporary)"
    echo "Super Admin:  https://admin.starktrack.ch (once DNS propagates)"
    echo ""
    echo "🔧 Next Steps:"
    echo "1. Test super admin access at: https://admin-starktracklog.web.app"
    echo "2. Create super admin users: dart run create_admin_user.dart"
    echo "3. Wait for DNS propagation (admin.starktrack.ch)"
    echo ""
    echo "🔒 Security Features:"
    echo "- Only super admin users can access admin interface"
    echo "- Company users will be redirected to main app"
    echo "- Complete separation between admin and company data"
    echo ""
    echo "📁 New Structure:"
    echo "lib/super_admin/ - All super admin functionality"
    echo "lib/super_admin/main.dart - Super admin entry point"
    echo "lib/super_admin/screens/ - Super admin screens"
    echo "lib/super_admin/tools/ - Super admin tools"
else
    echo "❌ Deployment failed!"
    exit 1
fi 