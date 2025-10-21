# TestFlight Upload Anleitung - Version 1.1.0

## ✅ Build erfolgreich erstellt!

**Version:** 1.1.0 (Build 2)
**Datei:** `build/ios/ipa/shoply.ipa` (26.0MB)

## Upload zu TestFlight

### Methode 1: Xcode Organizer (EMPFOHLEN)

Das Archive wurde bereits geöffnet. Im Xcode Organizer:

1. **Wähle das Archive** (sollte bereits ausgewählt sein)
   - Version 1.1.0 (2)
   - Datum: Heute

2. **Klicke auf "Distribute App"**

3. **Wähle "App Store Connect"** → **Next**

4. **Wähle "Upload"** → **Next**

5. **Signing:**
   - ✅ Automatically manage signing
   - → **Next**

6. **Review:**
   - Prüfe die Informationen
   - → **Upload**

7. **Warte auf Upload** (kann 2-5 Minuten dauern)

8. **Fertig!** 
   - Du erhältst eine Bestätigung
   - Die App erscheint in 5-10 Minuten in App Store Connect

### Methode 2: Transporter App

Falls du die Transporter App installiert hast:

1. **Öffne Transporter:**
   ```bash
   open -a Transporter
   ```

2. **Drag & Drop:**
   - Ziehe `build/ios/ipa/shoply.ipa` in die Transporter App

3. **Deliver:**
   - Klicke auf "Deliver"
   - Warte auf Upload

### Methode 3: Terminal (Fortgeschritten)

```bash
xcrun altool --upload-app \
  --type ios \
  --file build/ios/ipa/shoply.ipa \
  --apiKey YOUR_API_KEY \
  --apiIssuer YOUR_ISSUER_ID
```

## Nach dem Upload

### 1. App Store Connect öffnen

Gehe zu [App Store Connect](https://appstoreconnect.apple.com)

### 2. TestFlight Tab

1. **Wähle deine App** (Shoply)
2. **Gehe zu "TestFlight"**
3. **Warte auf "Processing"** (5-10 Minuten)
4. **Status wird zu "Ready to Test"**

### 3. Release Notes hinzufügen

Wenn der Build bereit ist:

1. **Klicke auf Build 2**
2. **"Test Details"** → **"What to Test"**
3. **Füge die Release Notes ein:**

```
Version 1.1.0 - Neue Features

🎉 Einkaufshistorie → Liste hinzufügen
• Ganzen Einkauf mit einem Klick zur Liste hinzufügen
• Perfekt zum Wiederholen von Einkäufen

✨ Verbesserte Sortierung
• Custom Sort für Listen per Drag & Drop
• Custom Sort für Items per Drag & Drop
• Sortierung wird automatisch gespeichert

✅ Einkauf abschließen - Nur markierte Items
• Nur markierte Items werden in die Historie übernommen
• Nicht markierte Items bleiben für den nächsten Einkauf

🔧 Technische Verbesserungen
• Verbesserte Performance
• Stabilere Synchronisation
• Code-Optimierungen
```

4. **"Save"**

### 4. Tester benachrichtigen

1. **Gehe zu "Internal Testing"** oder **"External Testing"**
2. **Wähle deine Tester-Gruppe**
3. **Aktiviere "Notify Testers"**
4. **"Save"**

## Tester erhalten Benachrichtigung

Deine Tester bekommen:
- ✉️ E-Mail-Benachrichtigung
- 📱 Push-Benachrichtigung in TestFlight App
- Update ist sofort verfügbar

## Fertig! 🎉

Das Update ist jetzt live in TestFlight!

## Troubleshooting

### "Missing Compliance"
Falls nach dem Upload gefragt wird:
- **Verwendet deine App Verschlüsselung?** → Ja (HTTPS)
- **Verwendet sie Verschlüsselung außer HTTPS?** → Nein
- → Keine Export Compliance nötig

### "Processing" dauert zu lange
- Normal: 5-10 Minuten
- Manchmal: bis zu 30 Minuten
- Bei Problemen: Apple Developer Support kontaktieren

### Build erscheint nicht
- Prüfe E-Mails von Apple (Fehler-Benachrichtigungen)
- Prüfe App Store Connect → Activity
- Warte 30 Minuten, dann neu versuchen
