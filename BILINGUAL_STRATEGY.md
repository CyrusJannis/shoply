# Shoply Bilingual Strategy (English/German)

## Current State Analysis

### ✅ What's Working
- **UI Localization**: Complete German/English translations in `AppLocalizations`
- **System Integration**: Proper Flutter localization delegates setup
- **User Preference**: App follows device language settings

### ⚠️ Current Limitations
1. **Categories**: Hardcoded in German only (`Obst & Gemüse`, `Milchprodukte`, etc.)
2. **AI Categorization**: German-only prompts and keywords
3. **Recipes**: No language tagging - German users create German recipes, English users see German content
4. **Labels**: ML-generated labels not localized
5. **Mixed Content**: User-generated content (item names, recipe titles) in mixed languages

---

## Recommended Architecture: **Language-Aware with Smart Translation**

### Philosophy
> **Store content in user's language, display in user's language, but enable cross-language understanding through AI.**

### Why This Approach?
- ✅ **Natural UX**: Users type in their native language (no forcing)
- ✅ **Accurate categorization**: AI understands both languages
- ✅ **Shared recipes**: German recipes visible to English users (with translations)
- ✅ **Cost-effective**: Minimal API calls, heavy caching
- ✅ **Offline-first**: Works without internet after initial categorization

---

## Implementation Plan

### 🎯 Phase 1: Bilingual Categories (Week 1)

**Goal**: Categories work perfectly in both languages

#### 1.1 Update Category Data Structure

**File**: `lib/core/constants/categories.dart`

```dart
class CategoryData {
  final String id; // Unique identifier (e.g., 'fruits_vegetables')
  final Map<String, String> names; // Language-specific names
  final Color color;
  final IconData icon;
  final Map<String, List<String>> keywords; // Language-specific keywords

  const CategoryData({
    required this.id,
    required this.names,
    required this.color,
    required this.icon,
    required this.keywords,
  });

  String getName(String languageCode) {
    return names[languageCode] ?? names['en']!; // Fallback to English
  }

  List<String> getKeywords(String languageCode) {
    return keywords[languageCode] ?? keywords['en']!;
  }
}

class Categories {
  static const List<CategoryData> all = [
    CategoryData(
      id: 'fruits_vegetables',
      names: {
        'en': 'Fruits & Vegetables',
        'de': 'Obst & Gemüse',
      },
      color: Color(0xFF4CAF50),
      icon: Icons.apple_rounded,
      keywords: {
        'en': ['apple', 'banana', 'orange', 'carrot', 'lettuce', 'tomato', 'cucumber', 'potato'],
        'de': ['apfel', 'banane', 'orange', 'karotte', 'salat', 'tomate', 'gurke', 'kartoffel'],
      },
    ),
    CategoryData(
      id: 'dairy',
      names: {
        'en': 'Dairy Products',
        'de': 'Milchprodukte',
      },
      color: Color(0xFF2196F3),
      icon: Icons.water_drop_rounded,
      keywords: {
        'en': ['milk', 'cheese', 'yogurt', 'butter', 'cream'],
        'de': ['milch', 'käse', 'joghurt', 'butter', 'sahne'],
      },
    ),
    // ... rest of categories
  ];

  // Helper to get category by ID
  static CategoryData getById(String id) {
    return all.firstWhere((cat) => cat.id == id);
  }

  // Helper to get all category names in a specific language
  static List<String> getNamesInLanguage(String languageCode) {
    return all.map((cat) => cat.getName(languageCode)).toList();
  }
}
```

**AI Execution Pattern**:
```bash
# 1. Backup current file
cp lib/core/constants/categories.dart lib/core/constants/categories.dart.backup

# 2. Create new bilingual structure
# Use create_file or replace_string_in_file

# 3. Update all usages
grep -r "Categories.all" lib/
# Update each file to use Categories.getNamesInLanguage(locale.languageCode)

# 4. Build verification
flutter build ios --simulator --debug 2>&1 | tail -20
```

#### 1.2 Update Gemini Categorization Service

**File**: `lib/data/services/gemini_categorization_service.dart`

Add language detection and bilingual support:

