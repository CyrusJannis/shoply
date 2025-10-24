# OAuth Setup - Google & Apple Sign-In

## Übersicht
Die App unterstützt jetzt drei Anmeldemethoden:
1. ✅ **E-Mail/Passwort** (bereits implementiert)
2. ✅ **Google Sign-In** (Gmail)
3. ✅ **Apple Sign-In** (Apple ID)

## 1. Supabase OAuth Konfiguration

### Google OAuth Setup

1. **Google Cloud Console öffnen**: https://console.cloud.google.com/
2. **Projekt erstellen** oder bestehendes auswählen
3. **APIs & Services** → **Credentials**
4. **OAuth 2.0 Client IDs** erstellen:
   - **Web Application** (für Supabase)
   - **iOS** (für iOS App)
   - **Android** (für Android App)

#### Authorized redirect URIs (Web):
```
https://[YOUR-PROJECT-REF].supabase.co/auth/v1/callback
```

5. **Client ID** und **Client Secret** kopieren

### Apple OAuth Setup

1. **Apple Developer Account**: https://developer.apple.com/
2. **Certificates, Identifiers & Profiles** → **Identifiers**
3. **App ID** erstellen mit **Sign in with Apple** Capability
4. **Services ID** erstellen:
   - Identifier: `com.shoply.app.signin`
   - **Sign in with Apple** aktivieren
   - **Configure** klicken
   - **Primary App ID** auswählen
   - **Domains and Subdomains**: `[YOUR-PROJECT-REF].supabase.co`
   - **Return URLs**: `https://[YOUR-PROJECT-REF].supabase.co/auth/v1/callback`

5. **Key** erstellen:
   - **Sign in with Apple** aktivieren
   - **Key ID** und **.p8 Datei** herunterladen

### Supabase Dashboard Konfiguration

1. **Supabase Dashboard** öffnen: https://app.supabase.com/
2. **Authentication** → **Providers**

#### Google Provider aktivieren:
- **Enabled**: ON
- **Client ID**: [Deine Google Client ID]
- **Client Secret**: [Dein Google Client Secret]
- **Authorized Client IDs**: [iOS und Android Client IDs hinzufügen]

#### Apple Provider aktivieren:
- **Enabled**: ON
- **Services ID**: `com.shoply.app.signin`
- **Team ID**: [Deine Apple Team ID]
- **Key ID**: [Deine Apple Key ID]
- **Private Key**: [Inhalt der .p8 Datei]

## 2. iOS Konfiguration

### Info.plist (`ios/Runner/Info.plist`)

```xml
<!-- Google Sign-In -->
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.[YOUR-CLIENT-ID]</string>
    </array>
  </dict>
</array>

<!-- Apple Sign-In -->
<key>CFBundleIdentifier</key>
<string>com.shoply.app</string>
```

### Capabilities
In Xcode:
1. **Signing & Capabilities** Tab öffnen
2. **+ Capability** klicken
3. **Sign in with Apple** hinzufügen

## 3. Android Konfiguration

### build.gradle (`android/app/build.gradle`)

```gradle
android {
    defaultConfig {
        applicationId "com.shoply.app"
        // ...
    }
}
```

### AndroidManifest.xml (`android/app/src/main/AndroidManifest.xml`)

```xml
<!-- Google Sign-In -->
<application>
    <meta-data
        android:name="com.google.android.gms.version"
        android:value="@integer/google_play_services_version" />
</application>
```

### SHA-1 Fingerprint hinzufügen

1. SHA-1 generieren:
```bash
cd android
./gradlew signingReport
```

2. SHA-1 in Google Cloud Console hinzufügen:
   - **Credentials** → **OAuth 2.0 Client IDs** → **Android**
   - SHA-1 eintragen

## 4. macOS Konfiguration

### Entitlements (`macos/Runner/DebugProfile.entitlements` & `Release.entitlements`)

```xml
<!-- Apple Sign-In -->
<key>com.apple.developer.applesignin</key>
<array>
    <string>Default</string>
</array>

<!-- Keychain Access -->
<key>keychain-access-groups</key>
<array>
    <string>$(AppIdentifierPrefix)com.shoply.app</string>
</array>
```

### Info.plist (`macos/Runner/Info.plist`)

```xml
<!-- Google Sign-In -->
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.[YOUR-CLIENT-ID]</string>
    </array>
  </dict>
</array>
```

## 5. Testen

### Login Screen
1. App starten
2. Du siehst drei Optionen:
   - **E-Mail/Passwort Felder**
   - **"Continue with Google"** Button (weiß mit Google Logo)
   - **"Continue with Apple"** Button (schwarz mit Apple Logo)

### Signup Screen
Gleiche Optionen wie Login Screen

### Funktionsweise
- **Google**: Öffnet Browser → Google Login → Zurück zur App
- **Apple**: Native Apple Sign-In Dialog → Zurück zur App
- **E-Mail**: Direkt in der App

## 6. Datenbank

User-Profile werden automatisch erstellt in der `users` Tabelle:
- **email**: E-Mail des Users
- **display_name**: Name (von OAuth Provider oder E-Mail)
- **auth_provider**: `email`, `google`, oder `apple`
- **created_at**: Erstellungsdatum
- **updated_at**: Update-Datum

## 7. Troubleshooting

### Google Sign-In funktioniert nicht
- SHA-1 Fingerprint korrekt in Google Console?
- Client IDs in Supabase korrekt?
- Redirect URI korrekt konfiguriert?

### Apple Sign-In funktioniert nicht
- Services ID korrekt konfiguriert?
- Return URL korrekt?
- Capabilities in Xcode aktiviert?

### OAuth Redirect funktioniert nicht
- Deep Links korrekt konfiguriert?
- Supabase Redirect URL korrekt?

## 8. Sicherheit

- ✅ OAuth Tokens werden von Supabase verwaltet
- ✅ Keine Passwörter in der App gespeichert
- ✅ Sichere Token-Verwaltung durch Supabase
- ✅ Automatische Token-Erneuerung

## Nächste Schritte

1. **Supabase OAuth Provider konfigurieren**
2. **Google Cloud Console einrichten**
3. **Apple Developer Account einrichten**
4. **iOS/Android Konfiguration anpassen**
5. **Testen!**
