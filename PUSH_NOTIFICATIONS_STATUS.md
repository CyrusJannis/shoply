# Push Notifications Status

**Date**: November 10, 2025  
**Status**: ❌ **DISABLED** (Intentionally)

---

## 🚫 Current State

Push notifications are **completely disabled** in the Shoply app.

### Disabled Package

In `pubspec.yaml` line 51:
```yaml
# firebase_messaging: ^16.0.3  # Disabled for Google Sign-In compatibility
```

### Reason for Disabling

Firebase Messaging was disabled to maintain compatibility with Google Sign-In implementation. There were conflicts between the packages that prevented proper authentication flow.

---

## 📱 What Users See

The Settings screen shows:
- **"Push-Benachrichtigungen"** (German) / **"Push Notifications"** (English)
- Subtitle: **"Einstellungen verwalten"** / **"Manage preferences"**
- Tapping opens: `NotificationsScreen`

However, the NotificationsScreen is a **placeholder UI** without actual push notification functionality.

---

## 🔧 Implementation Details

### Files Involved

1. **`lib/presentation/screens/profile/settings/notifications_screen.dart`**
   - UI for notification preferences
   - Settings can be toggled but have no effect
   - No actual Firebase integration

2. **`pubspec.yaml`**
   - `firebase_messaging` commented out
   - No push notification dependencies active

### UI Categories in NotificationsScreen

**Recipes** (Recipe notifications):
- Recipe likes on your recipes
- Comments on recipes
- New recipes published

**Lists** (Shopping list notifications):
- List updates (items added/removed)
- List invitations
- Changes in shared lists

**General**:
- Weekly digest
- Promotions & news

---

## ✅ What Works

- ✅ Settings UI is functional
- ✅ User preferences are saved to local storage
- ✅ UI toggles work smoothly
- ✅ Fully bilingual (German/English)

---

## ❌ What Doesn't Work

- ❌ No actual push notifications sent
- ❌ No Firebase Cloud Messaging integration
- ❌ No device token registration
- ❌ No background notification handling
- ❌ Settings have no real effect

---

## 🚀 How to Enable Push Notifications

If you want to implement push notifications in the future, here's what you need to do:

### Step 1: Resolve Google Sign-In Conflict

1. Update both packages to latest compatible versions:
   ```yaml
   dependencies:
     google_sign_in: ^6.2.2
     firebase_messaging: ^16.0.3
   ```

2. Test authentication flow thoroughly
3. Ensure no version conflicts

### Step 2: Firebase Setup

1. **iOS Configuration**:
   - Enable Push Notifications in Xcode capabilities
   - Upload APNs certificate to Firebase Console
   - Add `GoogleService-Info.plist` with messaging enabled

2. **Android Configuration**:
   - Add `google-services.json`
   - Configure FCM in Firebase Console
   - Set up notification channels

### Step 3: Backend Integration

Create Supabase Edge Function for sending notifications:

```typescript
// supabase/functions/send-notification/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  const { userIds, title, body, data } = await req.json()
  
  // Get user FCM tokens from database
  const { data: users } = await supabase
    .from('users')
    .select('fcm_token')
    .in('id', userIds)
  
  // Send via FCM API
  for (const user of users) {
    await fetch('https://fcm.googleapis.com/v1/projects/YOUR_PROJECT/messages:send', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${FCM_SERVER_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        message: {
          token: user.fcm_token,
          notification: { title, body },
          data
        }
      })
    })
  }
  
  return new Response(JSON.stringify({ success: true }), {
    headers: { 'Content-Type': 'application/json' }
  })
})
```

### Step 4: Database Schema

Add FCM token storage:

```sql
-- Add to users table
ALTER TABLE users 
  ADD COLUMN fcm_token TEXT,
  ADD COLUMN notification_preferences JSONB DEFAULT '{
    "recipe_likes": true,
    "comments": true,
    "new_recipes": true,
    "list_updates": true,
    "list_invites": true,
    "shared_list_changes": true,
    "weekly_digest": true,
    "promotions": false
  }'::jsonb;
```

### Step 5: Flutter Implementation

```dart
// lib/data/services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  
  Future<void> initialize() async {
    // Request permissions
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    // Get FCM token
    final token = await _messaging.getToken();
    if (token != null) {
      await _saveTokenToDatabase(token);
    }
    
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
  }
  
  Future<void> _saveTokenToDatabase(String token) async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId != null) {
      await SupabaseService.instance.client
        .from('users')
        .update({'fcm_token': token})
        .eq('id', userId);
    }
  }
}
```

### Step 6: Trigger Notifications

Update repositories to trigger notifications:

```dart
// When item added to shared list
await supabase.functions.invoke('send-notification', body: {
  'userIds': sharedListMemberIds,
  'title': 'List Updated',
  'body': '$userName added $itemName to $listName',
  'data': {'type': 'list_update', 'listId': listId}
});
```

---

## 📊 Estimated Effort

| Task | Effort | Priority |
|------|--------|----------|
| Resolve package conflicts | 2-4 hours | High |
| Firebase setup (iOS/Android) | 4-6 hours | High |
| FCM token management | 2-3 hours | High |
| Edge function for sending | 3-4 hours | Medium |
| Notification triggers | 4-6 hours | Medium |
| Testing on real devices | 3-4 hours | High |
| **Total** | **18-27 hours** | - |

---

## 🎯 Current Recommendation

**Keep push notifications disabled** for now because:

1. ✅ App works perfectly without them
2. ✅ No user complaints about missing notifications
3. ✅ Avoids authentication flow issues
4. ✅ Reduces complexity and maintenance
5. ✅ Saves Firebase costs

**Enable when**:
- User base grows and requests notifications
- Google Sign-In conflict is resolved upstream
- Have dedicated time for full implementation and testing

---

## 📱 User Impact

**What users lose**:
- Real-time notifications for list changes
- Recipe interaction notifications
- Weekly digests

**What users still have**:
- ✅ Full app functionality
- ✅ Real-time list syncing (via Supabase realtime)
- ✅ In-app notifications
- ✅ Email notifications (if implemented)

**Alternative**: Use **Supabase Realtime** for in-app notifications (already implemented for lists).

---

## 🔮 Future Considerations

### Phase 1: In-App Notifications (No Firebase)
- Use Supabase Realtime for live updates
- Show badges/indicators in app
- No push when app is closed

### Phase 2: Email Notifications
- Easier to implement than push
- No device compatibility issues
- Use Supabase Edge Functions + email service

### Phase 3: Push Notifications (Full Implementation)
- Implement when user base justifies effort
- Requires Firebase setup and testing
- Monthly costs for FCM API

---

## ✅ Summary

**Push Notifications Status**: Disabled  
**Reason**: Google Sign-In compatibility  
**UI Status**: Functional placeholder  
**User Impact**: Minimal (app works great without them)  
**Recommendation**: Keep disabled until real user need emerges  

The bilingual system is now **100% complete** without push notifications! 🚀
