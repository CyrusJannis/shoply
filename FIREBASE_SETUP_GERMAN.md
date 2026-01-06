# 🔥 Firebase Push Notifications Setup - Deutsche Anleitung

**Datum**: 13. November 2025  
**Methode**: FlutterFire CLI (Automatisch & Einfach!)

---

## ✅ VORAUSSETZUNGEN

Bevor du startest, brauchst du:
- ✅ Node.js installiert (für npm)
- ✅ Flutter SDK installiert
- ✅ Xcode installiert (für iOS)
- ✅ Google/Gmail Account für Firebase

---

## 🚀 SCHRITT 1: Firebase CLI installieren (5 Minuten)

### 1.1 Firebase Tools installieren

Öffne Terminal und führe aus:

```bash
npm install -g firebase-tools
```

### 1.2 Bei Firebase anmelden

```bash
firebase login
```

Ein Browser-Fenster öffnet sich:
- Wähle deinen Google Account
- Klicke "Zulassen"
- Du siehst: "✔ Success! Logged in as [deine-email]"

---

## 🔧 SCHRITT 2: FlutterFire CLI installieren (2 Minuten)

### 2.1 FlutterFire CLI global installieren

```bash
dart pub global activate flutterfire_cli
```

### 2.2 Zum PATH hinzufügen (einmalig)

```bash
echo 'export PATH="$PATH:$HOME/.pub-cache/bin"' >> ~/.zshrc
source ~/.zshrc
```

Teste ob es funktioniert:

```bash
flutterfire --version
```

Du solltest eine Versionsnummer sehen (z.B. `1.0.0`).

---

## ⚙️ SCHRITT 3: Firebase für dein Projekt konfigurieren (5 Minuten)

### 3.1 Zum Projekt navigieren

```bash
cd /Users/jannisdietrich/Documents/shoply
```

### 3.2 FlutterFire konfigurieren

```bash
flutterfire configure
```

### 3.3 Interaktive Fragen beantworten

**Frage 1:** "Select a Firebase project to configure your Flutter application with"

```
? Select a Firebase project to configure your Flutter application with
  › ────────────────────────────────────────────────────────────
  ❯ <create a new project>
    my-existing-project (my-existing-project-id)
```

**Option A:** Neues Projekt erstellen
- Wähle `<create a new project>`
- Projekt-ID eingeben: `shoply-app` (oder ein anderer Name)
- Enter drücken

**Option B:** Existierendes Projekt nutzen
- Wähle dein existierendes Projekt mit Pfeiltasten
- Enter drücken

---

**Frage 2:** "Which platforms should your configuration support?"

```
? Which platforms should your configuration support (use arrow keys & space to select)?
  ❯ ◉ android
    ◉ ios
    ◯ macos
    ◯ web
    ◯ windows
    ◯ linux
```

Wähle mit **Leertaste**:
- ☑️ **android** (für später)
- ☑️ **ios**

Drücke **Enter**

---

**Was passiert automatisch:**

```
✔ Firebase project selected.
✔ Registered a new Firebase iOS app.
✔ Firebase configuration file lib/firebase_options.dart generated successfully.
✔ Downloaded iOS configuration files.
✔ Files placed in: ios/Runner/GoogleService-Info.plist
```

✅ **FERTIG!** FlutterFire hat alles konfiguriert!

---

## 📝 SCHRITT 4: Code aktualisieren (2 Minuten)

### 4.1 main.dart Import hinzufügen

Öffne `lib/main.dart` und füge ganz oben hinzu:

```dart
import 'firebase_options.dart';
```

### 4.2 Firebase Initialisierung aktivieren

Suche nach dieser Zeile in `lib/main.dart` (Zeile ~39):

```dart
// options: DefaultFirebaseOptions.currentPlatform,
```

**Entferne die Kommentarzeichen:**

```dart
options: DefaultFirebaseOptions.currentPlatform,
```