```dart
/// Categorize a shopping item (supports English & German)
Future<String> categorizeItem(String itemName, String languageCode) async {
  final normalizedName = itemName.trim().toLowerCase();
  final cacheKey = '${languageCode}_$normalizedName';
  
  // Check cache
  if (_categoryCache.containsKey(cacheKey)) {
    return _categoryCache[cacheKey]!;
  }

  // Detect language if not specified
  final detectedLanguage = languageCode == 'auto' 
    ? _detectLanguage(itemName) 
    : languageCode;

  try {
    await _rateLimit();
    final categoryId = await _categorizeWithGemini(itemName, detectedLanguage);
    
    // Cache with category ID (language-agnostic)
    _categoryCache[cacheKey] = categoryId;
    await _saveCache();
    
    return categoryId;
  } catch (e) {
    return _fallbackCategorization(itemName, detectedLanguage);
  }
}

/// Detect language using simple heuristics
String _detectLanguage(String text) {
  final lowerText = text.toLowerCase();
  
  // Check for German-specific characters
  if (lowerText.contains(RegExp(r'[äöüß]'))) {
    return 'de';
  }
  
  // Check for common German words
  const germanWords = ['und', 'mit', 'ohne', 'der', 'die', 'das'];
  for (final word in germanWords) {
    if (lowerText.split(' ').contains(word)) {
      return 'de';
    }
  }
  
  return 'en'; // Default to English
}

Future<String> _categorizeWithGemini(String itemName, String language) async {
  if (_model == null) throw Exception('Gemini not initialized');

  final categoryNames = Categories.getNamesInLanguage(language);
  final prompt = language == 'de' 
    ? _getGermanPrompt(itemName, categoryNames)
    : _getEnglishPrompt(itemName, categoryNames);

  final content = [Content.text(prompt)];
  final response = await _model!.generateContent(content);
  
  final categoryName = response.text!.trim();
  
  // Convert name back to ID
  final category = Categories.all.firstWhere(
    (cat) => cat.getName(language) == categoryName,
    orElse: () => Categories.getById('other'),
  );
  
  return category.id;
}

String _getGermanPrompt(String itemName, List<String> categories) {
  return '''
Kategorisiere diesen Einkaufsartikel in EINE dieser Kategorien:
${categories.join(', ')}

Artikel: "$itemName"

Regeln:
- Gib NUR den Kategorienamen zurück, sonst nichts
- Orientiere dich an deutschen Supermarkt-Konventionen
- Bei Unklarheit: "Sonstiges"

Kategorie:''';
}

String _getEnglishPrompt(String itemName, List<String> categories) {
  return '''
Categorize this grocery item into ONE of these categories:
${categories.join(', ')}

Item: "$itemName"

Rules:
- Return ONLY the category name, nothing else
- Follow typical supermarket organization
- If unclear, use "Other"

Category:''';
}
```

#### 1.3 Update Database Schema

**Migration**: `database/migrations/add_language_support.sql`

```sql
-- Add language tracking to shopping items
ALTER TABLE list_items
ADD COLUMN language VARCHAR(2) DEFAULT 'de',
ADD COLUMN category_id VARCHAR(50); -- Store category ID, not translated name

-- Update existing items to use category IDs
UPDATE list_items
SET category_id = CASE 
  WHEN category = 'Obst & Gemüse' THEN 'fruits_vegetables'
  WHEN category = 'Milchprodukte' THEN 'dairy'
  WHEN category = 'Fleisch & Fisch' THEN 'meat_fish'
  WHEN category = 'Backwaren' THEN 'bakery'
  WHEN category = 'Getränke' THEN 'beverages'
  WHEN category = 'Gewürze' THEN 'spices'
  WHEN category = 'Tiefkühl' THEN 'frozen'
  WHEN category = 'Grundnahrungsmittel' THEN 'staples'
  WHEN category = 'Snacks' THEN 'snacks'
  WHEN category = 'Haushalt & Drogerie' THEN 'household'
  ELSE 'other'
END;

-- Add language support to recipes
ALTER TABLE recipes
ADD COLUMN language VARCHAR(2) DEFAULT 'de',
ADD COLUMN translations JSONB; -- Store translations if available

-- Create index for language filtering
CREATE INDEX idx_recipes_language ON recipes(language);
```

---

### 🎯 Phase 2: Recipe Language Detection & Tagging (Week 2)

**Goal**: Recipes are properly tagged and searchable by language

#### 2.1 Update Recipe Model

**File**: `lib/data/models/recipe.dart`

