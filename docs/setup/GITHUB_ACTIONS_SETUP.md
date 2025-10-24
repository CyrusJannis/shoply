# GitHub Actions Setup für automatische TestFlight Deployments

## Übersicht
Bei jedem `git push` auf den `main` Branch wird automatisch:
1. Die App gebaut
2. Ein neues Archive erstellt
3. Zu TestFlight hochgeladen
4. Tester bekommen eine Benachrichtigung

## Benötigte Secrets in GitHub

Gehe zu: **GitHub Repository → Settings → Secrets and variables → Actions → New repository secret**

### 1. App Store Connect API Key erstellen

1. Gehe zu [App Store Connect](https://appstoreconnect.apple.com)
2. **Users and Access** → **Integrations** → **App Store Connect API**
3. Klicke auf **"+"** (Generate API Key)
4. Name: `GitHub Actions`
5. Access: **App Manager**
6. Klicke **Generate**  
7. **Lade die .p8 Datei herunter** (nur einmal möglich!)
8. Notiere:
   - **Issuer ID** (oben auf der Seite)
   - **Key ID** (in der Tabelle)

### 2. Secrets in GitHub hinzufügen

#### `APP_STORE_CONNECT_API_KEY_ID`
- Wert: Die **Key ID** von oben

#### `APP_STORE_CONNECT_ISSUER_ID`
- Wert: Die **Issuer ID** von oben

#### `APP_STORE_CONNECT_API_KEY`
- Wert: Öffne die heruntergeladene `.p8` Datei mit einem Texteditor
- Kopiere den **gesamten Inhalt** (inklusive `-----BEGIN PRIVATE KEY-----` und `-----END PRIVATE KEY-----`)

### 3. iOS Zertifikat exportieren

1. Öffne **Keychain Access** auf deinem Mac
2. Suche nach deinem **Apple Development** oder **Apple Distribution** Zertifikat
3. Rechtsklick → **Export**
4. Speichere als `.p12` Datei
5. Setze ein **Passwort** (merke es dir!)
6. Konvertiere zu Base64:
   ```bash
   base64 -i /pfad/zu/deinem/zertifikat.p12 | pbcopy
   ```
   (Das kopiert den Base64-String in die Zwischenablage)

#### `IOS_CERTIFICATE_P12`
- Wert: Der Base64-String aus der Zwischenablage

#### `IOS_CERTIFICATE_PASSWORD`
- Wert: Das Passwort, das du beim Export gesetzt hast

### 4. Provisioning Profile exportieren

1. Gehe zu [Apple Developer](https://developer.apple.com/account/resources/profiles/list)
2. Lade dein **App Store** Provisioning Profile herunter
3. Konvertiere zu Base64:
   ```bash
   base64 -i /pfad/zu/deinem/profile.mobileprovision | pbcopy
   ```

#### `IOS_PROVISIONING_PROFILE`
- Wert: Der Base64-String aus der Zwischenablage

## Testen

1. Committe und pushe die Änderungen:
   ```bash
   git add .
   git commit -m "Add GitHub Actions for TestFlight"
   git push origin main
   ```

2. Gehe zu GitHub → **Actions** Tab
3. Du solltest einen laufenden Workflow sehen
4. Nach ca. 15-20 Minuten sollte der Build auf TestFlight sein

## Troubleshooting

- **Build schlägt fehl**: Prüfe die Logs im Actions Tab
- **Zertifikat-Fehler**: Stelle sicher, dass das Zertifikat nicht abgelaufen ist
- **Upload schlägt fehl**: Prüfe, ob die API Key Permissions korrekt sind

## Hinweis

Die Build-Nummer wird automatisch bei jedem Build erhöht. Du musst nur die Version in `pubspec.yaml` manuell ändern, wenn du eine neue Version veröffentlichen möchtest.
