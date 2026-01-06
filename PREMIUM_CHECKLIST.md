# 🎯 Premium Subscription - Complete Checklist

**Status:** 5. November 2025  
**Ziel:** Premium Subscriptions via TestFlight testen und live schalten

---

## ✅ ALREADY DONE

### 1. Backend Infrastructure
- ✅ SQL Migration erstellt (`database/migrations/premium_subscription_system.sql`)
- ✅ `users` Tabelle mit Subscription-Feldern
- ✅ `subscription_transactions` Tabelle
- ✅ SQL Functions: `is_premium_user()`, `activate_trial()`, `activate_subscription()`
- ✅ Edge Function für tägliches Expiry (`supabase/functions/expire-subscriptions/`)
- ✅ Cron-Job auf cron-job.org konfiguriert (läuft täglich)

### 2. Flutter App Code
- ✅ `SubscriptionService` vollständig implementiert (398 Zeilen)
- ✅ Product IDs definiert: `shoply_premium_monthly`, `shoply_premium_yearly`
- ✅ `PaywallModal` erstellt (413 Zeilen)
- ✅ `FeatureGate` Utility (149 Zeilen)
- ✅ AI Dashboard mit Premium-Overlays
- ✅ Apple IAP → Supabase Verbindung implementiert
- ✅ `in_app_purchase` Package in pubspec.yaml

### 3. App Store Connect
- ✅ Subscription Products erstellt
- ✅ Product IDs: `shoply_premium_monthly`, `shoply_premium_yearly`
- ✅ Preise: $2.99/month, $29.99/year
- ✅ 14-day free trial konfiguriert
- ✅ Screenshots hochgeladen
- ✅ Beschreibungen ausgefüllt
- ✅ Status: "Ready to Submit"

---

## ⚠️ TO DO - CRITICAL (Before Testing)

### 1. Deploy SQL Migration to Supabase
**Status:** ❌ NICHT DEPLOYED (Functions existieren nicht in Supabase)

**Action:**
```bash
# Gehe zu Supabase Dashboard
# https://supabase.com/dashboard/project/rtwzzerhgieyxsijemsd/sql/new

# Führe diese Datei aus:
/Users/jannisdietrich/Documents/shoply/database/migrations/premium_subscription_system.sql
```

**Oder via CLI:**
```bash
supabase db push
```

**Verify:**
```sql
-- In Supabase SQL Editor ausführen
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_name IN ('activate_subscription', 'activate_trial', 'is_premium_user');
```

Erwartetes Ergebnis: 3 Zeilen

---

### 2. Initialize SubscriptionService in App
**Status:** ⚠️ Service wird nie initialisiert

**Problem:** Der `SubscriptionService` muss beim App-Start initialisiert werden, um Purchase-Updates zu empfangen.

**Fix:** In `lib/main.dart` hinzufügen:

```dart
import 'package:shoply/data/services/subscription_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  
  // 🆕 FÜGE DIES HINZU:
  final subscriptionService = SubscriptionService();
  await subscriptionService.initialize();
  
  runApp(const MyApp());
}
```

**Location:** `/Users/jannisdietrich/Documents/shoply/lib/main.dart`

---

### 3. Add In-App Purchase Capability in Xcode
**Status:** ❓ UNBEKANNT (muss geprüft werden)

**Action:**
1. Öffne `ios/Runner.xcworkspace` in Xcode
2. Wähle **Runner** Target
3. **Signing & Capabilities** Tab
4. Prüfe ob **"In-App Purchase"** vorhanden ist
5. Falls nicht: Klicke **+ Capability** → Suche **"In-App Purchase"** → Hinzufügen

---

### 4. Test-Account in App Store Connect Sandbox
**Status:** ❓ UNBEKANNT

**Action:**
1. Gehe zu App Store Connect
2. **Users and Access** > **Sandbox** > **Testers**
3. Erstelle mindestens 2 Test-Accounts:
   - test1@example.com
   - test2@example.com
4. Notiere Passwörter

---

## 📱 TO DO - Testing Phase

### 5. Build & Upload to TestFlight

