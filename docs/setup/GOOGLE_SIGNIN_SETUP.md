# Google Sign-In Setup für iOS & Android

## Übersicht
Natives Google Sign-In ist jetzt implementiert. Die Anmeldung erfolgt **in der App** ohne Browser.

## 1. Google Cloud Console Setup

### A. Projekt erstellen/auswählen
1. Gehe zu [Google Cloud Console](https://console.cloud.google.com/)
2. Wähle dein Projekt oder erstelle ein neues

### B. OAuth Consent Screen konfigurieren
1. **APIs & Services** → **OAuth consent screen**
2. Wähle **External** (für öffentliche App)
3. Fülle die erforderlichen Felder aus:
   - App name: `ShoplyAI`
   - User support email: Deine E-Mail
   - Developer contact: Deine E-Mail
4. Klicke **Save and Continue**
5. Scopes: Keine zusätzlichen Scopes nötig (nur basic profile)
6. Test users: Optional, füge Test-E-Mails hinzu
7. **Save and Continue** → **Back to Dashboard**

### C. OAuth 2.0 Client IDs erstellen

#### iOS Client ID
1. **APIs & Services** → **Credentials** → **Create Credentials** → **OAuth client ID**
2. Application type: **iOS**
3. Name: `ShoplyAI iOS`
4. Bundle ID: `com.shoply.app` (aus deiner Info.plist)
5. **Create**
6. **Kopiere die Client ID** (Format: `xxx.apps.googleusercontent.com`)

#### Web Client ID (für iOS benötigt)
1. **Create Credentials** → **OAuth client ID**
2. Application type: **Web application**
3. Name: `ShoplyAI Web`
4. Authorized redirect URIs: 
   - `https://YOUR-PROJECT.supabase.co/auth/v1/callback`
5. **Create**
6. **Kopiere die Client ID**

#### Android Client ID
1. **Create Credentials** → **OAuth client ID**
2. Application type: **Android**
3. Name: `ShoplyAI Android`
4. Package name: `com.shoply.app`
5. SHA-1 certificate fingerprint:
   ```bash
   # Debug Keystore
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   
   # Release Keystore (später)
   keytool -list -v -keystore /path/to/your/release.keystore -alias your-key-alias
   ```
6. **Create**

## 2. Supabase Konfiguration

1. Gehe zu [Supabase Dashboard](https://app.supabase.com)
2. Wähle dein Projekt
3. **Authentication** → **Providers** → **Google**
4. Enable Google Provider
5. Füge ein:
   - **Client ID**: Die Web Client ID von oben
   - **Client Secret**: Das Secret der Web Client ID
6. **Save**

## 3. App Konfiguration

### A. env.dart aktualisieren
```dart
class Env {
  static const String supabaseUrl = 'YOUR-SUPABASE-URL';
  static const String supabaseAnonKey = 'YOUR-SUPABASE-ANON-KEY';
  
  // iOS Web Client ID (wichtig!)
  static const String googleClientId = 'YOUR-WEB-CLIENT-ID.apps.googleusercontent.com';
}
```

### B. iOS Konfiguration

1. Öffne `ios/Runner/Info.plist`
2. Füge hinzu (vor `</dict>`):
```xml
<!-- Google Sign-In -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <!-- Reversed iOS Client ID -->
            <string>com.googleusercontent.apps.YOUR-IOS-CLIENT-ID</string>
        </array>
    </dict>
</array>
<key>GIDClientID</key>
<string>YOUR-IOS-CLIENT-ID.apps.googleusercontent.com</string>
```

**Wichtig:** Ersetze `YOUR-IOS-CLIENT-ID` mit deiner iOS Client ID (nur die Nummer vor `.apps.googleusercontent.com`)

### C. Android Konfiguration

Keine zusätzliche Konfiguration nötig! Das Package verwendet automatisch die SHA-1 Fingerprints.

## 4. Testen

### Debug Build
```bash
# iOS
flutter run -d ios

# Android
flutter run -d android
```

1. Klicke auf "Continue with Google"
2. Wähle dein Google-Konto
3. Erlaube den Zugriff
4. Du wirst automatisch eingeloggt

### Troubleshooting

#### iOS: "Sign in with Google temporarily disabled"
- Prüfe, ob die `GIDClientID` in Info.plist korrekt ist
- Prüfe, ob der URL Scheme korrekt ist (reversed client ID)
- Stelle sicher, dass du die **Web Client ID** in `env.dart` verwendest

#### Android: "Developer Error" oder "Sign in failed"
- Prüfe SHA-1 Fingerprint in Google Console
- Stelle sicher, dass Package Name übereinstimmt
- Für Release Build: Füge Release SHA-1 hinzu

#### "Invalid ID Token"
- Stelle sicher, dass die Web Client ID in Supabase konfiguriert ist
- Prüfe, ob die Client ID in `env.dart` korrekt ist

## 5. Production Release

### iOS
1. Keine zusätzlichen Schritte nötig
2. Die gleiche Konfiguration funktioniert für Release

### Android
1. Erstelle Release Keystore
2. Generiere SHA-1 für Release Keystore
3. Füge Release SHA-1 in Google Console hinzu (zusätzlich zum Debug SHA-1)

## Fertig! 🎉

Natives Google Sign-In ist jetzt vollständig integriert und funktioniert **in der App** ohne Browser-Umleitung.
