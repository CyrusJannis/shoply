# 🚀 Quick Start - Premium Subscriptions

**Ziel:** Premium Subscriptions in 30 Minuten live testen

---

## ⚡ Step 1: Deploy SQL Functions (5 Minuten)

### Option A: Automatisch (empfohlen)
```bash
cd /Users/jannisdietrich/Documents/shoply
./deploy_subscription_system.sh
```

### Option B: Manuell
1. Gehe zu: https://supabase.com/dashboard/project/rtwzzerhgieyxsijemsd/sql/new
2. Öffne: `database/migrations/premium_subscription_system.sql`
3. Kopiere den kompletten Inhalt
4. Paste in Supabase SQL Editor
5. Klicke **"Run"**

### Verify:
```sql
-- In Supabase SQL Editor ausführen:
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_name IN ('activate_subscription', 'activate_trial', 'is_premium_user');
```

Erwartetes Ergebnis: 3 Zeilen
- ✅ `activate_subscription`
- ✅ `activate_trial`
- ✅ `is_premium_user`

---

## ⚡ Step 2: Build & Upload to TestFlight (15 Minuten)

```bash
# Clean everything
cd /Users/jannisdietrich/Documents/shoply
flutter clean
rm -rf ~/Library/Developer/Xcode/DerivedData

# Install dependencies
flutter pub get
cd ios && pod install && cd ..

# Open Xcode
open ios/Runner.xcworkspace
```

### In Xcode:
1. **Wähle Target:** Runner
2. **Signing & Capabilities:**
   - ✅ Team selected
   - ✅ Bundle ID: com.dominik.shoply
   - ✅ Add "In-App Purchase" capability (falls nicht vorhanden)
3. **General Tab:**
   - Version: 1.1.0 (oder höher)
   - Build: Erhöhe um 1
4. **Wähle Device:** "Any iOS Device (arm64)"
5. **Product > Clean Build Folder** (⇧⌘K)
6. **Product > Archive**
7. Warte 5-10 Minuten...
8. **Organizer öffnet sich**
9. **Distribute App**
10. **App Store Connect** > **Upload**
11. **Automatic Signing**
12. **Upload**

### In App Store Connect:
1. Gehe zu: https://appstoreconnect.apple.com/apps
2. **TestFlight** Tab
3. Warte bis Build **"Ready to Submit"** (5-15 Minuten)
4. Klicke auf deinen **neuen Build**
5. **In-App Purchases** Section
6. Klicke **+ oder Edit**
7. Wähle BEIDE Subscriptions:
   - ✅ shoply_premium_monthly
   - ✅ shoply_premium_yearly
8. **Save**

---

## ⚡ Step 3: Test with Sandbox (10 Minuten)

### Create Sandbox Tester:
1. App Store Connect > **Users and Access**
2. **Sandbox** > **Testers**
3. **+ Add**
4. Email: `test1@example.com` (kann fake sein)
5. Passwort: `Test1234!`
6. Land: Deutschland
7. **Create**

### Test on Device:
1. **iOS Settings** > **App Store**
2. Scrolle runter zu **Sandbox Account**
3. Melde dich an mit `test1@example.com`
4. **Installiere App** über TestFlight
5. **Öffne App**
6. **Gehe zu AI Dashboard**
7. **Tippe auf "AI Meal Planning"** (locked)
8. **Paywall erscheint**
9. **Wähle Monthly** ($2.99)
10. **Start 14-Day Free Trial**
11. **Bestätige mit Face ID** (KOSTENLOS in Sandbox!)
12. ✅ **Feature ist unlocked!**

### Verify in Supabase:
1. Gehe zu: https://supabase.com/dashboard/project/rtwzzerhgieyxsijemsd/editor
2. Öffne **users** Tabelle
3. Finde deinen Test-User
4. Prüfe Felder:
   - `subscription_tier`: "premium_monthly"
   - `subscription_status`: "trial" oder "active"
   - `subscription_expires_at`: Datum in Zukunft
   - `trial_ends_at`: ~14 Tage in Zukunft

---

## ✅ Success Criteria

Nach Step 3 solltest du:
- ✅ Premium Paywall sehen können
- ✅ Sandbox-Kauf durchführen können (kostenlos)
- ✅ Premium Features unlocked sehen
- ✅ Supabase zeigt Premium-Status
- ✅ Nach App-Restart: Premium bleibt aktiv

---

## 🆘 Troubleshooting

### "Product not found"
**Lösung:** 
- Warte 24h nach Product-Creation in App Store Connect
- Stelle sicher Product IDs matchen: `shoply_premium_monthly`

### "No Sandbox Account"
**Lösung:**
- Settings > App Store > Sign Out
- Sign In mit Sandbox-Account

### "Purchase failed"
**Lösung:**
- Prüfe Internet-Verbindung
- Prüfe Sandbox-Account ist valide
- Teste auf echtem Gerät (nicht Simulator)

### "Functions not found in Supabase"
**Lösung:**
```bash
# Run deployment script again
./deploy_subscription_system.sh
```

### "Paywall doesn't show"
**Check:**
```dart
// In ai_dashboard_screen.dart
FeatureGate.premiumOverlay(
  child: ...,
  onTap: () async {
    await FeatureGate.checkAccess(context, featureName: 'AI Meal Planning');
  },
)
```

---

## 📊 Test Checklist

After completing all steps:
- [ ] SQL Functions deployed (verify in Supabase)
- [ ] App built and uploaded to TestFlight
- [ ] Subscriptions linked to TestFlight build
- [ ] Sandbox account created
- [ ] Purchase flow works (kostenlos!)
- [ ] Premium features unlock
- [ ] Supabase shows correct subscription status
- [ ] App restart: Premium persists
- [ ] "Restore Purchases" works

---

## 🎉 Next Steps

After successful testing:
1. **Invite Beta Testers** (TestFlight > External Testing)
2. **Add more Premium Features** (see PREMIUM_CHECKLIST.md)
3. **Monitor Conversions** (Firebase Analytics)
4. **Submit to App Review**

---

## 📞 Quick Links

- **Supabase SQL Editor:** https://supabase.com/dashboard/project/rtwzzerhgieyxsijemsd/sql/new
- **App Store Connect:** https://appstoreconnect.apple.com/apps
- **TestFlight:** https://appstoreconnect.apple.com/apps/[your-app]/testflight
- **Sandbox Testers:** https://appstoreconnect.apple.com/access/testers

---

**Estimated Time:** 30 Minuten  
**Difficulty:** Medium  
**Prerequisites:** Xcode installed, Apple Developer Account, Supabase access

Good luck! 🚀
