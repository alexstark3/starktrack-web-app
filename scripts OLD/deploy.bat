@echo off
echo 🚀 Starting version update and sync...

REM Check if we're in a git repository
git rev-parse --git-dir >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Error: Not in a git repository
    exit /b 1
)

REM Check if there are uncommitted changes
git status --porcelain | findstr /r "." >nul
if %errorlevel% equ 0 (
    echo ⚠️  Warning: There are uncommitted changes in your repository
    echo    The script will commit all changes with the version update
)

REM Get current version (without build number)
for /f "tokens=2 delims= " %%a in ('findstr "version:" pubspec.yaml') do set VERSION=%%a
for /f "tokens=1 delims=+" %%a in ("%VERSION%") do set VERSION=%%a

if "%VERSION%"=="" (
    echo ❌ Error: Could not find version in pubspec.yaml
    exit /b 1
)

REM Get commit count and add offset to start from 521
for /f %%a in ('git rev-list --count HEAD') do set COMMIT_COUNT=%%a
set /a BUILD_NUMBER=%COMMIT_COUNT% + 521

REM Update pubspec.yaml with new build number
echo 📦 Updating version in pubspec.yaml...
powershell -Command "(Get-Content pubspec.yaml) -replace 'version: .*', 'version: %VERSION%+%BUILD_NUMBER%' | Set-Content pubspec.yaml"

echo 📦 Updated version to: %VERSION%+%BUILD_NUMBER%
echo    (Commit count: %COMMIT_COUNT% + offset: 521)

REM Get Flutter dependencies
echo 📥 Getting Flutter dependencies...
flutter pub get

REM Commit changes and push to GitHub
echo 📝 Committing changes...
git add .
git commit -m "🚀 Update version to %VERSION%+%BUILD_NUMBER%

- Updated build number to %BUILD_NUMBER%
- Ready for deployment"

echo 📤 Pushing to GitHub...
git push

if %errorlevel% neq 0 (
    echo ⚠️  Warning: Git push failed. You may need to pull changes first.
    echo    Run: git pull origin main
    exit /b 1
)

echo ✅ Version update complete!
echo 📦 Version %VERSION%+%BUILD_NUMBER% committed and pushed to GitHub
echo 🚀 GitHub Actions will automatically build and deploy both apps
echo 📋 Check deployment status at: https://github.com/alexstark3/starktrack-web-app/actions
pause