Die komplette Initialisierung sollte so aussehen:

```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

Speichern!

---

## 🍎 SCHRITT 5: Apple Push Notifications Key erstellen (10 Minuten)

### 5.1 Apple Developer Portal öffnen

Gehe zu: https://developer.apple.com/account/resources/authkeys/list

### 5.2 Neuen Key erstellen

1. Klicke auf **"+"** (Plus-Symbol)
2. **Key Name**: `Shoply Push Notifications`
3. Aktiviere ☑️ **"Apple Push Notifications service (APNs)"**
4. Klicke **"Continue"**
5. Klicke **"Register"**

### 5.3 Key herunterladen

1. Klicke **"Download"** → Speichere die `.p8` Datei
   - **WICHTIG**: Du kannst diese Datei nur EINMAL herunterladen!
   - Speichere sie sicher!

2. Notiere dir:
   - **Key ID**: (z.B. `ABC123DEFG`) - steht auf der Seite
   - **Team ID**: (z.B. `CTBGYBDPP4`) - oben rechts auf der Seite

---

## 🔥 SCHRITT 6: APNs Key zu Firebase hochladen (3 Minuten)

### 6.1 Firebase Console öffnen

1. Gehe zu: https://console.firebase.google.com/
2. Wähle dein Projekt (`shoply-app` oder wie du es genannt hast)

### 6.2 Cloud Messaging konfigurieren

1. Klicke auf **⚙️ Zahnrad** (oben links) → **"Project settings"**
2. Klicke auf **"Cloud Messaging"** Tab
3. Scrolle zu **"Apple app configuration"**

### 6.3 APNs Key hochladen

1. Klicke **"Upload"** unter "APNs Authentication Key"
2. Wähle die `.p8` Datei die du heruntergeladen hast
3. Gib ein:
   - **Key ID**: (z.B. `ABC123DEFG`)
   - **Team ID**: (z.B. `CTBGYBDPP4`)
4. Klicke **"Upload"**

✅ **Firebase Cloud Messaging ist jetzt aktiviert!**

---

## 📱 SCHRITT 7: Xcode Konfiguration (5 Minuten)

### 7.1 Xcode öffnen

```bash
cd /Users/jannisdietrich/Documents/shoply
open ios/Runner.xcworkspace
```

### 7.2 Push Notifications Capability hinzufügen

1. In Xcode, klicke auf **"Runner"** (blaues Icon ganz oben links)
2. Wähle **"Signing & Capabilities"** Tab
3. Klicke **"+ Capability"**
4. Suche nach **"Push Notifications"**
5. Doppelklick darauf

✅ "Push Notifications" erscheint in der Liste

### 7.3 Background Modes hinzufügen

1. Immer noch in **"Signing & Capabilities"**
2. Klicke wieder **"+ Capability"**
3. Suche nach **"Background Modes"**
4. Doppelklick darauf
5. In der Background Modes Sektion, aktiviere ☑️:
   - **"Remote notifications"**

✅ Xcode ist konfiguriert!

Du kannst Xcode schließen.

---

## 🗄️ SCHRITT 8: Datenbank aktualisieren (2 Minuten)

### 8.1 Supabase SQL Editor öffnen

Gehe zu deinem Supabase Dashboard → **SQL Editor**

### 8.2 SQL ausführen

Kopiere und führe diesen Code aus:

```sql
-- FCM Token Spalte zur users Tabelle hinzufügen
ALTER TABLE users 
  ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- Index für schnellere Suche erstellen
CREATE INDEX IF NOT EXISTS idx_users_fcm_token 
  ON users(fcm_token);
