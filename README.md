# StarkTrack

A Flutter-based time tracking and project management application. ✅

## 🚨 SECURITY NOTICE

**IMPORTANT**: This project has been updated to use environment variables for Firebase configuration. The previous hardcoded API keys have been removed for security.

### Setup Instructions

1. **Copy the environment template:**
   ```bash
   cp env.template .env
   ```

2. **Fill in your Firebase credentials in `.env`:**
   - Get your API keys from [Firebase Console](https://console.firebase.google.com/)
   - Replace the placeholder values in `.env` with your actual keys

3. **Run the app with environment variables:**
   ```bash
   flutter run --dart-define-from-file=.env
   ```

### Firebase Configuration

The app uses Firebase for:
- Authentication
- Firestore database
- Real-time data synchronization

### Development

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
