#!/bin/bash

# inject_firebase_config.sh
# Build Phase Script: Reads API key from .env and injects into GoogleService-Info.plist
# This runs as an Xcode Build Phase ("Run Script") before the "Copy Bundle Resources" phase.

set -e

ENV_FILE="${SRCROOT}/.env"
PLIST_FILE="${SRCROOT}/Vibe/GoogleService-Info.plist"

# Fallback: also check root-level plist
ROOT_PLIST_FILE="${SRCROOT}/GoogleService-Info.plist"

if [ ! -f "$ENV_FILE" ]; then
    echo "error: .env file not found at ${ENV_FILE}. Copy .env.example to .env and fill in your keys."
    exit 1
fi

# Read FIREBASE_API_KEY from .env
FIREBASE_API_KEY=$(grep -E '^FIREBASE_API_KEY=' "$ENV_FILE" | cut -d '=' -f2 | tr -d '[:space:]')

if [ -z "$FIREBASE_API_KEY" ] || [ "$FIREBASE_API_KEY" = "YOUR_FIREBASE_API_KEY_HERE" ]; then
    echo "error: FIREBASE_API_KEY is not set in .env file. Please add your Firebase API key."
    exit 1
fi

# Inject into Vibe/GoogleService-Info.plist
if [ -f "$PLIST_FILE" ]; then
    /usr/libexec/PlistBuddy -c "Set :API_KEY ${FIREBASE_API_KEY}" "$PLIST_FILE"
    echo "✅ Injected FIREBASE_API_KEY into ${PLIST_FILE}"
fi

# Inject into root GoogleService-Info.plist if it exists
if [ -f "$ROOT_PLIST_FILE" ]; then
    /usr/libexec/PlistBuddy -c "Set :API_KEY ${FIREBASE_API_KEY}" "$ROOT_PLIST_FILE"
    echo "✅ Injected FIREBASE_API_KEY into ${ROOT_PLIST_FILE}"
fi

echo "🔐 Firebase config injection complete."