```

Klicke **"Run"**

✅ Datenbank ist bereit!

---

## 📦 SCHRITT 9: Pods installieren (2 Minuten)

```bash
cd /Users/jannisdietrich/Documents/shoply/ios
pod install
```

Du solltest sehen:
```
Installing Firebase...
Installing FirebaseMessaging...
✅ Pod installation complete!
```

---

## 🧪 SCHRITT 10: Testen! (5 Minuten)

### 10.1 App bauen und starten

```bash
cd /Users/jannisdietrich/Documents/shoply
flutter clean
flutter pub get
flutter run
```

### 10.2 Console Logs checken

Suche nach diesen Zeilen in der Console:

```
✅ Firebase Analytics initialized
✅ [FCM] User granted permission
📱 [FCM] Token: eyJhbGc...  [langer String]
✅ [FCM] Token saved to database
✅ [FCM] Initialized successfully
```

### 10.3 FCM Token kopieren

Kopiere den langen Token String der nach `📱 [FCM] Token:` kommt.

### 10.4 Test-Benachrichtigung senden

1. Gehe zu Firebase Console: https://console.firebase.google.com/
2. Wähle dein Projekt
3. **Sidebar** → **Engage** → **Messaging**
4. Klicke **"Create your first campaign"** oder **"New campaign"**
5. Wähle **"Firebase Notification messages"**
6. **Notification title**: `Test Benachrichtigung`
7. **Notification text**: `Hello from Firebase! 🔥`
8. Klicke **"Send test message"**
9. Füge deinen **FCM Token** ein (den langen String)
10. Klicke **"Test"**

🎉 **Du solltest eine Benachrichtigung erhalten!**

---

## ✅ FERTIG! Was funktioniert jetzt?

✅ Push Notifications wenn App **geschlossen** ist  
✅ Push Notifications wenn App im **Hintergrund** ist  
✅ Push Notifications wenn App **offen** ist  
✅ Badge Updates auf App Icon  
✅ Sound & Vibration  
✅ Navigation beim Tap  

---

## 🐛 Probleme? Troubleshooting

### Problem: "Firebase not configured"

**Lösung:**
```bash
cd /Users/jannisdietrich/Documents/shoply
flutterfire configure
```

### Problem: "APNs token not found"

**Lösung:** 
- iOS Einstellungen → Shoply → Benachrichtigungen
- Aktiviere **"Benachrichtigungen zulassen"**

### Problem: "No FCM token"

**Lösung:**
1. Check Apple Developer Portal - APNs Key muss gültig sein
2. Check Firebase Console - .p8 file korrekt hochgeladen?
3. App neu installieren

### Problem: Build-Fehler nach pod install

**Lösung:**
```bash
cd /Users/jannisdietrich/Documents/shoply/ios
rm -rf Pods Podfile.lock
pod install
flutter clean
flutter run
```

---

## 📊 Zeitaufwand

| Schritt | Zeit |
|---------|------|
| Firebase CLI | 5 min |
| FlutterFire CLI | 2 min |
| FlutterFire Config | 5 min |
| Code Update | 2 min |
| Apple APNs Key | 10 min |
| Firebase Upload | 3 min |
| Xcode Config | 5 min |
| Database | 2 min |
| Pods Install | 2 min |
| Testing | 5 min |
| **GESAMT** | **~41 Minuten** |

---

## 🎯 Nächste Schritte

Nach dem Setup kannst du:

1. **Benachrichtigungen programmatisch senden** über Supabase Edge Functions
2. **Benachrichtigungen bei Listen-Updates** automatisch verschicken
3. **Rezept-Benachrichtigungen** implementieren
4. **Benutzerdefinierte Sounds** hinzufügen

---

## 💡 Tipps

✅ **Teste immer auf einem echten Gerät** - Simulator unterstützt keine Push Notifications  
✅ **Sichere deine .p8 Datei** - Du kannst sie nur einmal herunterladen  
✅ **Check Console Logs** - Alle Debug-Infos sind dort  
✅ **Firebase ist kostenlos** für die meisten Apps (bis 200M messages/Monat)

---

Viel Erfolg! 🚀
