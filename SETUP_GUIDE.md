# Shoply - Complete Setup Guide

This guide will walk you through setting up the Shoply app from scratch.

## Prerequisites

1. **Flutter SDK** (3.9.2 or higher)
   - Install from: https://flutter.dev/docs/get-started/install
   - Verify installation: `flutter doctor`

2. **Supabase Account**
   - Sign up at: https://supabase.com
   - Free tier is sufficient for development

3. **Firebase Account** (for push notifications)
   - Create project at: https://console.firebase.google.com
   - Free tier is sufficient

4. **IDE** (VS Code or Android Studio recommended)
   - VS Code: Install Flutter and Dart extensions
   - Android Studio: Install Flutter plugin

## Step 1: Clone and Install Dependencies

```bash
# Clone the repository (if from git)
git clone <your-repo-url>
cd shoply

# Install dependencies
flutter pub get
```

## Step 2: Configure Supabase

### 2.1 Create Supabase Project

1. Go to https://supabase.com/dashboard
2. Click "New Project"
3. Fill in project details:
   - Name: Shoply
   - Database Password: (choose a strong password)
   - Region: (select closest to you)
4. Wait for project to be created (~2 minutes)

### 2.2 Run Database Schema

1. In your Supabase project, go to "SQL Editor"
2. Click "New Query"
3. Copy the entire content of `supabase_schema.sql`
4. Paste into the query editor
5. Click "Run" to execute
6. Verify tables were created in "Table Editor"

### 2.3 Configure Authentication

1. Go to "Authentication" → "Providers"
2. Enable Email provider:
   - Toggle "Enable Email provider" ON
   - Enable "Confirm email" (recommended)
3. Configure Google OAuth (optional):
   - Get credentials from Google Cloud Console
   - Add redirect URL from Supabase
   - Enter Client ID and Secret
4. Configure Apple Sign-In (optional for iOS):
   - Set up in Apple Developer account
   - Configure in Supabase

### 2.4 Set up Storage

1. Go to "Storage"
2. Create three buckets:
   - `avatars` - for user profile pictures
   - `recipe-images` - for recipe photos
   - `flyer-images` - for promotional flyers
3. Set bucket policies (make public for reading):

```sql
-- For each bucket, run this policy:
CREATE POLICY "Public Access"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');
```

### 2.5 Enable Realtime

1. Go to "Database" → "Replication"
2. Enable replication for these tables:
   - `shopping_lists`
   - `shopping_items`
   - `notifications`

### 2.6 Get API Keys

1. Go to "Settings" → "API"
2. Copy these values:
   - Project URL
   - anon public key

## Step 3: Configure Environment Variables

1. Open `lib/core/config/env.dart`
2. Replace the placeholders:

```dart
class Env {
  static const String supabaseUrl = 'https://your-project.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key-here';
  
  // ... rest of the file
}
```

**IMPORTANT:** Never commit this file with real credentials!

Add to `.gitignore`:
```
lib/core/config/env.dart
```

## Step 4: Configure Firebase (for Push Notifications)

### 4.1 Create Firebase Project

1. Go to https://console.firebase.google.com
2. Click "Add Project"
3. Name it "Shoply"
4. Disable Google Analytics (optional)
5. Click "Create Project"

### 4.2 Add Android App

1. In Firebase console, click "Add app" → Android icon
2. Enter package name: `com.example.shoply` (or your custom package)
3. Download `google-services.json`
4. Place it in `android/app/` directory

### 4.3 Add iOS App

1. Click "Add app" → iOS icon
2. Enter bundle ID: `com.example.shoply` (or your custom bundle)
3. Download `GoogleService-Info.plist`
4. Place it in `ios/Runner/` directory

### 4.4 Enable Cloud Messaging

1. In Firebase console, go to "Cloud Messaging"
2. Enable Cloud Messaging API
3. Copy Server Key for later use

## Step 5: Platform-Specific Setup

### Android Setup

1. Open `android/app/build.gradle`
2. Verify minimum SDK version is 21 or higher:

```gradle
minSdkVersion 21
```

3. Add Google Services plugin (should already be configured)

### iOS Setup

1. Open `ios/Podfile`
2. Ensure platform is iOS 12.0 or higher:

```ruby
platform :ios, '12.0'
```

3. Run pod install:

```bash
cd ios
pod install
cd ..
```

4. Configure permissions in `ios/Runner/Info.plist`:

```xml
<!-- Camera Permission -->
<key>NSCameraUsageDescription</key>
<string>We need camera access to scan barcodes</string>

<!-- Photo Library Permission -->
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to save images</string>

<!-- Biometric Authentication -->
<key>NSFaceIDUsageDescription</key>
<string>We use Face ID for secure authentication</string>
```

## Step 6: Test the App

