# 🍎 Sign in with Apple Setup für Shoply

Diese Anleitung zeigt dir, wie du Sign in with Apple in deiner Shoply-App einrichtest.

## 📋 Voraussetzungen

- Apple Developer Account
- Xcode installiert
- Bundle ID: `com.cyrusjannis.shoply` (oder deine eigene)

---

## 1️⃣ Apple Developer Portal Konfiguration

### Schritt 1: App ID konfigurieren

1. Gehe zu [Apple Developer Portal](https://developer.apple.com/account/)
2. Navigiere zu **Certificates, Identifiers & Profiles**
3. Wähle **Identifiers** → **App IDs**
4. Suche deine App ID (`com.cyrusjannis.shoply`)
5. Klicke auf **Edit** oder **Configure**
6. Aktiviere **Sign in with Apple** Capability
7. Klicke auf **Save**

### Schritt 2: Service ID erstellen (für Supabase)

1. Gehe zu **Identifiers** → **Services IDs**
2. Klicke auf das **+** Symbol
3. Wähle **Services IDs** und klicke **Continue**
4. Fülle aus:
   - **Description**: `Shoply Sign in with Apple`
   - **Identifier**: `com.cyrusjannis.shoply.signin` (muss eindeutig sein)
5. Klicke **Continue** → **Register**

### Schritt 3: Service ID konfigurieren

1. Wähle die gerade erstellte Service ID
2. Aktiviere **Sign in with Apple**
3. Klicke auf **Configure**
4. Füge folgende Domains und Return URLs hinzu:
   - **Domains**: `<your-project-ref>.supabase.co`
   - **Return URLs**: `https://<your-project-ref>.supabase.co/auth/v1/callback`
   
   Beispiel:
   - Domain: `abcdefghijklmn.supabase.co`
   - Return URL: `https://abcdefghijklmn.supabase.co/auth/v1/callback`

5. Klicke **Save** → **Continue** → **Save**

### Schritt 4: Private Key erstellen

1. Gehe zu **Keys** im Apple Developer Portal
2. Klicke auf das **+** Symbol
3. Gib einen Namen ein: `Shoply Sign in with Apple Key`
4. Aktiviere **Sign in with Apple**
5. Klicke auf **Configure** neben "Sign in with Apple"
6. Wähle deine **Primary App ID** (`com.cyrusjannis.shoply`)
7. Klicke **Save** → **Continue** → **Register**
8. **WICHTIG**: Lade die `.p8` Datei herunter (nur einmal möglich!)
9. Notiere dir:
   - **Key ID** (z.B. `ABC123DEFG`)
   - **Team ID** (findest du oben rechts im Portal, z.B. `XYZ987TEAM`)

---

## 2️⃣ Xcode Projekt Konfiguration

### Schritt 1: Entitlements Datei erstellen

1. Öffne dein Projekt in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. Wähle das **Runner** Target
3. Gehe zum Tab **Signing & Capabilities**
4. Klicke auf **+ Capability**
5. Suche und füge **Sign in with Apple** hinzu

Dies erstellt automatisch eine `Runner.entitlements` Datei.

### Schritt 2: Entitlements Datei prüfen

Die Datei sollte so aussehen:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.developer.applesignin</key>
	<array>
		<string>Default</string>
	</array>
</dict>
</plist>
```

---

## 3️⃣ Supabase Konfiguration

### Schritt 1: Apple Provider aktivieren

1. Gehe zu deinem [Supabase Dashboard](https://app.supabase.com/)
2. Wähle dein Projekt
3. Navigiere zu **Authentication** → **Providers**
4. Suche **Apple** und klicke auf **Enable**

### Schritt 2: Apple Provider konfigurieren

Fülle folgende Felder aus:

1. **Services ID**: `com.cyrusjannis.shoply.signin` (deine Service ID von Schritt 1.2)
2. **Team ID**: Deine Team ID (z.B. `XYZ987TEAM`)
3. **Key ID**: Die Key ID von deinem Private Key (z.B. `ABC123DEFG`)
4. **Private Key**: Öffne die `.p8` Datei und kopiere den gesamten Inhalt (inklusive `-----BEGIN PRIVATE KEY-----` und `-----END PRIVATE KEY-----`)

5. Klicke **Save**

---

## 4️⃣ App Testen

### Lokales Testen

1. Starte die App auf einem echten iOS-Gerät (Simulator funktioniert nur mit Apple ID)
2. Gehe zum Login-Screen
3. Klicke auf **Continue with Apple**
4. Melde dich mit deiner Apple ID an
5. Wähle, ob du deine echte E-Mail oder eine versteckte E-Mail verwenden möchtest

### Wichtige Hinweise

- **Simulator**: Sign in with Apple funktioniert nur eingeschränkt im Simulator
- **Echtes Gerät**: Für vollständige Tests verwende ein echtes iOS-Gerät
- **Apple ID**: Du musst mit einer Apple ID angemeldet sein
- **Zwei-Faktor-Authentifizierung**: Stelle sicher, dass 2FA für deine Apple ID aktiviert ist

---

## 5️⃣ Troubleshooting

### Problem: "Invalid client"

**Lösung**: 
- Überprüfe, ob die Service ID korrekt in Supabase eingetragen ist
- Stelle sicher, dass die Return URL exakt mit deiner Supabase URL übereinstimmt

### Problem: "Invalid key"

**Lösung**:
- Überprüfe, ob der Private Key vollständig kopiert wurde (inklusive Header/Footer)
- Stelle sicher, dass Key ID und Team ID korrekt sind

### Problem: "The operation couldn't be completed"

**Lösung**:
- Stelle sicher, dass die App ID die Sign in with Apple Capability aktiviert hat
- Überprüfe, ob die Entitlements Datei korrekt im Xcode-Projekt eingebunden ist
- Baue die App neu: `flutter clean && flutter pub get && cd ios && pod install`

### Problem: Button wird nicht angezeigt

**Lösung**:
- Überprüfe, ob das `sign_in_with_apple` Package in `pubspec.yaml` vorhanden ist
- Führe `flutter pub get` aus

---

## 6️⃣ Checkliste

- [ ] App ID hat Sign in with Apple Capability aktiviert
- [ ] Service ID erstellt und konfiguriert
- [ ] Private Key (.p8) heruntergeladen und gespeichert
- [ ] Key ID und Team ID notiert
- [ ] Supabase Apple Provider konfiguriert
- [ ] Entitlements Datei in Xcode erstellt
- [ ] App auf echtem Gerät getestet

---

## 📚 Weitere Ressourcen

- [Apple Sign in with Apple Dokumentation](https://developer.apple.com/sign-in-with-apple/)
- [Supabase Apple Auth Guide](https://supabase.com/docs/guides/auth/social-login/auth-apple)
- [sign_in_with_apple Package](https://pub.dev/packages/sign_in_with_apple)

---

## 🔐 Sicherheitshinweise

- **Private Key**: Bewahre die `.p8` Datei sicher auf (nicht in Git committen!)
- **Service ID**: Verwende eine eindeutige Service ID pro App
- **Return URLs**: Stelle sicher, dass nur deine Supabase URL eingetragen ist

---

## ✅ Fertig!

Deine App sollte jetzt Sign in with Apple unterstützen! 🎉

Bei Fragen oder Problemen, überprüfe die Troubleshooting-Sektion oder die offiziellen Dokumentationen.
