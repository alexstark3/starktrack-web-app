@echo off
echo 🚀 Setting up Super Admin Subdomain: admin.starktrack.ch

REM Step 1: Build the super admin web app
echo 📦 Building super admin web app...
flutter build web --release --target lib/super_admin/main.dart --output-dir build/admin

REM Check if build was successful
if %errorlevel% neq 0 (
    echo ❌ Super admin build failed!
    pause
    exit /b 1
)

echo ✅ Super admin build completed successfully!

REM Step 2: Build the main web app (if needed)
echo 📦 Building main web app...
flutter build web --release --output-dir build/web

REM Check if build was successful
if %errorlevel% neq 0 (
    echo ❌ Main build failed!
    pause
    exit /b 1
)

echo ✅ Main build completed successfully!

REM Step 3: Deploy to Firebase Hosting
echo 🌐 Deploying to Firebase Hosting...
firebase deploy --only hosting

if %errorlevel% equ 0 (
    echo 🎉 Deployment completed successfully!
    echo.
    echo 📋 Domain Setup:
    echo Main App:     https://starktrack.ch
    echo Super Admin:  https://admin-starktracklog.web.app (temporary)
    echo Super Admin:  https://admin.starktrack.ch (once DNS propagates)
    echo.
    echo 🔧 Next Steps:
    echo 1. Test super admin access at: https://admin-starktracklog.web.app
    echo 2. Create super admin users: dart run create_admin_user.dart
    echo 3. Wait for DNS propagation (admin.starktrack.ch)
    echo.
    echo 🔒 Security Features:
    echo - Only super admin users can access admin interface
    echo - Company users will be redirected to main app
    echo - Complete separation between admin and company data
    echo.
    echo 📁 New Structure:
    echo lib/super_admin/ - All super admin functionality
    echo lib/super_admin/main.dart - Super admin entry point
    echo lib/super_admin/screens/ - Super admin screens
    echo lib/super_admin/tools/ - Super admin tools
) else (
    echo ❌ Deployment failed!
    pause
    exit /b 1
)

pause 