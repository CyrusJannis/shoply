# 🤖 KI-basierte Zutatenerkennung Setup

## Übersicht

Die App nutzt jetzt **Google Gemini AI** um automatisch **jede beliebige Zutat** zu erkennen und passende Ersatzprodukte vorzuschlagen - auch für Zutaten, die nicht in der lokalen Datenbank sind!

## 🎯 Wie es funktioniert

### 2-Stufen-System:

1. **Stufe 1: Lokale Datenbank** (schnell, offline)
   - 50+ vordefinierte Ersatzprodukte
   - Sofortige Antwort ohne Internet
   
2. **Stufe 2: KI-Analyse** (intelligent, universal)
   - Falls Stufe 1 keinen Ersatz findet
   - Gemini AI analysiert die Zutat
   - Schlägt intelligente Ersatzprodukte vor
   - Funktioniert für **JEDE Zutat weltweit**

### Beispiele:

| Zutat (User-Input) | Lokale DB | KI-Analyse |
|-------------------|-----------|------------|
| "Milch" | ✅ Hafermilch | - |
| "Bio-Vollmilch 3,5%" | ❌ | ✅ Hafermilch |
| "Parmigiano Reggiano" | ❌ | ✅ Hefeflocken |
| "Ghee (geklärte Butter)" | ❌ | ✅ Kokosöl |
| "พริกไทย" (Thai) | ❌ | ✅ Schwarzer Pfeffer |

## 📋 Setup-Schritte

### 1. Gemini API Key erhalten

1. Gehe zu: https://makersuite.google.com/app/apikey
2. Klicke auf "Create API Key"
3. Kopiere den API Key

### 2. API Key in der App konfigurieren

#### Option A: .env Datei (empfohlen)

1. Erstelle Datei im Root: `.env`
   ```bash
   GEMINI_API_KEY=dein_api_key_hier
   ```

2. Füge zu `.gitignore` hinzu:
   ```
   .env
   ```

3. Installiere flutter_dotenv:
   ```bash
   flutter pub add flutter_dotenv
   ```

4. Update `ai_ingredient_analyzer.dart`:
   ```dart
   import 'package:flutter_dotenv/flutter_dotenv.dart';
   
   static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
   ```

#### Option B: Direkt im Code (nur für Tests!)

In `lib/data/services/ai_ingredient_analyzer.dart` Zeile 9:
```dart
static const String _apiKey = 'DEIN_API_KEY_HIER';
```

⚠️ **WARNUNG**: Nie API Keys in Git committen!

### 3. Dependency installieren

```bash
flutter pub add google_generative_ai
flutter pub get
```

### 4. KI aktivieren/deaktivieren

In `ingredient_substitution_service.dart`:
```dart
IngredientSubstitutionService.useAI = true;  // KI AN
IngredientSubstitutionService.useAI = false; // KI AUS (nur lokale DB)
```

## 🧪 Testing

### Test 1: Bekannte Zutat (lokale DB)
```dart
// Sollte lokale DB nutzen
final recipe = await IngredientSubstitutionService.adaptRecipeWithAI(
  recipe: recipe,
  allergies: [AllergyType.milk],
  diets: [],
);
// Log: ✅ Lokale DB: Milch → Hafermilch
```

### Test 2: Unbekannte Zutat (KI)
```dart
// Sollte KI nutzen
final recipe = await IngredientSubstitutionService.adaptRecipeWithAI(
  recipe: recipeWithExoticIngredient,
  allergies: [AllergyType.milk],
  diets: [DietType.vegan],
);
// Log: 🤖 KI analysiert: Ghee
// Log: ✅ KI-Ersatz: Ghee → Kokosöl (95% Confidence)
```

### Test 3: Batch-Analyse (ganzes Rezept)
```dart
final analyzer = AIIngredientAnalyzer();
final results = await analyzer.analyzeRecipe(
  ingredients: recipe.ingredients,
  allergies: [AllergyType.milk],
  diets: [DietType.vegan],
);
```

## 💰 Kosten

Gemini API ist **kostenlos** für:
- Bis zu 60 Anfragen/Minute
- Bis zu 1500 Anfragen/Tag

**Schätzung für deine App:**
- Pro Rezept-Analyse: ~10-15 Zutaten = 1 Anfrage (Batch-Modus)
- 100 Rezepte pro Tag = 100 Anfragen
- → Gut innerhalb der Free-Tier Limits!

## 🎨 UI Integration

### Recipe Detail Screen (bereits implementiert)

Die KI wird automatisch genutzt wenn:
1. User hat Allergien/Diäten gespeichert
2. User öffnet Rezept-Detail
3. User togglet zu "Angepasst"
4. → System nutzt zuerst lokale DB, dann KI

### Console Logs zum Debugging

```
🤖 KI analysiert: Parmigiano Reggiano
✅ KI-Ersatz: Parmigiano Reggiano → Hefeflocken (92% Confidence)
```

## ⚡ Performance-Optimierung

### Caching (TODO)
```dart
// In ai_ingredient_analyzer.dart
final Map<String, IngredientAnalysisResult> _cache = {};

Future<IngredientAnalysisResult> analyzeIngredient(...) async {
  final cacheKey = '$ingredientName|$allergies|$diets';
  if (_cache.containsKey(cacheKey)) {
    return _cache[cacheKey]!;
  }
  // ... KI-Anfrage
  _cache[cacheKey] = result;
  return result;
}
```

### Batch-Modus nutzen
Statt einzelne Zutaten → ganzes Rezept auf einmal:
```dart
await analyzer.analyzeRecipe(ingredients: recipe.ingredients);
```

## 🔧 Troubleshooting

### Problem: "API Key ungültig"
- Lösung: API Key auf https://makersuite.google.com neu generieren

### Problem: "Rate Limit exceeded"
- Lösung: Caching implementieren oder Anfragen drosseln

### Problem: KI gibt keine Antwort
- Lösung: Fallback auf lokale DB (automatisch)
- Check Console Logs: `❌ AI Ingredient Analysis Error`

## 🚀 Next Steps

1. ✅ KI-Service implementiert
2. ✅ Integration in IngredientSubstitutionService
3. ⏳ API Key konfigurieren
4. ⏳ Dependency installieren: `flutter pub add google_generative_ai`
5. ⏳ Testen mit exotischen Zutaten
6. ⏳ Caching implementieren (Optional)

## 📊 Monitoring

Schaue in Console Logs:
- `✅ Lokale DB:` → Lokale Datenbank wurde genutzt
- `🤖 KI analysiert:` → KI-Anfrage gestartet
- `✅ KI-Ersatz:` → KI hat Ersatz gefunden
- `⚠️ KI: Kein Ersatz` → Auch KI konnte nichts finden
- `❌ KI-Fehler:` → Technischer Fehler (Network, API Key, etc.)

---

**Status**: 🟡 Implementiert - API Key Setup erforderlich