```dart
class Recipe extends Equatable {
  // ... existing fields
  final String language; // 'en', 'de', or 'auto-detected'
  final Map<String, RecipeTranslation>? translations; // Optional translations
  
  const Recipe({
    // ... existing params
    this.language = 'de', // Default to German (majority of users)
    this.translations,
  });
  
  // Helper to get localized content
  String getLocalizedName(String preferredLanguage) {
    if (language == preferredLanguage) return name;
    return translations?[preferredLanguage]?.name ?? name;
  }
  
  String getLocalizedDescription(String preferredLanguage) {
    if (language == preferredLanguage) return description;
    return translations?[preferredLanguage]?.description ?? description;
  }
}

class RecipeTranslation {
  final String name;
  final String description;
  final List<String> instructions;
  
  const RecipeTranslation({
    required this.name,
    required this.description,
    required this.instructions,
  });
}
```

#### 2.2 Auto-Translate Recipes (Premium Feature)

**File**: `lib/data/services/recipe_translation_service.dart`

```dart
class RecipeTranslationService {
  final GenerativeModel _model;
  
  /// Translate recipe from one language to another
  /// Cost-optimized: Only translates title, description, instructions
  /// Ingredients stay in original language (understood by categorization)
  Future<RecipeTranslation> translateRecipe(
    Recipe recipe,
    String targetLanguage,
  ) async {
    final prompt = '''
Translate this recipe from ${recipe.language} to $targetLanguage.
Preserve cooking terminology and measurements exactly.

Original Recipe:
Title: ${recipe.name}
Description: ${recipe.description}
Instructions: ${recipe.instructions.join('\n')}

Return ONLY a JSON object with this structure:
{
  "name": "translated title",
  "description": "translated description",
  "instructions": ["step 1", "step 2", ...]
}
''';

    final response = await _model.generateContent([Content.text(prompt)]);
    final jsonStr = response.text!.replaceAll('```json', '').replaceAll('```', '').trim();
    final data = jsonDecode(jsonStr);
    
    return RecipeTranslation(
      name: data['name'],
      description: data['description'],
      instructions: List<String>.from(data['instructions']),
    );
  }
}
```

#### 2.3 UI: Show Recipe Language

Display language badges and offer translation:

```dart
// In recipe_card.dart or recipe_detail_screen.dart
Widget _buildLanguageBadge(BuildContext context, Recipe recipe) {
  final currentLanguage = Localizations.localeOf(context).languageCode;
  final needsTranslation = recipe.language != currentLanguage;
  
  return Row(
    children: [
      Chip(
        label: Text(recipe.language.toUpperCase()),
        avatar: Icon(Icons.language, size: 16),
      ),
      if (needsTranslation) ...[
        SizedBox(width: 8),
        TextButton.icon(
          icon: Icon(Icons.translate),
          label: Text('Translate'),
          onPressed: () => _showTranslation(context, recipe),
        ),
      ],
    ],
  );
}
```

---

### 🎯 Phase 3: Smart Labels & Search (Week 3)

**Goal**: Labels work across languages, search understands both

#### 3.1 Bilingual Label Generation

Update recipe labels to be language-agnostic:

```dart
class RecipeLabelService {
  static const List<String> dietLabels = [
    'vegetarian',
    'vegan',
    'gluten_free',
    'dairy_free',
    'low_carb',
    'keto',
  ];
  
  static const List<String> mealTypeLabels = [
    'breakfast',
    'lunch',
    'dinner',
    'snack',
    'dessert',
  ];
  
  static const List<String> cuisineLabels = [
    'italian',
    'asian',
    'mexican',
    'german',
    'mediterranean',
  ];
  
  // Get localized label text
  static String getLocalizedLabel(String labelId, String languageCode) {
    final labels = {
      'vegetarian': {'en': 'Vegetarian', 'de': 'Vegetarisch'},
      'vegan': {'en': 'Vegan', 'de': 'Vegan'},
      'gluten_free': {'en': 'Gluten-Free', 'de': 'Glutenfrei'},
      // ... all labels
    };
    
    return labels[labelId]?[languageCode] ?? labelId;
  }
}
```

#### 3.2 Cross-Language Search

