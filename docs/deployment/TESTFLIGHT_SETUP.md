# 🧪 **TestFlight Internal Testing Setup Guide**

## 📋 **What's New Text für interne Tester:**

**Kopiere diesen Text in das "What's New" Feld in TestFlight:**

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

## 📱 **How to Upload to TestFlight (Internal Testing):**

### **Step 1: Build für TestFlight**
1. **In Xcode** (nicht Flutter!):
   - Öffne `ios/Runner.xcworkspace`
   - Wähle **Product** → **Archive** (oder `Cmd + B`)
   - Warte bis Archive erstellt ist

### **Step 2: Upload zu TestFlight**
1. **In Xcode Organizer** (Window → Organizer):
   - Wähle das gerade erstellte Archive
   - Klicke **"Distribute App"**
   - Wähle **"App Store Connect"**

2. **Export & Upload**:
   - Wähle **"Upload"** für TestFlight
   - Wähle **"Automatically manage signing"**
   - Klicke **"Upload"**

### **Step 3: TestFlight Konfiguration**
1. **Gehe zu App Store Connect** (https://appstoreconnect.apple.com)
2. **Wähle deine App** → **TestFlight**
3. **Unter "Internal Testing"**:
   - Klicke **"Add to Group"**
   - Wähle deine interne Tester-Gruppe (oder erstelle neue)
   - Füge den **"What's New"** Text oben ein
   - Klicke **"Add"**

### **Step 4: Tester hinzufügen**
1. **Internal Testing** → **Add Testers**
2. **Füge E-Mail-Adressen hinzu** (max 100 für Internal)
3. **Tester bekommen automatisch eine Einladung**

### **Step 5: Build-Number erhöhen für Updates**
1. **In Xcode** → **Runner** → **General**
2. **Build Number** erhöhen (z.B. von 3 auf 4)
3. **Archive und Upload** erneut

## ⚠️ **Internal vs External Testing:**

| | **Internal Testing** | **External Testing** |
|---|---|---|
| **Review** | ❌ Kein Review nötig | ✅ Apple Review (1-2 Tage) |
| **Limit** | Max 100 Tester | Unbegrenzt |
| **Speed** | Sofort verfügbar | Nach Review |
| **Team** | Nur App Store Connect Team | Jeder mit Link |

## 🔧 **Version Tracking in der App:**

Die App zeigt automatisch das **Update-Dialog** beim ersten Start nach einem Update an:

- ✅ **Automatische Erkennung** neuer Versionen
- ✅ **Version gespeichert** in SharedPreferences
- ✅ **Dialog nur einmal** pro Version
- ✅ **Lokalisierte Texte** (Deutsch/Englisch)

**Die App ist bereit für TestFlight!** 🚀
