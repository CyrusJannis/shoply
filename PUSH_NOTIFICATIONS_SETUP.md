# 🔔 Push Notifications Setup Guide

## ✅ Was bereits funktioniert:
- ✅ Push Notifications von Firebase Console → App funktionieren!
- ✅ APNs Production Key ist korrekt konfiguriert
- ✅ iOS Entitlements sind richtig gesetzt (`production`)
- ✅ FCM Tokens werden gespeichert

## ⚠️ Was noch fehlt:

### **User-to-User Push Notifications**

Aktuell werden Notifications nur **lokal** angezeigt (auf dem eigenen Device).

Für Push Notifications **an andere User** brauchen wir eine **Backend-Lösung**!

---

## 🚀 Lösung: Supabase Edge Function

### **1. Deploy Edge Function**

```bash
cd /Users/jannisdietrich/Documents/shoply

# Install Supabase CLI if not installed
# brew install supabase/tap/supabase

# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref YOUR_PROJECT_REF

# Deploy the function
supabase functions deploy send-push-notification
```

### **2. Set Environment Variables**

Du brauchst einen **Firebase Service Account Key**:

1. **Firebase Console** → **Project Settings** → **Service Accounts**
2. Click **"Generate new private key"**
3. Download die JSON-Datei

Dann in Supabase:

```bash
# Extract from the JSON file
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----"
FIREBASE_CLIENT_EMAIL="firebase-adminsdk-xxxxx@shoplyai-1554e.iam.gserviceaccount.com"

# Set in Supabase
supabase secrets set FIREBASE_PRIVATE_KEY="$FIREBASE_PRIVATE_KEY"
supabase secrets set FIREBASE_CLIENT_EMAIL="$FIREBASE_CLIENT_EMAIL"
```

### **3. Test the Function**

```bash
curl -X POST \
  'https://YOUR_PROJECT_REF.supabase.co/functions/v1/send-push-notification' \
  -H 'Authorization: Bearer YOUR_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "token": "FCM_TOKEN_HERE",
    "notification": {
      "title": "Test",
      "body": "This is a test notification"
    },
    "data": {
      "type": "test"
    }
  }'
```

---

## 📱 Wie es funktioniert:

### **Aktueller Flow:**

1. User A fügt Item zur Liste hinzu
2. `item_repository.dart` → `_sendListUpdateNotifications()`
3. Holt FCM Token von User B aus Supabase
4. Ruft Edge Function `send-push-notification` auf
5. Edge Function sendet Push via Firebase Cloud Messaging
6. User B bekommt Push Notification!

---

## 🔧 Alternative: Einfachere Lösung ohne Edge Function

Wenn du **keine Edge Function** deployen willst:

### **Option A: Supabase Realtime + Local Notifications**

Nutze Supabase Realtime um andere Clients zu benachrichtigen:

```dart
// In item_repository.dart
_supabase.from('notifications').insert({
  'user_id': memberId,
  'title': listName,
  'body': '$adderName added "$itemName"',
  'data': {'type': 'list_update', 'listId': listId},
  'created_at': DateTime.now().toIso8601String(),
});

// In FCMService - subscribe to notifications table
_supabase
  .from('notifications')
  .stream(primaryKey: ['id'])
  .eq('user_id', currentUserId)
  .listen((data) {
    // Show local notification when new row inserted
    NotificationService.instance.showNotification(...);
  });
```

### **Option B: Custom Backend mit Cloud Functions**

Erstelle eine Cloud Function die FCM Notifications sendet.

---

## 📋 Status:

- ✅ Firebase → iOS Push Notifications: **FUNKTIONIERT**
- ⚠️ User → User Push Notifications: **BRAUCHT EDGE FUNCTION**
- ✅ Code ist vorbereitet: `item_repository.dart` Zeile 387-400
- ⚠️ Edge Function muss deployed werden

---

## 🎯 Nächste Schritte:

1. **Deploy Edge Function** (siehe oben)
2. **Test mit 2 Devices**:
   - Device A: Item hinzufügen
   - Device B: Sollte Push Notification bekommen
3. **Verify in Logs**:
   ```bash
   supabase functions logs send-push-notification
   ```

---

## 💡 Tipp:

Für Testing kannst du erstmal **Option A** (Realtime + Local Notifications) nutzen.
Das funktioniert **ohne Backend**, aber nur wenn die App **im Hintergrund läuft**.

Für echte Push Notifications (auch wenn App geschlossen ist) brauchst du die Edge Function!
