# Browser Login Data Persistence Guide

## Overview

The StarkTrack web app now includes browser login data persistence features that help users have a smoother login experience while maintaining security.

## Features

### 1. Remember Email Address
- **What it does**: Saves your email address in the browser's local storage
- **Security**: Only the email is saved, never the password
- **Control**: You can enable/disable this feature with a "Remember my email" checkbox
- **Privacy**: Data is stored locally in your browser, not on our servers

### 2. Browser Password Manager Support
- **Automatic detection**: The login form is properly configured for browser password managers
- **Auto-fill**: Your browser can automatically fill in both email and password fields
- **Save prompts**: Browser will offer to save your login credentials
- **Cross-device sync**: If you use browser sync, credentials can be available on other devices

### 3. Separate Storage for Different User Types
- **Regular users**: Email saved separately from admin users
- **Super admins**: Separate storage to avoid conflicts
- **Independent settings**: Each user type can have different "remember me" preferences

## How to Use

### For Regular Users
1. Go to the main login page at `https://starktrack.ch`
2. Enter your email and password
3. Check the "Remember my email" checkbox if you want the email saved
4. Click "Login"
5. Next time you visit, your email will be pre-filled (if enabled)

### For Super Admins
1. Go to the admin login page at `https://admin.starktrack.ch`
2. Enter your admin email and password
3. Check the "Remember my email" checkbox if you want the email saved
4. Click "Login"
5. Next time you visit, your admin email will be pre-filled (if enabled)

## Security Features

### What is Saved
- ✅ Email address (only if "Remember me" is checked)
- ✅ "Remember me" preference
- ❌ Passwords (never saved locally)

### What is NOT Saved
- ❌ Passwords
- ❌ Session tokens
- ❌ Personal data beyond email
- ❌ Login history

### Data Storage
- **Location**: Browser's local storage (SharedPreferences)
- **Scope**: Only accessible by the same domain
- **Persistence**: Survives browser restarts
- **Clearance**: Removed when browser data is cleared

## Browser Compatibility

### Supported Browsers
- ✅ Chrome/Chromium
- ✅ Firefox
- ✅ Safari
- ✅ Edge
- ✅ Opera

### Password Manager Support
- ✅ Chrome Password Manager
- ✅ Firefox Lockwise
- ✅ Safari Keychain
- ✅ 1Password
- ✅ LastPass
- ✅ Bitwarden
- ✅ Other password managers

## Troubleshooting

### Email Not Being Remembered
1. Make sure you checked "Remember my email" before logging in
2. Check if your browser allows local storage
3. Try clearing browser data and logging in again

### Password Manager Not Working
1. Ensure you're using a supported browser
2. Check if your password manager is enabled
3. Try manually saving the password through your password manager
4. Check browser settings for autofill permissions

### Clearing Saved Data
To clear all saved login data:
1. Clear your browser's local storage for the domain
2. Or use the browser's "Clear browsing data" feature
3. Or contact support for assistance

## Privacy and Data Protection

### Data Usage
- Saved data is only used for login convenience
- No data is sent to external services
- No tracking or analytics on saved data

### GDPR Compliance
- Data is stored locally on your device
- You have full control over saved data
- You can clear data at any time
- No personal data is processed on our servers

## Technical Details

### Storage Keys
- Regular users: `remember_me`, `saved_email`
- Super admins: `super_admin_remember_me`, `super_admin_saved_email`

### Implementation
- Uses Flutter's `shared_preferences` package
- Implements proper autofill hints for browser compatibility
- Includes error handling and fallbacks
- Follows Flutter web best practices

## Support

If you experience issues with browser persistence:
1. Check this guide for common solutions
2. Try clearing browser data and logging in again
3. Contact support with specific error details
4. Include your browser type and version in support requests 