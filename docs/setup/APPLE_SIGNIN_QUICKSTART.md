# 🚀 Sign in with Apple - Schnellstart

## ✅ Was bereits fertig ist

- ✅ Code implementiert (`SupabaseService.signInWithApple()`)
- ✅ UI Button vorhanden (Login & Signup Screens)
- ✅ Package installiert (`sign_in_with_apple: ^5.0.0`)
- ✅ Entitlements-Datei erstellt (`ios/Runner/Runner.entitlements`)

## 📋 Was du noch tun musst

### 1. Xcode Konfiguration (5 Minuten)

```bash
cd ios
open Runner.xcworkspace
```

**In Xcode:**
1. Wähle **Runner** Target
2. Tab **Signing & Capabilities**
3. Klicke **+ Capability**
4. Füge **Sign in with Apple** hinzu
5. Fertig! ✅

📖 Detaillierte Anleitung: [APPLE_SIGNIN_XCODE_SETUP.md](APPLE_SIGNIN_XCODE_SETUP.md)

---

### 2. Apple Developer Portal (10 Minuten)

**Benötigt:**
- Apple Developer Account
- Bundle ID: `com.cyrusjannis.shoply`

**Schritte:**
1. ✅ App ID: Sign in with Apple aktivieren
2. ✅ Service ID erstellen: `com.cyrusjannis.shoply.signin`
3. ✅ Private Key (.p8) erstellen und herunterladen
4. ✅ Key ID und Team ID notieren

📖 Detaillierte Anleitung: [APPLE_SIGNIN_SETUP.md](APPLE_SIGNIN_SETUP.md) - Abschnitt 1

---

### 3. Supabase Konfiguration (5 Minuten)

**Im Supabase Dashboard:**
1. Gehe zu **Authentication** → **Providers**
2. Aktiviere **Apple**
3. Trage ein:
   - Services ID: `com.cyrusjannis.shoply.signin`
   - Team ID: `[DEINE_TEAM_ID]`
   - Key ID: `[DEINE_KEY_ID]`
   - Private Key: `[INHALT_DER_P8_DATEI]`
4. Speichern ✅

📖 Detaillierte Anleitung: [APPLE_SIGNIN_SETUP.md](APPLE_SIGNIN_SETUP.md) - Abschnitt 3

---

## 🧪 Testen

```bash
# App neu bauen
flutter clean
flutter pub get
cd ios && pod install && cd ..

# Auf echtem iOS-Gerät starten
flutter run
```

**Im App:**
1. Gehe zum Login-Screen
2. Klicke "Continue with Apple"
3. Melde dich mit deiner Apple ID an
4. Fertig! 🎉

---

## 📊 Checkliste

- [ ] Xcode: Sign in with Apple Capability hinzugefügt
- [ ] Apple Developer: App ID konfiguriert
- [ ] Apple Developer: Service ID erstellt
- [ ] Apple Developer: Private Key heruntergeladen
- [ ] Supabase: Apple Provider konfiguriert
- [ ] App auf echtem Gerät getestet

---

## 🆘 Hilfe benötigt?

### Schnelle Lösungen:

**"Invalid client"**
→ Überprüfe Service ID in Supabase

**"Invalid key"**
→ Überprüfe Private Key (vollständig kopiert?)

**"Operation couldn't be completed"**
→ Stelle sicher, dass Entitlements in Xcode eingebunden sind

📖 Mehr Lösungen: [APPLE_SIGNIN_SETUP.md](APPLE_SIGNIN_SETUP.md) - Abschnitt 5

---

## 📚 Dokumentation

1. **[APPLE_SIGNIN_XCODE_SETUP.md](APPLE_SIGNIN_XCODE_SETUP.md)** - Xcode Konfiguration
2. **[APPLE_SIGNIN_SETUP.md](APPLE_SIGNIN_SETUP.md)** - Vollständige Anleitung
3. **[GOOGLE_SIGNIN_SETUP.md](GOOGLE_SIGNIN_SETUP.md)** - Google Sign-In (bereits konfiguriert)

---

## ⏱️ Geschätzte Zeit

- **Xcode Setup**: 5 Minuten
- **Apple Developer Portal**: 10 Minuten
- **Supabase Konfiguration**: 5 Minuten
- **Testen**: 5 Minuten

**Gesamt: ~25 Minuten** ⏰

---

## 🎯 Nächste Schritte

Nach erfolgreichem Setup:
1. ✅ Sign in with Apple funktioniert
2. ✅ Benutzer können sich mit Apple ID anmelden
3. ✅ E-Mail-Privatsphäre wird unterstützt (Hide My Email)
4. ➡️ App für TestFlight vorbereiten (siehe [TESTFLIGHT_UPLOAD_ANLEITUNG.md](TESTFLIGHT_UPLOAD_ANLEITUNG.md))

---

**Viel Erfolg! 🚀**
