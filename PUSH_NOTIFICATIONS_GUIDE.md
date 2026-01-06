# Push Notifications Implementation Guide for Shoply

## Overview
This guide shows how to implement push notifications for key events in Shoply using local notifications for testing and remote notifications for production.

## Events to Notify About

### High Priority 🔴
1. **List Updates** - When someone adds/removes items from a shared list
2. **Recipe Likes** - When your recipe gets liked
3. **Recipe Comments** - When someone comments on your recipe
4. **List Invitations** - When you're invited to a shared list

### Medium Priority 🟡
5. **Shopping Completion** - When a shared list is marked as "shopping done"
6. **Recipe Ratings** - When your recipe gets rated
7. **New Followers** - If we add a follow system

## Implementation Steps

### Phase 1: Local Notifications (Testing)

Local notifications work on simulator and don't require server setup.

#### 1. Enable Local Notifications

Add to `pubspec.yaml` (already done):
```yaml
dependencies:
  flutter_local_notifications: ^16.3.2
```

#### 2. Create Notification Service

File: `lib/data/services/notification_service.dart`

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance {
    _instance ??= NotificationService._();
    return _instance!;
  }

  NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');

    const initializationSettings = InitializationSettings(
      iOS: initializationSettingsIOS,
      android: initializationSettingsAndroid,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
    debugPrint('✅ [NOTIFICATIONS] Initialized');
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 [NOTIFICATIONS] Tapped: ${response.payload}');
    // Handle notification tap - navigate to relevant screen
    // You can parse response.payload as JSON to determine action
  }

  Future<void> requestPermissions() async {
    final bool? granted = await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    debugPrint('✅ [NOTIFICATIONS] Permissions granted: $granted');
  }

  // Show notification for list update
  Future<void> notifyListUpdate({
    required String listName,
    required String action, // "added item", "removed item", "updated list"
    required String listId,
  }) async {
    await _showNotification(
      id: listId.hashCode,
      title: '🛒 $listName',
      body: 'Someone $action',
      payload: '{"type":"list_update","listId":"$listId"}',
    );
  }

  // Show notification for recipe like
  Future<void> notifyRecipeLike({
    required String recipeName,
    required String liker,
    required String recipeId,
  }) async {
    await _showNotification(
      id: recipeId.hashCode,
      title: '❤️ Recipe Liked!',
      body: '$liker liked your recipe "$recipeName"',
      payload: '{"type":"recipe_like","recipeId":"$recipeId"}',
    );
  }

  // Show notification for recipe comment
  Future<void> notifyRecipeComment({
    required String recipeName,
    required String commenter,
    required String comment,
    required String recipeId,
  }) async {
    await _showNotification(
      id: recipeId.hashCode + 1,
      title: '💬 New Comment',
      body: '$commenter commented on "$recipeName": $comment',
      payload: '{"type":"recipe_comment","recipeId":"$recipeId"}',
    );
  }

  // Show notification for list invitation
  Future<void> notifyListInvitation({
    required String listName,
    required String inviter,
    required String listId,
  }) async {
    await _showNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: '📨 List Invitation',
      body: '$inviter invited you to join "$listName"',
      payload: '{"type":"list_invitation","listId":"$listId"}',
    );
  }

  // Generic notification method
  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'shoply_channel',
      'Shoply Notifications',
      channelDescription: 'Notifications for lists, recipes, and updates',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );

    debugPrint('🔔 [NOTIFICATIONS] Shown: $title - $body');
  }

  // Clear all notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
```

#### 3. Initialize in main.dart

Add to `lib/main.dart`:

```dart
import 'package:shoply/data/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ... existing initialization
  
  // Initialize notifications
  await NotificationService.instance.initialize();
  await NotificationService.instance.requestPermissions();
  
  runApp(const MyApp());
}
```

#### 4. Trigger Notifications in Repositories

Example: `lib/data/repositories/list_repository.dart`

```dart
import 'package:shoply/data/services/notification_service.dart';

class ListRepository {
  // ... existing code
  