```dart
class RecipeSearchService {
  /// Search recipes across languages
  /// Translates query if needed to match recipe language
  Future<List<Recipe>> searchRecipes(String query, String userLanguage) async {
    // 1. Search in user's language
    var results = await _searchInLanguage(query, userLanguage);
    
    // 2. If few results, try translating query to other language
    if (results.length < 5) {
      final otherLanguage = userLanguage == 'en' ? 'de' : 'en';
      final translatedQuery = await _translateQuery(query, otherLanguage);
      final otherResults = await _searchInLanguage(translatedQuery, otherLanguage);
      results.addAll(otherResults);
    }
    
    return results;
  }
  
  Future<String> _translateQuery(String query, String targetLanguage) async {
    // Simple word-by-word translation using cache
    // For common ingredients: "chicken" -> "hähnchen"
    final words = query.toLowerCase().split(' ');
    final translated = words.map((word) {
      return _ingredientTranslations[word]?[targetLanguage] ?? word;
    }).join(' ');
    
    return translated;
  }
  
  static const Map<String, Map<String, String>> _ingredientTranslations = {
    'chicken': {'de': 'hähnchen', 'en': 'chicken'},
    'milk': {'de': 'milch', 'en': 'milk'},
    'cheese': {'de': 'käse', 'en': 'cheese'},
    // ... common ingredients (100-200 most used)
  };
}
```

---

## Best Practices Summary

### ✅ DO
1. **Store category IDs** (language-agnostic) in database, not translated names
2. **Auto-detect language** from user input using simple heuristics
3. **Display in user's language** using dynamic lookups
4. **Cache translations** aggressively to minimize API costs
5. **Provide fallbacks** to original language if translation unavailable
6. **Tag recipes with language** at creation time
7. **Use AI for translation** only when user explicitly requests it

### ❌ DON'T
1. **Don't force language** - let users type naturally
2. **Don't translate everything** - ingredient names can stay in original language
3. **Don't call API for every search** - use cached translation dictionary
4. **Don't store duplicate data** - use IDs and compute display names
5. **Don't block UI** - show original content while translation loads

---

## Migration Strategy

### Step 1: Categories (Low Risk)
- Update category structure to use IDs
- Deploy without breaking existing data
- Gradually migrate items to new structure

### Step 2: Recipes (Medium Risk)
- Add language column with default 'de'
- Auto-detect language for new recipes
- Backfill existing recipes (manual review for ambiguous cases)

### Step 3: Search & Translation (High Value)
- Add premium translation feature
- Implement cross-language search
- Monitor API costs and user engagement

---

## Cost Estimation

**Gemini 1.5-flash pricing**:
- Input: $0.075 per 1M tokens
- Output: $0.30 per 1M tokens

**Estimated costs**:
- **Categorization**: ~50 tokens per call → $0.000015 per item
  - 10,000 items/month = $0.15/month
- **Recipe translation**: ~500 tokens per recipe → $0.00015 per recipe
  - 100 translations/month = $0.015/month
- **Search query translation**: ~20 tokens per query → $0.000006 per search
  - 10,000 searches/month = $0.06/month

**Total estimated cost**: < $1/month for moderate usage

---

## Testing Checklist

### Categories
- [ ] German user adds "Milch" → categorized as "dairy"
- [ ] English user adds "milk" → categorized as "dairy"
- [ ] Display shows "Milchprodukte" for German, "Dairy Products" for English
- [ ] Category colors/icons consistent across languages

### Recipes
- [ ] German recipe shows German badge
- [ ] English user sees "Translate" button on German recipe
- [ ] Translation preserves measurements (250ml, 2 cups, etc.)
- [ ] Ingredients remain in original language but are understood by categorization

### Search
- [ ] German user searches "Hähnchen" → finds chicken recipes in both languages
- [ ] English user searches "chicken" → finds "Hähnchen" recipes
- [ ] Labels filter works: "vegetarian" matches both "vegetarisch" and "vegetarian" recipes

---

## Future Enhancements

### Phase 4: Community Contributions
- Users can submit translations for recipes
- Voting system for translation quality
- Community-maintained ingredient dictionary

### Phase 5: More Languages
- Spanish, French, Italian support
- Language detection improvements
- Regional variations (US English vs UK English)

### Phase 6: Voice Input
- Speech-to-text with language detection
- "Add milk" vs "Füge Milch hinzu" both work

---

## Summary

**Recommended Implementation Order**:
1. ✅ **Week 1**: Bilingual categories (biggest UX impact)
2. ✅ **Week 2**: Recipe language tagging
3. ✅ **Week 3**: Translation feature (premium)
4. ⏸️ **Week 4+**: Advanced search, community translations

**Key Principle**: 
> Users create content in their language, AI bridges the gap for cross-language understanding.

This approach balances **natural UX** (users don't think about language), **technical simplicity** (IDs instead of translations everywhere), and **cost efficiency** (smart caching, on-demand translation).
