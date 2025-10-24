# 🔧 Xcode Setup für Sign in with Apple

## Schnellanleitung: Entitlements in Xcode hinzufügen

### Methode 1: Automatisch über Xcode (Empfohlen)

1. **Öffne das Projekt in Xcode:**
   ```bash
   cd ios
   open Runner.xcworkspace
   ```

2. **Wähle das Runner Target:**
   - Klicke auf **Runner** in der Projektnavigation (links)
   - Wähle das **Runner** Target (nicht das Projekt)

3. **Füge Sign in with Apple Capability hinzu:**
   - Gehe zum Tab **Signing & Capabilities**
   - Klicke auf **+ Capability** (oben links)
   - Suche nach **Sign in with Apple**
   - Doppelklick auf **Sign in with Apple**

4. **Fertig!** Xcode erstellt automatisch die `Runner.entitlements` Datei

### Methode 2: Manuelle Einbindung (Falls Methode 1 nicht funktioniert)

Falls die Entitlements-Datei bereits existiert, aber nicht eingebunden ist:

1. **Öffne das Projekt in Xcode:**
   ```bash
   cd ios
   open Runner.xcworkspace
   ```

2. **Wähle das Runner Target:**
   - Klicke auf **Runner** in der Projektnavigation
   - Wähle das **Runner** Target

3. **Gehe zu Build Settings:**
   - Klicke auf den Tab **Build Settings**
   - Suche nach "Code Signing Entitlements" (nutze die Suchleiste)

4. **Setze den Pfad:**
   - Für **Debug**: `Runner/Runner.entitlements`
   - Für **Release**: `Runner/Runner.entitlements`
   - Für **Profile**: `Runner/Runner.entitlements`

5. **Speichern:**
   - Drücke `Cmd + S` zum Speichern
   - Schließe Xcode

---

## ✅ Überprüfung

Nach dem Setup solltest du Folgendes sehen:

### In Xcode:
- Tab **Signing & Capabilities** zeigt **Sign in with Apple** an
- Die Datei `Runner.entitlements` ist im Projekt sichtbar

### In der Dateistruktur:
```
ios/
  Runner/
    Runner.entitlements  ← Diese Datei sollte existieren
    Info.plist
    AppDelegate.swift
    ...
```

---

## 🔄 App neu bauen

Nach dem Setup:

```bash
# Zurück zum Projekt-Root
cd ..

# Flutter Clean
flutter clean

# Dependencies neu installieren
flutter pub get

# iOS Pods neu installieren
cd ios
pod install
cd ..

# App bauen
flutter build ios
```

---

## 🧪 Testen

1. **Auf echtem Gerät testen** (Simulator hat Einschränkungen)
2. App starten
3. Zum Login-Screen navigieren
4. "Continue with Apple" Button sollte funktionieren

---

## ⚠️ Wichtige Hinweise

- **Bundle ID**: Stelle sicher, dass deine Bundle ID im Apple Developer Portal registriert ist
- **Provisioning Profile**: Muss die Sign in with Apple Capability enthalten
- **Team**: Stelle sicher, dass das richtige Team in Xcode ausgewählt ist

---

## 🐛 Troubleshooting

### Problem: "Capability not found"

**Lösung:**
- Stelle sicher, dass du mit deinem Apple Developer Account in Xcode angemeldet bist
- Gehe zu **Xcode** → **Preferences** → **Accounts** und füge deinen Account hinzu

### Problem: "Provisioning profile doesn't include the Sign in with Apple entitlement"

**Lösung:**
- Gehe zum Apple Developer Portal
- Lösche das alte Provisioning Profile
- Lass Xcode ein neues erstellen (Automatic Signing)

### Problem: Entitlements-Datei wird nicht gefunden

**Lösung:**
- Überprüfe den Pfad in Build Settings
- Stelle sicher, dass die Datei `Runner/Runner.entitlements` heißt
- Prüfe, ob die Datei im Xcode-Projekt sichtbar ist (nicht nur im Finder)

---

## 📝 Nächste Schritte

Nach dem Xcode-Setup:
1. ✅ Xcode-Konfiguration abgeschlossen
2. ➡️ Weiter mit [APPLE_SIGNIN_SETUP.md](APPLE_SIGNIN_SETUP.md) für Apple Developer Portal und Supabase Setup
