#!/bin/bash
#./scripts/deploy_super_admin.sh
echo "🏗️  Building super admin web app..."
flutter build web --release --target=lib/super_admin/main.dart --output-dir build/admin

if [ $? -ne 0 ]; then
    echo "❌ Super admin build failed!"
    exit 1
fi

echo "✅ Super admin build completed successfully!"

echo "🚀 Deploying super admin app to Firebase Hosting (subdomain)..."
firebase deploy --only hosting:admin --project starktracklog

if [ $? -eq 0 ]; then
    echo "🎉 Super admin app deployed successfully!"
    echo ""
    echo "🌐 Access it at: https://admin-starktracklog.web.app"
    echo "   (or your custom subdomain, e.g., https://admin.starktrack.ch)"
else
    echo "❌ Deployment failed!"
    exit 1
fi