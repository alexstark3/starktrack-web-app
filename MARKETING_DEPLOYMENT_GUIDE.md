# Stark Track Marketing Site Deployment Guide

## Overview
This guide explains how to deploy the Stark Track marketing site to `starktrack.ch` using Firebase Hosting.

## Prerequisites
- Firebase CLI installed and authenticated
- Domain `starktrack.ch` configured in your DNS
- Firebase project: `starktracklog`

## Configuration Summary

### Firebase Configuration (`firebase.json`)
- **Marketing Target**: `marketing` → serves from `build/marketing`
- **App Target**: `main` → serves from `build/web` (existing app)
- **Admin Target**: `admin` → serves from `build/admin` (existing admin)

### Marketing Site Structure
- **Entry Point**: `lib/marketing_main.dart`
- **Build Output**: `build/marketing/`
- **Content**: Landing page, About Us, Contact form

## Deployment Steps

### 1. Build the Marketing Site

**Windows:**
```bash
scripts\build_marketing.bat
```

**Linux/Mac:**
```bash
chmod +x scripts/build_marketing.sh
./scripts/build_marketing.sh
```

### 2. Deploy to Firebase

```bash
# Deploy only the marketing site
firebase deploy --only hosting:marketing
```

### 3. Configure Custom Domain

```bash
# Add custom domain to Firebase
firebase hosting:sites:create starktrack-marketing

# Add the custom domain
firebase hosting:channel:deploy live --only starktrack-marketing
```

### 4. DNS Configuration

Configure your DNS provider to point `starktrack.ch` to Firebase:

**A Records:**
```
starktrack.ch → 199.36.158.100
www.starktrack.ch → 199.36.158.100
```

**Or CNAME (if supported):**
```
starktrack.ch → starktrack-marketing.web.app
www.starktrack.ch → starktrack-marketing.web.app
```

## Domain Strategy

### Current Setup:
- **`starktrack.ch`** → Marketing site (landing page, about, contact)
- **`starktracklog.web.app`** → Main app (login, dashboard)
- **`starktracklog.firebaseapp.com`** → Redirect to main domain

### User Flow:
1. **Marketing**: Users visit `starktrack.ch` for information
2. **Login**: "Login" button redirects to `starktracklog.web.app`
3. **App**: Users access the full application

## Build Commands

### Marketing Site Only:
```bash
flutter build web --target lib/marketing_main.dart --web-renderer html --release
```

### Main App (existing):
```bash
flutter build web --web-renderer html --release
```

## Verification

After deployment, verify:
1. `starktrack.ch` shows the marketing landing page
2. "Login" button redirects to app domain
3. All pages (About, Contact) work correctly
4. Language switching works
5. Contact form submits successfully

## Troubleshooting

### Build Issues:
- Ensure Flutter is up to date
- Clear build cache: `flutter clean`
- Rebuild: `flutter pub get`

### Deployment Issues:
- Check Firebase authentication: `firebase login`
- Verify project: `firebase use starktracklog`
- Check hosting configuration: `firebase hosting:sites:list`

### DNS Issues:
- DNS propagation can take 24-48 hours
- Use `nslookup starktrack.ch` to verify DNS
- Check Firebase hosting domains: `firebase hosting:sites:list`

## Next Steps

1. **Deploy marketing site** to `starktrack.ch`
2. **Configure login redirects** to point to app domain
3. **Set up analytics** for marketing site
4. **Optimize SEO** for marketing pages
5. **Monitor performance** and user flows
