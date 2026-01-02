# Share Link Setup

## Übersicht
Die App unterstützt jetzt das Teilen von Listen über:
1. **6-stellige Codes** (z.B. `ABC123`)
2. **Internet-Links** (z.B. `https://deine-domain.com/join/ABC123`)

## Domain konfigurieren

### 1. Domain in der App einstellen
Öffne die Datei: `lib/core/constants/app_config.dart`

Ändere die `shareDomain` Konstante zu deiner Domain:
```dart
static const String shareDomain = 'https://deine-domain.com';
```

### 2. Deep Link Setup

#### iOS (ios/Runner/Info.plist)
Füge folgendes hinzu:
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLName</key>
    <string>com.shoply.app</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>shoply</string>
    </array>
  </dict>
</array>
```

#### Android (android/app/src/main/AndroidManifest.xml)
Füge im `<activity>` Tag hinzu:
```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data
        android:scheme="https"
        android:host="deine-domain.com"
        android:pathPrefix="/join" />
</intent-filter>
```

### 3. Website Setup (Optional)
Erstelle eine einfache Weiterleitungs-Website auf deiner Domain:

**Beispiel index.html:**
```html
<!DOCTYPE html>
<html>
<head>
    <title>Shoply - Join List</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
</head>
<body>
    <script>
        // Extrahiere den Share-Code aus der URL
        const path = window.location.pathname;
        const code = path.split('/').pop();
        
        // Versuche die App zu öffnen
        window.location.href = `shoply://join/${code}`;
        
        // Fallback: Zeige Anweisungen nach 2 Sekunden
        setTimeout(() => {
            document.body.innerHTML = `
                <h1>Join Shoply List</h1>
                <p>Share Code: <strong>${code}</strong></p>
                <p>Öffne die Shoply App und gib diesen Code ein.</p>
            `;
        }, 2000);
    </script>
</body>
</html>
```

## Verwendung

### Liste teilen
1. Öffne eine Liste
2. Tippe auf das Share-Icon
3. Generiere einen Share-Code
4. Du erhältst:
   - **Code**: `ABC123`
   - **Link**: `https://deine-domain.com/join/ABC123`
5. Teile entweder den Code oder den Link

### Liste beitreten
1. Tippe auf "Join List" in der Listen-Übersicht
2. Gib entweder ein:
   - Den 6-stelligen Code: `ABC123`
   - Den vollständigen Link: `https://deine-domain.com/join/ABC123`
3. Tippe auf "Join"

## Datenbank
Das `share_link` Feld wird automatisch in der `shopping_lists` Tabelle gespeichert.

Stelle sicher, dass die Spalte existiert:
```sql
ALTER TABLE shopping_lists ADD COLUMN IF NOT EXISTS share_link TEXT;
```