  Future<void> addItem(String listId, ShoppingItemModel item) async {
    // Add item to database
    await _supabase.from('shopping_items').insert(item.toJson());
    
    // Check if list is shared
    final shares = await _supabase
        .from('list_shares')
        .select('user_id, shopping_lists!inner(name)')
        .eq('list_id', listId)
        .neq('user_id', _supabase.auth.currentUser!.id);
    
    // Notify other users (they'll receive it when they open the app)
    if (shares.isNotEmpty) {
      final listName = shares[0]['shopping_lists']['name'];
      debugPrint('📤 [NOTIFICATIONS] Triggering notification for list update');
      // In production, this would trigger push notifications
      // For testing, show local notification
      await NotificationService.instance.notifyListUpdate(
        listName: listName,
        action: 'added "${item.name}"',
        listId: listId,
      );
    }
  }
}
```

Example: `lib/data/repositories/recipe_repository.dart`

```dart
Future<void> toggleLike(String recipeId) async {
  final userId = _supabase.auth.currentUser!.id;
  
  // Check if already liked
  final existing = await _supabase
      .from('recipe_likes')
      .select()
      .eq('recipe_id', recipeId)
      .eq('user_id', userId)
      .maybeSingle();
  
  if (existing == null) {
    // Add like
    await _supabase.from('recipe_likes').insert({
      'recipe_id': recipeId,
      'user_id': userId,
    });
    
    // Get recipe details and owner
    final recipe = await _supabase
        .from('recipes')
        .select('title, author_id, users!inner(display_name)')
        .eq('id', recipeId)
        .single();
    
    final currentUserName = _supabase.auth.currentUser!.userMetadata?['display_name'] ?? 'Someone';
    
    // Notify recipe author (if not self)
    if (recipe['author_id'] != userId) {
      await NotificationService.instance.notifyRecipeLike(
        recipeName: recipe['title'],
        liker: currentUserName,
        recipeId: recipeId,
      );
    }
  } else {
    // Remove like
    await _supabase.from('recipe_likes').delete().eq('id', existing['id']);
  }
}
```

### Phase 2: Remote Push Notifications (Production)

For production, you'll need Firebase Cloud Messaging (FCM) or Apple Push Notification service (APNs).

#### Option A: Firebase Cloud Messaging (Recommended)

**Why FCM?**
- Works on both iOS and Android
- Free tier is generous
- Integrates well with Supabase Edge Functions

**Setup Steps:**

1. **Enable Firebase Messaging** in `pubspec.yaml`:
```yaml
dependencies:
  firebase_messaging: ^16.0.3
  firebase_core: ^4.2.1
```

2. **Configure Firebase**:
   - Go to Firebase Console
   - Add iOS app with bundle ID: `com.dominik.shoply`
   - Download `GoogleService-Info.plist` → `ios/Runner/`
   - Add Android app (when ready)

3. **Update iOS Capabilities**:
   - Open `ios/Runner.xcworkspace` in Xcode
   - Select Runner target → Signing & Capabilities
   - Add "Push Notifications" capability
   - Add "Background Modes" → Check "Remote notifications"

4. **Create FCM Service** (`lib/data/services/fcm_service.dart`):
```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FCMService {
  static FCMService? _instance;
  static FCMService get instance {
    _instance ??= FCMService._();
    return _instance!;
  }

  FCMService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  String? _fcmToken;

  Future<void> initialize() async {
    // Request permission
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ [FCM] User granted permission');
    }

    // Get FCM token
    _fcmToken = await _fcm.getToken();
    debugPrint('📱 [FCM] Token: $_fcmToken');

    // Save token to Supabase user profile
    if (_fcmToken != null) {
      await _saveTokenToDatabase(_fcmToken!);
    }

    // Listen for token refresh
    _fcm.onTokenRefresh.listen(_saveTokenToDatabase);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
  }

  Future<void> _saveTokenToDatabase(String token) async {
    // Save to Supabase
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId != null) {
      await SupabaseService.instance.client
          .from('user_devices')
          .upsert({
        'user_id': userId,
        'fcm_token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('🔔 [FCM] Foreground: ${message.notification?.title}');
    
    // Show local notification when app is in foreground
    NotificationService.instance._showNotification(
      id: message.messageId.hashCode,
      title: message.notification?.title ?? 'Shoply',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
    );
  }
}

@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  debugPrint('🔔 [FCM] Background: ${message.notification?.title}');
}
```

5. **Create Supabase Edge Function** to send notifications:

File: `supabase/functions/send-notification/index.ts`

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  const { userIds, title, body, data } = await req.json()
  
  // Get FCM tokens for users
  const { data: devices } = await supabaseClient
    .from('user_devices')
    .select('fcm_token')
    .in('user_id', userIds)
  
  const tokens = devices.map(d => d.fcm_token)
  
  // Send via FCM
  const response = await fetch('https://fcm.googleapis.com/fcm/send', {
    method: 'POST',
    headers: {
      'Authorization': `key=${Deno.env.get('FCM_SERVER_KEY')}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      registration_ids: tokens,
      notification: { title, body },
      data: data,
    }),
  })
  
  return new Response(JSON.stringify({ success: true }), {
    headers: { 'Content-Type': 'application/json' },
  })
})
```

6. **Create Database Trigger** to auto-send notifications:

```sql
-- Table to store user devices and FCM tokens
CREATE TABLE IF NOT EXISTS user_devices (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  fcm_token TEXT NOT NULL,
  platform TEXT NOT NULL CHECK (platform IN ('ios', 'android')),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, fcm_token)
);