### 6.1 Run on Emulator/Simulator

```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d <device-id>

# Or simply run (will prompt for device)
flutter run
```

### 6.2 Test Authentication

1. Launch the app
2. You should see the login screen
3. Try creating an account:
   - Use a real email (you'll need to verify it)
   - Password must meet requirements (8+ chars, 1 uppercase, 1 number)
4. Check your email for verification link (if enabled)
5. Sign in with your credentials

### 6.3 Test Basic Features

1. After login, you should see the Home screen
2. Navigate through bottom tabs (Home, Lists, Recipes, Profile)
3. Try creating a shopping list:
   - Go to Lists tab
   - Click the + icon
   - Enter a list name
   - Click Create
4. Check Profile section:
   - View your profile info
   - Try signing out

## Step 7: Enable Advanced Features

### 7.1 Barcode Scanner

The barcode scanner should work out of the box on physical devices.

**Note:** Camera permissions are required. Make sure you've added the permissions in Step 5.

### 7.2 Push Notifications

To enable push notifications:

1. Get FCM server key from Firebase Console
2. Create Supabase Edge Function for sending notifications
3. Configure in your app (see full documentation)

### 7.3 Deep Linking

Configure deep links for list sharing:

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data
        android:scheme="shoply"
        android:host="app.shoply.com" />
</intent-filter>
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>shoply</string>
        </array>
    </dict>
</array>
```

## Step 8: Troubleshooting

### Common Issues

**1. "Supabase has not been initialized"**
- Make sure you've filled in `env.dart` with your Supabase credentials
- Check that Supabase URL and key are correct

**2. "Connection refused" or network errors**
- Check your internet connection
- Verify Supabase project is running
- Check if you're behind a firewall/proxy

**3. Authentication errors**
- Verify email provider is enabled in Supabase
- Check if email confirmation is required
- Try with a different email

**4. Database errors**
- Verify `supabase_schema.sql` was run successfully
- Check RLS policies are set up correctly
- Verify user has proper permissions

**5. Build errors**
- Run `flutter clean`
- Delete `pubspec.lock`
- Run `flutter pub get` again
- For iOS: `cd ios && pod install`

### Debug Mode

Run in debug mode to see detailed logs:

```bash
flutter run --verbose
```

### Check Supabase Logs

1. Go to Supabase Dashboard
2. Click "Logs" → "API Logs"
3. Check for errors in requests

## Step 9: Development Workflow

### Making Changes

1. Create a feature branch:
```bash
git checkout -b feature/your-feature-name
```

2. Make your changes

3. Test thoroughly:
```bash
flutter test
```

4. Commit and push:
```bash
git add .
git commit -m "Add feature: your feature description"
git push origin feature/your-feature-name
```

### Hot Reload

While app is running:
- Press `r` for hot reload
- Press `R` for hot restart
- Press `q` to quit

### Code Generation

If you modify models or providers:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Step 10: Production Deployment

### Prepare for Release

1. Update version in `pubspec.yaml`:
```yaml
version: 1.0.0+1
```

2. Generate app icons (optional):
   - Use a tool like https://icon.kitchen
   - Replace icons in `android/app/src/main/res/` and `ios/Runner/Assets.xcassets/`

3. Update app name and package:
   - Android: `android/app/src/main/AndroidManifest.xml`
   - iOS: `ios/Runner/Info.plist`

### Build for Production

**Android (APK):**
```bash
flutter build apk --release
```

**Android (App Bundle - recommended for Play Store):**
```bash
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
```

### Signing

**Android:**
1. Create keystore:
```bash
keytool -genkey -v -keystore ~/shoply-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias shoply
```

2. Configure in `android/key.properties`
3. Update `android/app/build.gradle`

**iOS:**
1. Set up signing in Xcode
2. Configure provisioning profiles
3. Archive and submit to App Store

## Next Steps

Now that your app is set up:

1. **Customize the theme** - Edit colors in `lib/core/constants/app_colors.dart`
2. **Add more features** - Check the roadmap in README
3. **Test on real devices** - Test on both Android and iOS
4. **Add sample data** - Populate Supabase with test data
5. **Implement analytics** - Add Firebase Analytics (optional)

## Getting Help

If you encounter issues:

1. Check this guide carefully
2. Review Flutter documentation: https://flutter.dev/docs
3. Check Supabase documentation: https://supabase.com/docs
4. Open an issue on GitHub (if using repo)
5. Check Stack Overflow for common Flutter/Supabase issues

## Resources

- Flutter Documentation: https://flutter.dev/docs
- Supabase Documentation: https://supabase.com/docs
- Go Router Documentation: https://pub.dev/packages/go_router
- Riverpod Documentation: https://riverpod.dev

---

**Happy Coding! 🚀**
