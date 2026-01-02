# Deep Linking & Native Sharing Setup Guide

This document provides complete setup instructions for iOS Universal Links, Android App Links, and native sharing functionality in the Shoply app.

## Overview

The app uses **app_links** package for deep link handling with:
- **Universal Links (iOS)** - HTTPS links that open the app when installed
- **App Links (Android)** - Verified HTTPS links for Android
- **Custom Scheme** - `shoply://` fallback for direct app opening
- **Native Share Dialogs** - Platform-native sharing via `share_plus`

## Link Structure

| Content Type | Web URL | Custom Scheme |
|-------------|---------|---------------|
| Recipe | `https://shoplyai.app/recipe/[id]` | `shoply://recipe/[id]` |
| Shopping List | `https://shoplyai.app/list/[id]` | `shoply://list/[id]` |
| List Invite | `https://shoplyai.app/invite/[id]` | `shoply://invite/[id]` |
| Author Profile | `https://shoplyai.app/author/[id]` | `shoply://author/[id]` |

---

## iOS Universal Links Setup

### Step 1: Find Your Team ID

1. Go to [Apple Developer Portal](https://developer.apple.com/account)
2. Click on "Membership" in the sidebar
3. Your **Team ID** is displayed (e.g., `CTBGYBDPP4`)

### Step 2: Apple App Site Association (AASA) File

The AASA file is located at: `web/.well-known/apple-app-site-association`

Host this file at `https://shoplyai.app/.well-known/apple-app-site-association`

**Requirements:**
- Must be served over HTTPS (no redirects)
- Content-Type: `application/json`
- No authentication required

### Step 3: Entitlements Configuration

Associated Domains have been configured in both entitlements files:
- `ios/Runner/Runner.entitlements` (Release)
- `ios/Runner/RunnerDebug.entitlements` (Debug)

```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:shoplyai.app</string>
    <string>applinks:www.shoplyai.app</string>
</array>
```

### Step 4: Enable Associated Domains in Apple Developer Portal

1. Go to [Apple Developer Portal](https://developer.apple.com/account/resources/identifiers)
2. Select your App ID (`com.dominik.shoply`)
3. Enable "Associated Domains" capability
4. Save changes

---

## Android App Links Setup

### Step 1: Get SHA-256 Fingerprints

**Debug Fingerprint:**
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android | grep SHA256
```

Current debug fingerprint: `74:48:50:5B:82:58:93:10:A6:42:45:F2:D4:EF:03:C2:2F:3C:38:EB:77:98:61:EE:AD:DE:82:BB:B3:23:26:85`

**Release Fingerprint:**
```bash
keytool -list -v -keystore /path/to/your/release.keystore -alias your-alias | grep SHA256
```

### Step 2: Digital Asset Links File

The assetlinks.json file is located at: `web/.well-known/assetlinks.json`

Host this file at `https://shoplyai.app/.well-known/assetlinks.json`

**Important:** Replace `REPLACE_WITH_RELEASE_SHA256_FINGERPRINT` with your actual release keystore fingerprint.

### Step 3: Android Manifest Configuration

Intent filters have been added in `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- HTTPS App Links -->
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data android:scheme="https" android:host="shoplyai.app"/>
</intent-filter>

<!-- Custom scheme -->
<intent-filter>
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data android:scheme="shoply" android:host="recipe"/>
</intent-filter>
```

---

## Flutter Implementation

### Using the Sharing Service

```dart
import 'package:shoply/data/services/sharing_service.dart';

// Share a recipe
await SharingService.instance.shareRecipe(recipe);

// Share a shopping list
await SharingService.instance.shareList(
  listId: 'list-uuid',
  listName: 'Weekly Groceries',
  itemCount: 15,
);

// Share a list invite
await SharingService.instance.shareListInvite(
  listId: 'list-uuid',
  listName: 'Family Shopping',
);

// Share an author profile
await SharingService.instance.shareAuthor(
  authorId: 'author-uuid',
  authorName: 'Chef John',
  recipeCount: 25,
);
```

### Getting Share URLs

```dart
import 'package:shoply/data/services/deep_link_service.dart';

// Get shareable URLs
final recipeUrl = DeepLinkService.getRecipeShareUrl('recipe-id');
// Returns: https://shoplyai.app/recipe/recipe-id

final listUrl = DeepLinkService.getListShareUrl('list-id');
// Returns: https://shoplyai.app/list/list-id

final inviteUrl = DeepLinkService.getListInviteUrl('list-id');
// Returns: https://shoplyai.app/invite/list-id
```

### Handling Incoming Links

The `DeepLinkService` automatically handles incoming links. It's initialized in `app.dart`:

```dart
// Initialization happens automatically in app.dart
await DeepLinkService.instance.initialize(router);
DeepLinkService.instance.processPendingDeepLink();
```

---

## Web Hosting Requirements

### Files to Host

Upload these files to your web server at `https://shoplyai.app`:

1. `/.well-known/apple-app-site-association` - iOS Universal Links
2. `/.well-known/assetlinks.json` - Android App Links
3. `/recipe.html` - Recipe landing page (optional)
4. `/list.html` - List landing page (optional)

### Server Configuration (Nginx Example)

```nginx
# Serve .well-known files with correct content type
location /.well-known/ {
    add_header Content-Type application/json;
}

# Route deep link paths to landing pages
location ~ ^/recipe/(.+)$ {
    try_files $uri /recipe.html;
}

location ~ ^/list/(.+)$ {
    try_files $uri /list.html;
}

location ~ ^/invite/(.+)$ {
    try_files $uri /list.html;
}
```

---

## Testing

### Test on iOS

```bash
# Test with simulator
xcrun simctl openurl booted "https://shoplyai.app/recipe/test-123"

# Test custom scheme
xcrun simctl openurl booted "shoply://recipe/test-123"
```

### Test on Android

```bash
# Test HTTPS link
adb shell am start -W -a android.intent.action.VIEW \
  -d "https://shoplyai.app/recipe/test-123" \
  com.dominik.shoply

# Verify app link status
adb shell pm get-app-links com.dominik.shoply

# Re-verify links
adb shell pm verify-app-links --re-verify com.dominik.shoply
```

### Validate Configuration Files

```bash
# Check AASA file
curl -I https://shoplyai.app/.well-known/apple-app-site-association

# Check assetlinks.json
curl https://shoplyai.app/.well-known/assetlinks.json

# Use Google's verification tool
# https://developers.google.com/digital-asset-links/tools/generator
```

---

## Testing Checklist

### iOS
- [ ] AASA file accessible at correct URL
- [ ] Content-Type is `application/json`
- [ ] Associated Domains enabled in Apple Developer Portal
- [ ] App opens from HTTPS link when installed
- [ ] Custom scheme `shoply://` works
- [ ] Share sheet shows proper content

### Android
- [ ] assetlinks.json accessible at correct URL
- [ ] SHA-256 fingerprints are correct (debug + release)
- [ ] App link verification passes
- [ ] App opens from HTTPS link when installed
- [ ] Custom scheme works
- [ ] Share intent shows proper content

### Cross-Platform
- [ ] Links work from SMS/iMessage
- [ ] Links work from email clients
- [ ] Links work from social media apps
- [ ] Links work from browser address bar
- [ ] App navigates to correct screen from link

---

## Troubleshooting

### iOS Universal Links Not Working

1. **Check AASA file:**
   ```bash
   curl -v https://shoplyai.app/.well-known/apple-app-site-association
   ```

2. **Verify no redirects** - URL must return 200 directly

3. **Check Content-Type** - Must be `application/json`

4. **Reinstall app** - iOS caches AASA files

5. **Use Apple's validator:**
   https://search.developer.apple.com/appsearch-validation-tool/

### Android App Links Not Working

1. **Check assetlinks.json:**
   ```bash
   curl https://shoplyai.app/.well-known/assetlinks.json
   ```

2. **Verify SHA-256 fingerprint matches**

3. **Check verification status:**
   ```bash
   adb shell pm get-app-links com.dominik.shoply
   ```

4. **Clear and re-verify:**
   ```bash
   adb shell pm set-app-links --package com.dominik.shoply 0 all
   adb shell pm verify-app-links --re-verify com.dominik.shoply
   ```

---

## Security Considerations

1. **Validate incoming links** - App validates all parameters before navigation
2. **Use HTTPS only** - All web URLs use HTTPS
3. **No sensitive data in URLs** - Only UUIDs in links, no PII
4. **Authentication check** - Private content requires auth after navigation
