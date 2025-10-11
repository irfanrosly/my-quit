# Quick Firebase Setup - Step by Step

Follow these steps to get Firebase running in your app in ~10 minutes.

## Step 1: Create Firebase Project (3 minutes)

1. Open your browser and go to: https://console.firebase.google.com/
2. Click **"Add project"** or **"Create a project"**
3. Enter project name: `myquitmate` (or any name you want)
4. **Disable** Google Analytics (you can enable it later)
5. Click **"Create project"**
6. Wait for it to finish, then click **"Continue"**

## Step 2: Enable Authentication (2 minutes)

1. In your Firebase project, click **"Authentication"** in the left sidebar
2. Click **"Get started"**
3. Click on the **"Sign-in method"** tab
4. Click on **"Email/Password"**
5. **Toggle ON** the first switch (Email/Password)
6. Keep "Email link" OFF
7. Click **"Save"**

## Step 3: Create Firestore Database (2 minutes)

1. In the left sidebar, click **"Firestore Database"**
2. Click **"Create database"**
3. Select **"Start in test mode"** (for development)
4. Choose a location (select closest to you, e.g., `asia-southeast1`)
5. Click **"Enable"**
6. Wait for database to be created

## Step 4: Configure Your Flutter App (3 minutes)

Now we need to connect your app to Firebase. You have 2 options:

### Option A: Using FlutterFire CLI (Easiest - Recommended)

Run this command in your terminal (you may need to enter your password for sudo):

```bash
# Add flutterfire to PATH
export PATH="$PATH":"$HOME/.pub-cache/bin"

# Login to Firebase (opens browser)
firebase login

# Configure your Flutter app
flutterfire configure
```

**If `firebase login` fails**, install Firebase CLI first:
```bash
sudo npm install -g firebase-tools
```

Then when prompted:
- Select your Firebase project (`myquitmate`)
- Press **Space** to select platforms (iOS, Android, Web, macOS)
- Press **Enter** to confirm

This will automatically generate `lib/firebase_options.dart` with your configuration!

### Option B: Manual Configuration (If CLI doesn't work)

If the FlutterFire CLI doesn't work, follow these manual steps:

#### For Web (Quickest to test):

1. In Firebase Console, click the **⚙️ gear icon** → **Project settings**
2. Scroll down to **"Your apps"**
3. Click the **Web icon** `</>`
4. Enter app nickname: `MYQuitMate Web`
5. **Check** "Also set up Firebase Hosting"
6. Click **"Register app"**
7. Copy the `firebaseConfig` object
8. Open `lib/firebase_options.dart` in your project
9. Replace the `web` section with your values:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'YOUR_API_KEY',
  appId: 'YOUR_APP_ID',
  messagingSenderId: 'YOUR_SENDER_ID',
  projectId: 'YOUR_PROJECT_ID',
  authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',
  storageBucket: 'YOUR_PROJECT_ID.appspot.com',
);
```

#### For Android:

1. In Firebase Console, click **"Add app"** → Android icon
2. Android package name: `com.example.myquitmate` (or check `android/app/build.gradle`)
3. Click **"Register app"**
4. Download `google-services.json`
5. Move it to: `android/app/google-services.json`
6. Follow the setup instructions in Firebase Console

#### For iOS:

1. In Firebase Console, click **"Add app"** → iOS icon
2. iOS bundle ID: check `ios/Runner.xcodeproj/project.pbxproj` for `PRODUCT_BUNDLE_IDENTIFIER`
3. Click **"Register app"**
4. Download `GoogleService-Info.plist`
5. Move it to: `ios/Runner/GoogleService-Info.plist`
6. Follow the setup instructions in Firebase Console

## Step 5: Update Firestore Security Rules (1 minute)

1. In Firebase Console, go to **"Firestore Database"**
2. Click the **"Rules"** tab
3. Replace the content with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;

      // Subcollections
      match /{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

4. Click **"Publish"**

## Step 6: Run Your App

```bash
# For Web (easiest to test)
flutter run -d chrome

# For Android
flutter run

# For iOS
flutter run -d ios

# For macOS
flutter run -d macos
```

## What You Should See

1. **Login Screen** appears on first launch
2. Click **"Don't have an account? Sign up"**
3. Enter email and password (min 6 characters)
4. Click **"Sign Up"**
5. You'll be redirected to the **Dashboard**
6. You can **logout** using the logout icon in the top right
7. Login again with the same credentials

## Verify Everything Works

1. **Check Firebase Console → Authentication → Users**
   - You should see your newly created user

2. **Check Firebase Console → Firestore Database → Data**
   - You should see a `users` collection
   - With a document (your user ID)
   - Containing your user profile data

## Troubleshooting

### "No Firebase App '[DEFAULT]' has been created"
- Make sure you completed Step 4
- Check that `lib/firebase_options.dart` has your project configuration
- Run `flutter clean && flutter pub get`

### "An internal error has occurred"
- Check that Email/Password is enabled in Firebase Console
- Verify your internet connection
- Check Firebase Console for any project status issues

### "PERMISSION_DENIED"
- Check Firestore security rules (Step 5)
- Make sure user is logged in

### App won't build
- Run: `flutter clean && flutter pub get`
- Restart your IDE
- For Android: Make sure `google-services.json` is in `android/app/`
- For iOS: Make sure `GoogleService-Info.plist` is in `ios/Runner/`

## Testing Your Setup

Create a test account:
- Email: `test@example.com`
- Password: `password123`

Then try:
1. Sign up ✓
2. Auto-login to dashboard ✓
3. Logout ✓
4. Login again with same credentials ✓

## Next: What You Can Do

Now that Firebase is set up, your app has:

✅ **User Authentication** - Secure login/signup
✅ **User Profiles** - Stored in Firestore
✅ **Protected Dashboard** - Only accessible after login
✅ **Automatic Session Management** - Stay logged in
✅ **Real-time Database** - Firestore for user data

You can now:
- Save user quit plans to Firestore
- Track user progress in the database
- Sync data across devices
- Add more features (mood logs, badges, etc.)

## Need Help?

If you get stuck:
1. Check the Firebase Console for errors
2. Look at `flutter run` logs for detailed error messages
3. Verify all steps above were completed
4. Check [FIREBASE_SETUP.md](FIREBASE_SETUP.md) for more details

**Common Issue**: If FlutterFire CLI doesn't work, use Option B (Manual Configuration) - it works just as well!