**Steps:**
```bash
# 1. Clean
cd /Users/jannisdietrich/Documents/shoply
flutter clean
rm -rf ~/Library/Developer/Xcode/DerivedData

# 2. Get dependencies
flutter pub get
cd ios && pod install && cd ..

# 3. Open Xcode
open ios/Runner.xcworkspace
```

**In Xcode:**
1. Product > Clean Build Folder (⇧⌘K)
2. Wähle "Any iOS Device (arm64)"
3. Product > Archive
4. Distribute App > App Store Connect > Upload
5. Warte 5-15 Minuten auf Processing

**In App Store Connect:**
1. TestFlight Tab
2. Warte bis Build "Ready to Submit"
3. Klicke auf Build
4. **In-App Purchases** Section
5. Wähle beide Subscriptions:
   - ✅ shoply_premium_monthly
   - ✅ shoply_premium_yearly
6. Save

---

### 6. Test Purchase Flow with Sandbox

**On iOS Device:**
1. Settings > App Store > Sandbox Account
2. Sign in mit Sandbox-Account (test1@example.com)
3. Installiere App über TestFlight
4. Öffne AI Dashboard
5. Tippe auf "AI Meal Planning" (locked)
6. Paywall erscheint
7. Wähle Monthly oder Yearly
8. Klicke "Start 14-Day Free Trial"
9. Bestätige mit Face ID/Touch ID
10. ✅ Sandbox-Kauf ist KOSTENLOS!

**Verify in Supabase:**
```sql
-- In Supabase SQL Editor
SELECT 
  id,
  email,
  subscription_tier,
  subscription_status,
  subscription_expires_at,
  trial_ends_at
FROM users
WHERE email = 'deine-test-email@example.com';
```

Erwartetes Ergebnis:
- `subscription_tier`: "premium_monthly" oder "premium_yearly"
- `subscription_status`: "trial" oder "active"
- `subscription_expires_at`: Datum in 14 oder 30/365 Tagen

---

### 7. Test Premium Features

**After Purchase:**
1. ✅ AI Meal Planning unlocked (kein Overlay mehr)
2. ✅ Nutrition Insights accessible
3. ✅ Check Supabase: `is_premium_user(user_uuid)` returns TRUE
4. ✅ Restart App: Premium Status bleibt erhalten

**Test Restore:**
1. Lösche App
2. Installiere neu über TestFlight
3. Gehe zu AI Dashboard
4. Tippe locked feature
5. Paywall > "Restore Purchases"
6. ✅ Premium wird wiederhergestellt

---

### 8. Test Subscription Expiry

**Manual Test:**
```sql
-- In Supabase SQL Editor
-- Setze Expiry auf gestern
UPDATE users 
SET subscription_expires_at = NOW() - INTERVAL '1 day'
WHERE email = 'deine-test-email@example.com';
```

**Then:**
1. Restart App
2. ✅ Premium Features sollten wieder locked sein
3. ✅ Paywall erscheint wieder

**Run Cron Job Manually:**
```bash
curl -X POST "https://rtwzzerhgieyxsijemsd.supabase.co/functions/v1/expire-subscriptions" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ0d3p6ZXJoZ2lleXhzaWplbXNkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA1MDAyOTgsImV4cCI6MjA3NjA3NjI5OH0.modgHtr0QcRd6TTm0-R4eqwynb_jvGYpz-pBmvO6OmA"
```

Check:
```sql
SELECT subscription_status FROM users WHERE email = 'test@example.com';
-- Should be 'expired'
```

---

## 🎯 TO DO - Production Ready

### 9. Add More Premium Features

**Current:** Nur AI Dashboard ist premium-gated

**Recommendations:**
```dart
// 1. Recipes - Limit to 10 for free users
if (!await FeatureGate.isPremium() && recipes.length >= 10) {
  await FeatureGate.checkAccess(context, featureName: 'Unlimited Recipes');
  return;
}

// 2. List Sharing - Limit to 1 shared list
if (!await FeatureGate.isPremium() && sharedLists.length >= 1) {
  await FeatureGate.checkAccess(context, featureName: 'Unlimited Sharing');
  return;
}

// 3. Shopping History
if (!await FeatureGate.isPremium()) {
  await FeatureGate.checkAccess(context, featureName: 'Shopping History');
  return;
}

// 4. Advanced Analytics
FeatureGate.premiumOverlay(
  child: AdvancedAnalyticsWidget(),
  onTap: () => FeatureGate.checkAccess(context, featureName: 'Analytics'),
)
```

