# Firebase Setup Guide for MYQuitMate

This guide will walk you through setting up Firebase for your Flutter app.

## Prerequisites

- Flutter installed (you have this already)
- A Google account
- Firebase CLI installed (optional but recommended)

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name: `myquitmate` (or your preferred name)
4. Disable Google Analytics for this POC (optional)
5. Click "Create project"

## Step 2: Install Firebase CLI (Recommended)

Install FlutterFire CLI to automatically configure Firebase:

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Install FlutterFire CLI
dart pub global activate flutterfire_cli
```

## Step 3: Automatic Configuration (Recommended)

Run this command in your project root:

```bash
flutterfire configure
```

This will:
- Select your Firebase project
- Register your app for iOS, Android, Web, macOS
- Generate `lib/firebase_options.dart` with all configuration
- Update platform-specific files automatically

**This is the easiest way!** The FlutterFire CLI will replace the placeholder `firebase_options.dart` file.

## Step 4: Enable Authentication

1. In Firebase Console, go to "Authentication"
2. Click "Get started"
3. Go to "Sign-in method" tab
4. Enable "Email/Password" provider
5. Click "Save"

## Step 5: Create Firestore Database

1. In Firebase Console, go to "Firestore Database"
2. Click "Create database"
3. Select "Start in test mode" (for development)
4. Choose a location (closest to your users)
5. Click "Enable"

**Important:** Test mode allows all reads/writes. For production, update security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;

      // Subcollections (moodLogs, badges)
      match /{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

## Step 6: Install Dependencies

Run in your project root:

```bash
flutter pub get
```

## Step 7: Platform-Specific Setup

### iOS (if targeting iOS)

No additional setup needed if you used `flutterfire configure`!

If doing manual setup, add this to `ios/Runner/Info.plist`:
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>YOUR_BUNDLE_ID</string>
    </array>
  </dict>
</array>
```

### Android (if targeting Android)

No additional setup needed if you used `flutterfire configure`!

### Web (if targeting Web)

No additional setup needed if you used `flutterfire configure`!

## Step 8: Test the App

Run your app:

```bash
flutter run
```

You should see:
1. Login screen on first launch
2. Ability to create account with email/password
3. Automatic login on subsequent launches
4. Dashboard after successful login
5. Logout button in dashboard

## Manual Configuration (Alternative)

If you prefer manual setup without FlutterFire CLI:

1. In Firebase Console, add your app (iOS/Android/Web)
2. Download configuration files:
   - iOS: `GoogleService-Info.plist` → `ios/Runner/`
   - Android: `google-services.json` → `android/app/`
   - Web: Copy config to `web/index.html`
3. Update `lib/firebase_options.dart` with your project's configuration values

## Troubleshooting

### "No Firebase App '[DEFAULT]' has been created"
- Make sure `Firebase.initializeApp()` is called in `main()`
- Check that `firebase_options.dart` has correct configuration

### "firebase_core plugin not found"
- Run `flutter clean && flutter pub get`
- Restart your IDE

### Authentication not working
- Check that Email/Password provider is enabled in Firebase Console
- Verify app is connected to correct Firebase project

### Firestore permission denied
- Check Firestore security rules
- Make sure user is authenticated before accessing Firestore

## What's Integrated

### Authentication ([auth_service.dart](lib/services/auth_service.dart))
- Email/Password sign up
- Email/Password login
- Sign out
- Password reset
- Auth state tracking

### Firestore ([firestore_service.dart](lib/services/firestore_service.dart))
- User profile management
- Quit plan data storage
- Mood logs
- Badge tracking
- Real-time updates

### UI
- [Login Screen](lib/screens/login_screen.dart) - Sign up/Login
- [Dashboard](lib/screens/dashboard_screen.dart) - Protected route with logout
- Auth state management in [main.dart](lib/main.dart)

## Next Steps

1. **Test locally** - Create an account and test the flow
2. **Add more fields** - Customize user profile data
3. **Production rules** - Update Firestore security rules before launch
4. **Analytics** (optional) - Enable Firebase Analytics for insights
5. **Crashlytics** (optional) - Add crash reporting

## Free Tier Limits (Should be fine for POC)

- **Authentication**: 50,000 monthly active users
- **Firestore**:
  - 1 GB storage
  - 10 GB/month network egress
  - 50k reads/day
  - 20k writes/day
  - 20k deletes/day

For a low-user POC, you'll be well within these limits!

## Support

If you encounter issues:
1. Check [FlutterFire documentation](https://firebase.flutter.dev/)
2. Review [Firebase Console](https://console.firebase.google.com/) for errors
3. Check Flutter logs: `flutter logs`
