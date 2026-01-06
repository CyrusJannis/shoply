# Android Setup Guide for ShoplyAI

This guide covers everything needed to build and run ShoplyAI on Android.

## Prerequisites

1. **Android Studio** with Android SDK installed
2. **Java 17** (required for Gradle)
3. **Flutter SDK** (3.5.0 or higher)

## Firebase Setup (Required for Push Notifications)

### Step 1: Add Android App to Firebase

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `shoplyai-1554e`
3. Click "Add app" → "Android"
4. Enter package name: `com.dominik.shoply`
5. Download `google-services.json`
6. Replace the placeholder file at `android/app/google-services.json` with the downloaded file

### Step 2: Enable Firebase Cloud Messaging

1. In Firebase Console, go to "Cloud Messaging"
2. Enable FCM for your Android app
3. The app is already configured to receive push notifications

## Google Sign-In Setup

### Step 1: Configure OAuth Consent Screen

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to "APIs & Services" → "OAuth consent screen"
3. Configure as "External" and fill in required details

### Step 2: Create OAuth 2.0 Client ID

1. Go to "APIs & Services" → "Credentials"
2. Click "Create Credentials" → "OAuth 2.0 Client ID"
3. Select "Android" as application type
4. Enter package name: `com.dominik.shoply`
5. Add SHA-1 certificate fingerprint:

```bash
# For debug builds
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# For release builds
keytool -list -v -keystore your-release-key.keystore -alias your-key-alias
```

6. Add the SHA-1 to Firebase Console as well (Project Settings → Android app)

## Release Build Signing

### Step 1: Create Keystore

```bash
keytool -genkey -v -keystore ~/shoply-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias shoply
```

### Step 2: Configure Signing in Gradle

Create `android/key.properties`:

```properties
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=shoply
storeFile=/path/to/shoply-release-key.jks
```

Then update `android/app/build.gradle.kts`:

```kotlin
// Add at the top
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = java.util.Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

// Add signing config in android block
signingConfigs {
    create("release") {
        keyAlias = keystoreProperties["keyAlias"] as String
        keyPassword = keystoreProperties["keyPassword"] as String
        storeFile = file(keystoreProperties["storeFile"] as String)
        storePassword = keystoreProperties["storePassword"] as String
    }
}

buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
        // ... rest of config
    }
}
```

## Building the App

### Debug Build

```bash
flutter build apk --debug
```

### Release Build

```bash
flutter build apk --release
# or for App Bundle (recommended for Play Store)
flutter build appbundle --release
```

## Testing

### Run on Connected Device/Emulator

```bash
flutter run -d android
```

### Run on Specific Device

```bash
flutter devices  # List available devices
flutter run -d <device-id>
```

## Features Configured for Android

| Feature | iOS | Android | Notes |
|---------|-----|---------|-------|
| Push Notifications | ✅ | ✅ | Requires google-services.json |
| Google Sign-In | ✅ | ✅ | Requires SHA-1 fingerprint in Firebase |
| Apple Sign-In | ✅ | ❌ | iOS only |
| Deep Linking | ✅ | ✅ | `shoply://` and `https://shoplyai.app` |
| Voice Assistant | Siri | Google Assistant | Uses App Actions |
| Home Screen Widget | ✅ | 🔄 | Basic support, can be extended |
| Local Notifications | ✅ | ✅ | Full support |
| Camera/Gallery | ✅ | ✅ | Full support |
| In-App Purchases | ✅ | ✅ | Requires Play Console setup |

## Google Assistant App Actions

The app is configured to work with Google Assistant for:

- **Adding items**: "Hey Google, add milk to my Shoply list"
- **Creating lists**: "Hey Google, create a grocery list in Shoply"
- **Viewing lists**: "Hey Google, show my shopping list in Shoply"

These are configured in `android/app/src/main/res/xml/actions.xml`.

## Troubleshooting

### Build Fails with "No Android SDK"

Set the `ANDROID_HOME` environment variable:

```bash
export ANDROID_HOME=$HOME/Library/Android/sdk  # macOS
export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools
```

### Firebase Initialization Fails

1. Verify `google-services.json` is in `android/app/`
2. Check package name matches exactly: `com.dominik.shoply`
3. Ensure SHA-1 fingerprint is added to Firebase Console

### Google Sign-In Fails

1. Verify SHA-1 fingerprint is correct
2. Check OAuth consent screen is configured
3. Ensure package name matches in all places

### Push Notifications Not Working

1. Verify FCM is enabled in Firebase Console
2. Check device has Google Play Services
3. Test with Firebase Console "Test message" feature

## Minimum SDK Requirements

- **minSdk**: 23 (Android 6.0 Marshmallow)
- **targetSdk**: 34 (Android 14)
- **compileSdk**: 34

## Permissions

The app requests the following permissions:

- `INTERNET` - Network access
- `CAMERA` - Barcode scanning, recipe photos
- `READ_EXTERNAL_STORAGE` / `READ_MEDIA_IMAGES` - Gallery access
- `POST_NOTIFICATIONS` - Push notifications (Android 13+)
- `VIBRATE` - Notification vibration
- `RECEIVE_BOOT_COMPLETED` - Scheduled notifications
- `SCHEDULE_EXACT_ALARM` - Precise reminders

## Contact

For issues specific to Android implementation, check the configuration files:

- `android/app/build.gradle.kts` - App build configuration
- `android/app/src/main/AndroidManifest.xml` - App manifest
- `android/app/src/main/kotlin/com/dominik/shoply/MainActivity.kt` - Main activity
- `lib/firebase_options.dart` - Firebase configuration
