# 🚀 TestFlight Internal Tester Update

## Schnellanleitung: Neuen Build für interne Tester hochladen

### ✅ Was bereits erledigt ist:
- ✅ Build-Nummer erhöht (1.1.0+3)
- ✅ Code auf GitHub hochgeladen
- ✅ IPA wird gerade gebaut

---

## 📦 Schritt 1: Build hochladen

### Option A: Über Xcode (Empfohlen)

```bash
# Öffne Xcode
open ios/Runner.xcworkspace
```

**In Xcode:**
1. **Product** → **Archive**
2. Warte bis der Build fertig ist
3. Im Organizer: **Distribute App**
4. Wähle: **App Store Connect**
5. Wähle: **Upload**
6. Folge den Schritten
7. **Upload** klicken

### Option B: Über Transporter App

```bash
# IPA Datei öffnen
open build/ios/ipa/
```

1. Öffne **Transporter** App (aus dem App Store)
2. Ziehe die `.ipa` Datei in Transporter
3. Klicke **Deliver**
4. Warte auf Upload-Bestätigung

---

## 📱 Schritt 2: Build für interne Tester freigeben

### In App Store Connect:

1. Gehe zu [App Store Connect](https://appstoreconnect.apple.com/)
2. Wähle deine App **"Shoply"**
3. Klicke auf **TestFlight** Tab
4. Warte 5-10 Minuten bis der Build verarbeitet ist
5. Der neue Build erscheint unter **"iOS Builds"**

### Build für interne Tester aktivieren:

**Automatisch:**
- Interne Tester bekommen den Build **automatisch**, wenn "Automatic Distribution" aktiviert ist

**Manuell:**
1. Klicke auf den neuen Build (1.1.0 Build 3)
2. Unter **"Internal Testing"** → **"Add to Group"**
3. Wähle deine interne Tester-Gruppe
4. Klicke **Add**
5. Interne Tester bekommen eine Benachrichtigung

---

## 🎉 **Shoply v1.1.0 - What's New (Internal Test)**

### 🌟 **Major New Features:**

#### 🤖 **Intelligent Product Categorization System**
- **29 Smart Categories** - Automatic AI-powered product recognition
- **Typo Tolerance** - Recognizes "Gauda" → Gouda, "Kaese" → Käse, handles common misspellings
- **1000+ Keywords** - Ultra-accurate German & English product recognition
- **Confidence Scoring** - Smart fallback system for unknown products
- **Real-time Classification** - Instant categorization as you type

#### 🌍 **Complete Localization Support**
- **German & English** - Automatic system language detection
- **Native UI Translation** - All buttons, dialogs, messages localized
- **Consistent Terminology** - Professional translations throughout
- **Auto-Capitalization** - Sentence case formatting in all input fields

#### ✨ **Enhanced User Experience**
- **Unit Selection** - Dropdown for units (kg, pcs, l, ml, etc.) in edit mode
- **Whole Number Display** - Quantities show as "2" instead of "2.0"
- **Cleaner Interface** - Removed floating add button for streamlined UI
- **Improved Edit Dialog** - Better organization and user flow

#### 📱 **Technical Improvements**
- **ML-Ready Architecture** - TensorFlow Lite integration prepared
- **Better Performance** - Optimized categorization algorithms
- **Enhanced Error Handling** - More stable app experience
- **Accessibility Improvements** - Better support for all users

### 🛒 **How the New Features Work:**

1. **Smart Typing** → Start typing any product name
2. **Auto-Recognition** → Product instantly categorized (🥛 Milch, 🥩 Salami, 🥬 Obst)
3. **Edit Products** → Tap any item → Select units and edit quantities
4. **Language Adapts** → App automatically matches your device language
5. **Whole Numbers** → See "2" instead of "2.0" for cleaner display

### 🔧 **Testing Instructions for Internal Testers:**

#### **Categorization Testing:**
- ✅ Try various product names: "Gauda", "Salami", "Apfel", "Milch"
- ✅ Test typos: "Kaese", "Jogurt", "Broetchen"
- ✅ Check English products: "Cheese", "Milk", "Bread"
- ✅ Verify categories: 🥛 Kühlprodukte, 🥩 Fleisch, 🥬 Obst & Gemüse

#### **Localization Testing:**
- ✅ Change device language to German/English
- ✅ Check all dialogs and buttons are translated
- ✅ Verify auto-capitalization works in search field
- ✅ Test both German and English text inputs

#### **UI/UX Testing:**
- ✅ Edit products and check unit selection dropdown
- ✅ Verify quantities display as whole numbers
- ✅ Test search field auto-capitalization
- ✅ Check that add button is removed (use search bar)

#### **Bug Reporting:**
- Report any products that aren't categorized correctly
- Note any translation issues or missing text
- Mention any UI inconsistencies between languages

### 📋 **Known Features Working:**
- ✅ **29 Product Categories** with smart recognition
- ✅ **German/English Localization** with auto-detection
- ✅ **Auto-Capitalization** in all text inputs
- ✅ **Unit Selection** in product editing
- ✅ **Whole Number Display** for quantities
- ✅ **Enhanced Search Experience** without floating button

### 🎯 **Priority Test Cases:**
1. **Categorization Accuracy** - Does "Gauda" go to 🥛 Kühlprodukte?
2. **Language Switching** - Does the app adapt to system language?
3. **Unit Selection** - Can you select kg/pcs/l when editing?
4. **Number Display** - Do quantities show as "2" not "2.0"?

**Thank you for testing! Your feedback is crucial for the final release!** 🚀

---

## ⚠️ Wichtig: Nur für INTERNE Tester

### Unterschied Internal vs External:

| | Internal Tester | External Tester |
|---|----------------|-----------------|
| **Review** | ❌ Kein Review nötig | ✅ Apple Review erforderlich |
| **Limit** | Max 100 Tester | Unbegrenzt |
| **Zugriff** | Sofort verfügbar | Nach Review (1-2 Tage) |
| **Team** | Muss im App Store Connect Team sein | Jeder mit Link |

### Für interne Tester:
- ✅ **Kein Apple Review** nötig
- ✅ **Sofort verfügbar** nach Upload
- ✅ **Automatische Benachrichtigung** per E-Mail
- ✅ **Schnelle Updates** möglich

---

## 🔔 Was passiert nach dem Upload?

### Timeline:

1. **Upload** (5-10 Min)
   - IPA wird zu Apple hochgeladen
   - Verarbeitung beginnt

2. **Processing** (5-10 Min)
   - Apple verarbeitet den Build
   - Status: "Processing"

3. **Ready for Testing** (Sofort)
   - Build ist bereit
   - Interne Tester bekommen Benachrichtigung
   - Download über TestFlight App möglich

### Benachrichtigung an Tester:

Interne Tester erhalten:
- 📧 **E-Mail** mit Update-Info
- 📱 **Push-Benachrichtigung** in TestFlight App
- ✅ **Automatischer Download** (wenn aktiviert)

---

## 📝 Release Notes (Optional)

Du kannst Release Notes für diesen Build hinzufügen:

1. In App Store Connect → TestFlight
2. Klicke auf den Build
3. **Test Details** → **What to Test**
4. Füge hinzu:

```
Version 1.1.0 Build 3

Neue Features:
- ✅ Apple Sign-In hinzugefügt
- ✅ Verbesserter Google Sign-In (native SDK)
- ✅ Stabilere Authentifizierung

Behobene Bugs:
- 🐛 OAuth Redirect-Probleme behoben
- 🐛 Sign-In Flow verbessert
```

---

## 🧪 Testen

Nach dem Upload:

1. **TestFlight App** öffnen auf dem iPhone
2. App **"Shoply"** auswählen
3. **Update** Button erscheint
4. **Install** klicken
5. Neue Version testen

### Was testen:

- ✅ Google Sign-In
- ✅ Apple Sign-In
- ✅ Alle bestehenden Features
- ✅ Performance

---

## 🔄 Für weitere Updates:

```bash
# 1. Build-Nummer erhöhen in pubspec.yaml
# z.B. von 1.1.0+3 zu 1.1.0+4

# 2. Build erstellen
flutter build ipa --release

# 3. Hochladen (Xcode oder Transporter)

# 4. Warten auf Verarbeitung

# 5. Fertig! Interne Tester bekommen automatisch Update
```

---

## 💡 Tipps

### Schnellere Updates:
- Erhöhe nur die Build-Nummer (+1)
- Version bleibt gleich (1.1.0)
- Kein Review nötig für interne Tester

### Automatische Distribution:
1. TestFlight → App → Internal Testing
2. Aktiviere **"Automatically distribute to testers"**
3. Neue Builds gehen automatisch an alle internen Tester

### Tester hinzufügen:
1. App Store Connect → Users and Access
2. **TestFlight** → **Testers**
3. **Internal Testers** → **+** Button
4. E-Mail eingeben → Einladen

---

## ✅ Fertig!

Deine internen Tester haben jetzt Zugriff auf den neuen Build mit:
- ✨ Apple Sign-In
- ✨ Verbessertem Google Sign-In
- ✨ Stabilerer Authentifizierung

**Viel Erfolg beim Testen! 🚀**
