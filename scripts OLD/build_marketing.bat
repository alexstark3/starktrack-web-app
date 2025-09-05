@echo off
echo Building Stark Track Marketing Site...

REM Clean previous build
echo Cleaning previous build...
if exist build\marketing rmdir /s /q build\marketing

REM Build Flutter web app with marketing main
echo Building Flutter web app...
flutter build web --target lib/marketing_main.dart --web-renderer html --release

REM Copy build output to marketing directory
echo Copying build output...
mkdir build\marketing
xcopy build\web\* build\marketing\ /E /I /Y

echo Marketing site build complete!
echo Output directory: build\marketing
echo.
echo To deploy:
echo firebase deploy --only hosting:marketing
pause