-- Enable RLS
ALTER TABLE user_devices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own devices"
ON user_devices FOR ALL
USING (user_id = auth.uid());

-- Function to send notification when item is added to shared list
CREATE OR REPLACE FUNCTION notify_list_update()
RETURNS TRIGGER AS $$
DECLARE
  list_name TEXT;
  item_name TEXT;
  owner_id UUID;
  share_user_ids UUID[];
BEGIN
  -- Get list details
  SELECT name, owner_id INTO list_name, owner_id
  FROM shopping_lists
  WHERE id = NEW.list_id;
  
  -- Get all users who share this list (excluding current user)
  SELECT ARRAY_AGG(user_id) INTO share_user_ids
  FROM list_shares
  WHERE list_id = NEW.list_id
  AND user_id != auth.uid();
  
  -- Also notify list owner if they're not the one who added the item
  IF owner_id != auth.uid() THEN
    share_user_ids := array_append(share_user_ids, owner_id);
  END IF;
  
  -- Call edge function to send notifications
  IF array_length(share_user_ids, 1) > 0 THEN
    PERFORM net.http_post(
      url := 'https://YOUR_PROJECT.supabase.co/functions/v1/send-notification',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || current_setting('request.jwt.claims')::json->>'token'
      ),
      body := jsonb_build_object(
        'userIds', share_user_ids,
        'title', '🛒 ' || list_name,
        'body', 'Someone added "' || NEW.name || '"',
        'data', jsonb_build_object('type', 'list_update', 'listId', NEW.list_id)
      )
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger
CREATE TRIGGER on_shopping_item_insert
AFTER INSERT ON shopping_items
FOR EACH ROW
EXECUTE FUNCTION notify_list_update();
```

#### Option B: APNs Only (iOS-focused)

If you only care about iOS:

1. **Generate APNs Certificate** in Apple Developer Portal
2. **Upload to Supabase** Project Settings → Auth → Apple
3. **Use local_auth** package to handle notifications

## Testing Notifications

### Test 1: Local Notifications (Simulator)

```dart
// Add a test button in profile screen
ElevatedButton(
  onPressed: () {
    NotificationService.instance.notifyRecipeLike(
      recipeName: 'Test Recipe',
      liker: 'Test User',
      recipeId: 'test123',
    );
  },
  child: Text('Test Notification'),
),
```

### Test 2: Background Notifications (Real Device)

1. Run app on real device
2. Put app in background (home button)
3. Trigger notification from another device
4. Should see notification in notification center

### Test 3: List Update Notification

1. Create a shared list
2. Add item from one device
3. Other device should get notification

## Notification Settings Screen

Already exists at: `lib/presentation/screens/profile/settings/notifications_screen.dart`

Add toggles for each notification type:
- List updates
- Recipe likes
- Recipe comments
- Shopping completion
- Marketing (optional)

Store preferences in `users` table:
```sql
ALTER TABLE users ADD COLUMN notification_preferences JSONB DEFAULT '{
  "list_updates": true,
  "recipe_likes": true,
  "recipe_comments": true,
  "shopping_completion": true,
  "marketing": false
}'::jsonb;
```

## Best Practices

1. **Don't spam** - Group multiple updates into one notification
2. **Respect quiet hours** - No notifications 10 PM - 8 AM
3. **Allow opt-out** - Each notification type should be toggleable
4. **Deep linking** - Tapping notification should open relevant screen
5. **Badge count** - Update app icon badge with unread notifications
6. **Test thoroughly** - Especially background delivery

## Cost Estimate

- **Local Notifications**: FREE
- **FCM**: FREE (up to unlimited messages)
- **APNs**: FREE (with Apple Developer Account $99/year)
- **Supabase Edge Functions**: FREE (up to 500K invocations/month)

## Quick Start Checklist

- [ ] Add NotificationService.dart
- [ ] Initialize in main.dart
- [ ] Request permissions
- [ ] Add test notification button
- [ ] Test on simulator
- [ ] Integrate with ListRepository
- [ ] Integrate with RecipeRepository
- [ ] Test on real device
- [ ] Set up FCM (production)
- [ ] Deploy edge functions
- [ ] Create database triggers
- [ ] Add notification settings UI
- [ ] Test end-to-end

## Troubleshooting

**Notifications not showing:**
- Check permissions: Settings → Shoply → Notifications
- Check if initialized in main.dart
- Check console for error messages
- Ensure notification channel is created (Android)

**Background delivery fails:**
- Add Background Modes capability (iOS)
- Check FCM token is saved correctly
- Verify edge function is deployed
- Check Supabase logs

**Simulator limitations:**
- Remote push notifications don't work on simulator
- Use local notifications for testing
- Test remote push on real device only

---

**Next Step**: Create the NotificationService.dart file and add the "Test Notification" button to profile screen for testing!
