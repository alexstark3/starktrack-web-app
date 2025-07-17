// lib/config/firebase_config.template.dart
// Copy this file to firebase_config.dart and add your actual API keys
// This template file is safe to commit to git

class FirebaseConfig {
  static const String apiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: 'YOUR_API_KEY_HERE',
  );
  
  static const String appId = String.fromEnvironment(
    'FIREBASE_APP_ID',
    defaultValue: 'YOUR_APP_ID_HERE',
  );
  
  static const String messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: 'YOUR_MESSAGING_SENDER_ID_HERE',
  );
  
  static const String projectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'YOUR_PROJECT_ID_HERE',
  );
  
  static const String authDomain = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
    defaultValue: 'YOUR_PROJECT_ID.firebaseapp.com',
  );
  
  static const String storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
    defaultValue: 'YOUR_PROJECT_ID.appspot.com',
  );
} 