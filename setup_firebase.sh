#!/bin/bash

# Firebase Setup Helper Script for MYQuitMate
# This script helps you configure Firebase for your Flutter app

echo "🔥 Firebase Setup Helper for MYQuitMate"
echo "========================================"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Step 1: Check if FlutterFire CLI is available
echo "Step 1: Checking FlutterFire CLI..."
export PATH="$PATH":"$HOME/.pub-cache/bin"

if command -v flutterfire &> /dev/null; then
    echo -e "${GREEN}✓ FlutterFire CLI is installed${NC}"
else
    echo -e "${RED}✗ FlutterFire CLI not found${NC}"
    echo "Installing FlutterFire CLI..."
    dart pub global activate flutterfire_cli
    export PATH="$PATH":"$HOME/.pub-cache/bin"
fi

echo ""

# Step 2: Check if Firebase CLI is available
echo "Step 2: Checking Firebase CLI..."

if command -v firebase &> /dev/null; then
    echo -e "${GREEN}✓ Firebase CLI is installed${NC}"
else
    echo -e "${YELLOW}⚠ Firebase CLI not found${NC}"
    echo "Installing Firebase CLI (requires sudo)..."
    echo "You may be asked for your password."

    if sudo npm install -g firebase-tools; then
        echo -e "${GREEN}✓ Firebase CLI installed successfully${NC}"
    else
        echo -e "${RED}✗ Failed to install Firebase CLI${NC}"
        echo ""
        echo "Please install manually:"
        echo "  sudo npm install -g firebase-tools"
        echo ""
        echo "Or follow the manual setup in QUICK_FIREBASE_SETUP.md"
        exit 1
    fi
fi

echo ""

# Step 3: Login to Firebase
echo "Step 3: Logging into Firebase..."
echo "This will open a browser window for you to login."
echo ""

if firebase login; then
    echo -e "${GREEN}✓ Successfully logged into Firebase${NC}"
else
    echo -e "${RED}✗ Firebase login failed${NC}"
    echo ""
    echo "Please try manually:"
    echo "  firebase login"
    exit 1
fi

echo ""

# Step 4: Configure FlutterFire
echo "Step 4: Configuring your Flutter app with Firebase..."
echo ""
echo "You will be prompted to:"
echo "  1. Select your Firebase project (or create a new one)"
echo "  2. Select platforms (iOS, Android, Web, macOS)"
echo ""
echo "Press any key to continue..."
read -n 1 -s

if flutterfire configure; then
    echo ""
    echo -e "${GREEN}✓ Firebase configuration complete!${NC}"
else
    echo ""
    echo -e "${RED}✗ FlutterFire configuration failed${NC}"
    echo ""
    echo "Please try manually:"
    echo "  flutterfire configure"
    exit 1
fi

echo ""

# Step 5: Reminder about Firebase Console setup
echo "========================================"
echo -e "${GREEN}🎉 Setup Complete!${NC}"
echo "========================================"
echo ""
echo "Next steps (in Firebase Console):"
echo ""
echo "1. Enable Authentication:"
echo "   → Go to: https://console.firebase.google.com"
echo "   → Click 'Authentication' → 'Get started'"
echo "   → Enable 'Email/Password' provider"
echo ""
echo "2. Create Firestore Database:"
echo "   → Click 'Firestore Database' → 'Create database'"
echo "   → Select 'Start in test mode'"
echo "   → Choose your region"
echo ""
echo "3. Run your app:"
echo "   → flutter run"
echo ""
echo "For detailed instructions, see: QUICK_FIREBASE_SETUP.md"
echo ""
