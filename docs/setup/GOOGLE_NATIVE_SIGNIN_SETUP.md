# Native Google Sign-In Setup

## Übersicht
Die App verwendet jetzt **nativen Google Sign-In** statt Browser-Redirect. Das bedeutet:
- ✅ Google Login erscheint als natives Popup/Dialog
- ✅ Keine Browser-Weiterleitung mehr
- ✅ Professionellere User Experience
- ✅ Schnellerer Login-Flow

## Setup-Schritte

### 1. Google Client IDs konfigurieren

Du hast **zwei Optionen**:

#### Option A: Über dart-define (Empfohlen)

Starte die App mit:
```bash
flutter run -d macos \
  --dart-define=GOOGLE_CLIENT_ID=YOUR-IOS-CLIENT-ID.apps.googleusercontent.com \
  --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR-WEB-CLIENT-ID.apps.googleusercontent.com
```

#### Option B: In env.dart (falls vorhanden)

Falls du eine `lib/core/config/env.dart` Datei hast:

```dart
class Env {
  static const String googleClientId = 'YOUR-IOS-CLIENT-ID.apps.googleusercontent.com';
  static const String googleWebClientId = 'YOUR-WEB-CLIENT-ID.apps.googleusercontent.com';
}
```

**Wo finde ich die Client IDs?**

1. **Google Cloud Console**: https://console.cloud.google.com/
2. **APIs & Services** → **Credentials**
3. Kopiere:
   - **iOS Client ID** → `GOOGLE_CLIENT_ID`
   - **Web Client ID** → `GOOGLE_WEB_CLIENT_ID`

### 2. Supabase Konfiguration

#### A) Google Provider aktivieren

1. **Supabase Dashboard** → **Authentication** → **Providers**
2. **Google** aktivieren
3. Eintragen:
   - **Client ID**: [Web Client ID]
   - **Client Secret**: [Web Client Secret]
   - **Authorized Client IDs**: [iOS Client ID] (in neue Zeile)

#### B) Skip nonce check (wichtig für native Sign-In!)

In Supabase unter **Google Provider**:
- **Skip nonce check**: ✅ AKTIVIEREN

Das ist wichtig, weil der native Flow anders funktioniert als der Browser-Flow.

### 3. macOS Konfiguration

#### Info.plist bereits konfiguriert ✅

Die `macos/Runner/Info.plist` ist bereits konfiguriert mit:
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

### 4. iOS Konfiguration (für später)

Wenn du die App auf iOS deployen möchtest:

#### Info.plist (`ios/Runner/Info.plist`)

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <!-- Reversed client ID from Google Console -->
      <string>com.googleusercontent.apps.YOUR-CLIENT-ID</string>
    </array>
  </dict>
</array>

<key>GIDClientID</key>
<string>YOUR-IOS-CLIENT-ID.apps.googleusercontent.com</string>
```

### 5. Android Konfiguration (für später)

#### SHA-1 Fingerprint

1. Generieren:
```bash
cd android
./gradlew signingReport
```

2. SHA-1 in Google Cloud Console eintragen:
   - **Credentials** → **Android Client ID**
   - SHA-1 hinzufügen

## Wie es funktioniert

### Vorher (Browser-Flow):
1. User klickt "Continue with Google"
2. Browser öffnet sich
3. Google Login im Browser
4. Redirect zurück zur App
5. App verarbeitet Callback

### Jetzt (Native Flow):
1. User klickt "Continue with Google"
2. **Native Google Sign-In Dialog erscheint**
3. User wählt Account aus
4. **Direkt eingeloggt** - keine Browser-Weiterleitung!

## Vorteile

- ✅ **Bessere UX**: Kein Browser-Wechsel
- ✅ **Schneller**: Direkter Login-Flow
- ✅ **Professioneller**: Wie bei großen Apps (Gmail, YouTube, etc.)
- ✅ **Sicherer**: Native OAuth-Flow
- ✅ **Nahtlos**: Bleibt in der App

## Testen

1. App starten
2. Auf **"Continue with Google"** klicken
3. Native Google Sign-In Dialog sollte erscheinen
4. Account auswählen
5. Automatisch eingeloggt! 🎉

## Troubleshooting

### "Missing Google Auth Token"
- ✅ Client IDs in `env.dart` korrekt?
- ✅ iOS Client ID verwendet (nicht Web Client ID für `googleClientId`)?

### "Invalid Client"
- ✅ OAuth Consent Screen konfiguriert?
- ✅ Client IDs in Supabase eingetragen?
- ✅ "Skip nonce check" aktiviert?

### Dialog erscheint nicht
- ✅ `google_sign_in` Package installiert?
- ✅ App neu gestartet nach env.dart Änderung?

## Wichtig

⚠️ **env.dart nicht committen!**
Die `env.dart` Datei enthält sensible Daten und ist in `.gitignore`.
Verwende `env.example.dart` als Vorlage.

⚠️ **Skip nonce check in Supabase**
Muss aktiviert sein für nativen Google Sign-In!

## Nächste Schritte

1. ✅ Client IDs in `env.dart` eintragen
2. ✅ Supabase Google Provider konfigurieren
3. ✅ "Skip nonce check" aktivieren
4. ✅ App neu starten
5. ✅ Testen!
