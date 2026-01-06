# 🔔 Notification Fix Guide - Complete Implementation

**Date**: November 13, 2025
**Status**: 🟡 In Progress

---

## ✅ What I Just Fixed

1. **Enabled firebase_messaging** in pubspec.yaml
2. **Updated firebase_core** to 4.2.1 (from 3.6.0)
3. **Updated firebase_analytics** to 12.0.4 (from 11.3.3)
4. **Installed dependencies** successfully

---

## 🚧 What YOU Need to Do

### **Step 1: Get Firebase Configuration File** ⚠️ REQUIRED

1. Go to **Firebase Console**: https://console.firebase.google.com/
2. Select your project (or create one if needed)
3. Click on the **iOS app** or add iOS app if not exists
   - iOS Bundle ID: `com.dominik.shoply`
4. **Download `GoogleService-Info.plist`**
5. **Place it in**: `/Users/jannisdietrich/Documents/shoply/ios/Runner/GoogleService-Info.plist`

### **Step 2: Enable Cloud Messaging in Firebase**

1. In Firebase Console → **Project Settings**
2. Go to **Cloud Messaging** tab
3. Under **iOS app configuration**:
   - Upload your **APNs Auth Key** or **APNs Certificate**
   - Get this from **Apple Developer Portal** → Certificates, Identifiers & Profiles

### **Step 3: Configure Xcode** ⚠️ REQUIRED

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Runner** target → **Signing & Capabilities**
3. Click **+ Capability** → Add **"Push Notifications"**
4. Click **+ Capability** → Add **"Background Modes"**
   - Check ✅ **"Remote notifications"**
5. Build the project once in Xcode to verify configuration

---

## 💻 Code Changes Needed

### **Create FCM Service**

I'll create this file for you:

**File**: `lib/data/services/fcm_service.dart`

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shoply/data/services/supabase_service.dart';
import 'package:shoply/data/services/notification_service.dart';

/// Handle Firebase Cloud Messaging background messages
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  debugPrint('🔔 [FCM] Background message: ${message.notification?.title}');
}

class FCMService {
  static FCMService? _instance;
  static FCMService get instance {
    _instance ??= FCMService._();
    return _instance!;
  }

  FCMService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  String? _fcmToken;

  /// Initialize Firebase Cloud Messaging
  Future<void> initialize() async {
    try {
      debugPrint('🔵 [FCM] Initializing...');

      // Request permission
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ [FCM] User granted permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('⚠️ [FCM] User granted provisional permission');
      } else {
        debugPrint('❌ [FCM] User declined permission');
        return;
      }

      // Get FCM token
      _fcmToken = await _fcm.getToken();
      debugPrint('📱 [FCM] Token: $_fcmToken');

      // Save token to database
      if (_fcmToken != null) {
        await _saveTokenToDatabase(_fcmToken!);
      }

      // Listen for token refresh
      _fcm.onTokenRefresh.listen(_saveTokenToDatabase);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

      // Handle notification taps
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      debugPrint('✅ [FCM] Initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ [FCM] Initialization failed: $e');
      debugPrint('❌ [FCM] Stack trace: $stackTrace');
    }
  }

  /// Save FCM token to Supabase
  Future<void> _saveTokenToDatabase(String token) async {
    try {
      final userId = SupabaseService.instance.currentUser?.id;
      if (userId == null) {
        debugPrint('⚠️ [FCM] No user logged in, skipping token save');
        return;
      }

      await SupabaseService.instance.client
          .from('users')
          .update({'fcm_token': token})
          .eq('id', userId);

      debugPrint('✅ [FCM] Token saved to database');
    } catch (e) {
      debugPrint('❌ [FCM] Failed to save token: $e');
    }
  }

  /// Handle foreground messages - show local notification
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('🔔 [FCM] Foreground message: ${message.notification?.title}');

    if (message.notification != null) {
      // Show local notification when app is in foreground
      NotificationService.instance._showNotification(
        id: message.messageId.hashCode,
        title: message.notification!.title ?? 'Shoply',
        body: message.notification!.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  /// Handle notification tap - navigate to relevant screen
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('🔔 [FCM] Notification tapped: ${message.data}');

    // TODO: Add navigation logic based on notification type
    // Example:
    // if (message.data['type'] == 'list_update') {
    //   navigatorKey.currentContext?.push('/lists/${message.data['listId']}');
    // }
  }

  /// Get current FCM token
  String? get token => _fcmToken;
}
```

### **Update main.dart**

Add FCM initialization after NotificationService:

```dart
// Initialize Push Notifications (around line 66)
if (Platform.isIOS || Platform.isAndroid) {
  debugPrint('🔵 [MAIN] Initializing Notification Service...');
  await NotificationService.instance.initialize();
  await NotificationService.instance.requestPermissions();
  debugPrint('✅ Notification Service initialized');
  
  // Initialize Firebase Cloud Messaging
  debugPrint('🔵 [MAIN] Initializing FCM...');
  await FCMService.instance.initialize();
  debugPrint('✅ FCM initialized');
}
```

### **Update Database Schema**

Add FCM token column to users table in Supabase:

```sql
-- Add fcm_token column to users table
ALTER TABLE users 
  ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- Add index for faster lookups
CREATE INDEX IF NOT EXISTS idx_users_fcm_token ON users(fcm_token);
```

---

## 🔍 Testing Notifications

### **Test Local Notifications** (Should work now)

```dart
// In your app, try:
await NotificationService.instance.notifyListUpdate(
  listName: 'Test List',
  itemName: 'Test Item',
  updatedBy: 'You',
  listId: 'test-123',
);
```

### **Test Push Notifications** (After completing Steps 1-3)

1. Use **Firebase Console** → Cloud Messaging → Send test message
2. Select your device FCM token
3. Send notification
4. Should receive notification even when app is closed

---

## 📊 Summary

### ✅ Done by Me:
- Enabled `firebase_messaging` package
- Updated Firebase dependencies
- Installed all packages

### 🟡 TODO by You:
1. **Download GoogleService-Info.plist** from Firebase Console
2. **Enable Cloud Messaging** in Firebase with APNs certificate
3. **Configure Push Notifications** in Xcode
4. **Create FCM Service** (code provided above)
5. **Update main.dart** (code provided above)
6. **Update Database** (SQL provided above)

### Estimated Time:
- Firebase setup: **15-20 minutes**
- Code implementation: **10-15 minutes**
- Testing: **10 minutes**
- **Total: ~45 minutes**

---

## 🆘 If Notifications Still Don't Work

Check these:

1. ✅ **Permissions**: Go to iOS Settings → Shoply → Notifications → Ensure "Allow Notifications" is ON
2. ✅ **GoogleService-Info.plist**: Must be in correct location
3. ✅ **APNs Certificate**: Must be uploaded to Firebase Console
4. ✅ **FCM Token**: Check console logs for `📱 [FCM] Token: ...`
5. ✅ **Build**: Clean build in Xcode after adding capabilities

---

## 📞 Need Help?

If you get stuck:
1. Check Firebase Console for error messages
2. Check Xcode console for FCM logs
3. Verify APNs certificate is valid
4. Make sure bundle ID matches: `com.dominik.shoply`

---

**Next Steps**: Complete TODO items above, then test! 🚀