---

### 10. Add Subscription Management Screen

**Create:** `lib/presentation/screens/profile/subscription_screen.dart`

**Features:**
- Show current subscription tier
- Show expiry date
- "Cancel Subscription" button (deep link to App Store)
- "Upgrade/Downgrade" options
- Transaction history

---

### 11. Analytics & Monitoring

**Track:**
- Paywall impressions
- Conversion rate (paywall → purchase)
- Trial → Paid conversion
- Churn rate

**Tools:**
- Firebase Analytics (already integrated)
- Custom Supabase queries

---

### 12. Apple Server Notifications (Optional but Recommended)

**Why:** Real-time updates when subscriptions:
- Renew
- Cancel
- Expire
- Refund

**Setup:**
1. Create Supabase Edge Function for Apple webhooks
2. Configure in App Store Connect
3. Verify webhook signatures
4. Update `users` table automatically

**Priority:** MEDIUM (can be done after launch)

---

## 📊 Success Criteria

### Before Launch:
- [ ] SQL Functions deployed in Supabase
- [ ] SubscriptionService initialized in app
- [ ] In-App Purchase capability added in Xcode
- [ ] TestFlight build uploaded with subscriptions
- [ ] Sandbox test: Purchase works
- [ ] Sandbox test: Premium features unlock
- [ ] Sandbox test: Restore purchases works
- [ ] Sandbox test: Expiry works
- [ ] At least 3 beta testers tested successfully

### After Launch:
- [ ] 10+ premium subscribers
- [ ] <5% subscription errors
- [ ] Daily cron job running reliably
- [ ] Revenue tracking in App Store Connect

---

## 🚨 Known Issues

### 1. Sandbox Subscriptions Renew Faster
- Real monthly = 5 minutes in sandbox
- Real yearly = 1 hour in sandbox
- Don't worry - this is normal Apple behavior

### 2. First Purchase May Fail in Simulator
- Always test on real device
- Simulator can't complete IAP

### 3. Receipt Validation
- Currently: Basic validation
- Production: Consider RevenueCat or Apple receipt validation API

---

## 📞 Support Resources

### Documentation:
- Apple: https://developer.apple.com/in-app-purchase/
- Flutter IAP: https://pub.dev/packages/in_app_purchase
- Supabase: https://supabase.com/docs

### Debugging:
```dart
// Enable debug logs
if (kDebugMode) {
  print('🔵 Subscription Service Debug');
}
```

### Common Errors:
- "Product not found": Check Product IDs match exactly
- "Network error": Check Supabase connection
- "Purchase failed": Check Sandbox account signed in

---

## ✅ Quick Start Commands

```bash
# 1. Deploy SQL
# Copy content from database/migrations/premium_subscription_system.sql
# Paste in Supabase SQL Editor
# Click "Run"

# 2. Test cron job
curl -X POST "https://rtwzzerhgieyxsijemsd.supabase.co/functions/v1/expire-subscriptions" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ0d3p6ZXJoZ2lleXhzaWplbXNkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA1MDAyOTgsImV4cCI6MjA3NjA3NjI5OH0.modgHtr0QcRd6TTm0-R4eqwynb_jvGYpz-pBmvO6OmA"

# 3. Check functions exist
# In Supabase SQL Editor:
SELECT routine_name FROM information_schema.routines 
WHERE routine_name IN ('activate_subscription', 'activate_trial', 'is_premium_user');

# 4. Build for TestFlight
flutter clean
cd ios && pod install && cd ..
open ios/Runner.xcworkspace
# Then: Product > Archive
```

---

**Last Updated:** 5. November 2025  
**Next Review:** Nach TestFlight Upload
