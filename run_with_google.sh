#!/bin/bash

# Google Sign-In Configuration
# Replace these with your actual Client IDs from Google Cloud Console

GOOGLE_CLIENT_ID="901497821159-h85ocfnbfrfar09u2evtkbloudi99hdi.apps.googleusercontent.com"
GOOGLE_WEB_CLIENT_ID="901497821159-862bdr193n7pdstmgf3tl6afupm2d14u.apps.googleusercontent.com"

# Run the app with Google Sign-In enabled
flutter run -d macos \
  --dart-define=GOOGLE_CLIENT_ID=$GOOGLE_CLIENT_ID \
  --dart-define=GOOGLE_WEB_CLIENT_ID=$GOOGLE_WEB_CLIENT_ID
