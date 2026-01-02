# 🌱 Intelligentes Allergie- & Ernährungssystem

## Übersicht
Ein umfassendes System zur automatischen Anpassung von Rezepten basierend auf **Allergien**, **Unverträglichkeiten** und **Ernährungspräferenzen**.

---

## ✅ Implementierte Features

### 1. **Ernährungsformen** (10 Typen)
- 🍽️ **Keine Einschränkungen**
- 🌱 **Vegan** - Keine tierischen Produkte
- 🥗 **Vegetarisch** - Kein Fleisch/Fisch
- 🐟 **Pescetarisch** - Fisch erlaubt
- 🌿 **Flexitarisch** - Überwiegend pflanzlich
- 🥑 **Ketogen** - Low Carb, High Fat
- 🥩 **Paleo** - Steinzeiternährung
- 🥬 **Low Carb** - Reduzierte Kohlenhydrate
- ☪️ **Halal** - Islamische Speisevorschriften
- ✡️ **Koscher** - Jüdische Speisevorschriften

### 2. **Allergien & Intoleranzen** (20+ Typen)

#### **EU-14 Hauptallergene**
1. 🌾 **Gluten** - Weizen, Roggen, Gerste, Hafer, Dinkel, Kamut
2. 🦞 **Krebstiere** - Garnelen, Krabben, Hummer, Krebse
3. 🥚 **Eier** - Ei, Eigelb, Eiweiß
4. 🐟 **Fisch** - Thunfisch, Lachs, Kabeljau
5. 🥜 **Erdnüsse** - Erdnuss, Erdnussbutter
6. 🫘 **Soja** - Tofu, Sojamilch, Sojasoße, Edamame
7. 🥛 **Milch/Laktose** - Milch, Sahne, Butter, Käse, Joghurt, Quark
8. 🌰 **Nüsse** - Mandeln, Haselnüsse, Walnüsse, Cashews, Pistazien
9. 🥬 **Sellerie** - Staudensellerie, Knollensellerie
10. 🌻 **Senf** - Senfkörner, Senfsaat
11. 🫑 **Sesam** - Sesamöl, Tahini, Gomasio
12. 🧪 **Sulfite** - Schwefeldioxid, Trockenfrüchte
13. 🌺 **Lupinen** - Lupinenmehl
14. 🦑 **Weichtiere** - Muscheln, Schnecken, Tintenfisch, Austern

#### **Zusätzliche Intoleranzen**
15. 🥛 **Laktose-Intoleranz**
16. 🍎 **Fruktose-Intoleranz** - Honig, Agavendicksaft
17. 🧀 **Histamin-Intoleranz** - Tomaten, Käse, Wein, Schokolade

#### **Weitere Unverträglichkeiten**
18. 🍅 **Nachtschattengewächse** - Tomaten, Paprika, Auberginen, Kartoffeln
19. 🌽 **Mais** - Maismehl, Maisstärke, Polenta
20. 🍞 **Hefe** - Backhefe

### 3. **Intelligente Ersatzprodukte** (50+ Mappings)

#### **Milchprodukte**
| Original | Ersatzprodukte | Grund |
|----------|---------------|--------|
| Milch | Hafermilch, Mandelmilch, Sojamilch | 🌱 Vegan, 🥛 Laktosefrei |
| Sahne | Hafersahne, Soja-Cuisine | 🌱 Vegan, 🥛 Laktosefrei |
| Butter | Vegane Margarine, Kokosöl | 🌱 Vegan, 🥛 Laktosefrei |
| Käse | Veganer Käse, Hefeflocken | 🌱 Vegan, 🥛 Laktosefrei |
| Parmesan | Veganer Parmesan, Hefeflocken mit Mandeln | 🌱 Vegan |
| Joghurt | Sojajoghurt, Kokosjoghurt | 🌱 Vegan, 🥛 Laktosefrei |

#### **Eier**
| Original | Ersatzprodukte | Grund |
|----------|---------------|--------|
| Ei | Leinsamen-Ei (1 EL + 3 EL Wasser) | 🌱 Vegan, 🥚 Eifrei |
| Ei | Chia-Ei (1 EL Chia + 3 EL Wasser) | 🌱 Vegan, 🥚 Eifrei |
| Ei | Apfelmus (60g) - für Süßspeisen | 🌱 Vegan, 🥚 Eifrei |

#### **Fleisch & Fisch**
| Original | Ersatzprodukte | Grund |
|----------|---------------|--------|
| Hähnchen | Tofu, Tempeh, Seitan | 🌱 Vegan, 🥗 Vegetarisch |
| Rinderhackfleisch | Veganes Hackfleisch, Linsen | 🌱 Vegan, 🥗 Vegetarisch |
| Speck/Pancetta | Veganer Speck, Räuchertofu-Streifen | 🌱 Vegan, 🥗 Vegetarisch |
| Lachs | Geräucherter Karotten-Lachs | 🌱 Vegan, 🐟 Fischfrei |
| Thunfisch | Kichererbsen (zerdrückt) | 🌱 Vegan, 🐟 Fischfrei |

#### **Glutenhaltige Produkte**
| Original | Ersatzprodukte | Grund |
|----------|---------------|--------|
| Weizenmehl | Reismehl, Mandelmehl, Buchweizenmehl | 🌾 Glutenfrei |
| Spaghetti | Glutenfreie Pasta, Zucchini-Nudeln | 🌾 Glutenfrei, 🥬 Low Carb |
| Semmelbrösel | Glutenfreie Semmelbrösel, Gemahlene Mandeln | 🌾 Glutenfrei |
| Sojasoße | Tamari (glutenfrei), Kokos-Aminos | 🌾 Glutenfrei, 🫘 Sojafrei |

#### **Nüsse & Samen**
| Original | Ersatzprodukte | Grund |
|----------|---------------|--------|
| Mandeln | Sonnenblumenkerne | 🌰 Nussfrei |
| Walnüsse | Kürbiskerne | 🌰 Nussfrei |
| Erdnussbutter | Sonnenblumenkernmus | 🥜 Erdnussfrei, 🌰 Nussfrei |

#### **Weitere**
| Original | Ersatzprodukte | Grund |
|----------|---------------|--------|
| Honig | Ahornsirup, Agavendicksaft | 🌱 Vegan |
| Gelatine | Agar-Agar | 🌱 Vegan |

---

## 📂 Dateistruktur

```
lib/
├── data/
│   ├── models/
│   │   ├── dietary_preference.dart      # Enums & Ersatzprodukt-DB
│   │   └── user_model.dart               # Erweitert um allergies-Feld
│   └── services/
│       ├── ingredient_substitution_service.dart  # KI-Logik
│       └── user_service.dart             # User Update
└── presentation/
    └── screens/
        └── profile/
            └── dietary_preferences_screen.dart  # UI für Präferenzen

add_allergies_migration.sql  # Supabase Migration
```

---

## 🔧 Verwendung

### 1. **Supabase Migration ausführen**
```sql
-- In Supabase SQL Editor
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS allergies TEXT[] DEFAULT '{}';
```

### 2. **User-Präferenzen setzen**
```dart
// Im Profil-Screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => DietaryPreferencesScreen(),
  ),
);
```

### 3. **Rezept anpassen**
```dart
import 'package:shoply/data/services/ingredient_substitution_service.dart';

// Rezept basierend auf User-Präferenzen anpassen
final adaptedRecipe = IngredientSubstitutionService.adaptRecipe(
  recipe: originalRecipe,
  allergies: [AllergyType.lactose, AllergyType.gluten],
  diets: [DietType.vegan],
);

// Kompatibilität prüfen
final compatibility = IngredientSubstitutionService.checkRecipeCompatibility(
  recipe: originalRecipe,
  allergies: userAllergies,
  diets: userDiets,
);

print(compatibility.badgeText); // "✅ Passend" oder "✏️ 3 Anpassungen"
```

### 4. **Detaillierte Substitutionen abrufen**
```dart
final ingredientsWithSubs = IngredientSubstitutionService
  .getIngredientsWithSubstitutions(
    ingredients: recipe.ingredients,
    allergies: [AllergyType.milk],
    diets: [DietType.vegan],
  );

for (final item in ingredientsWithSubs) {
  if (item.needsSubstitution) {
    print('${item.original.name} → ${item.bestSubstitute?.substitute}');
    print('Grund: ${item.reasons.join(", ")}');
  }
}
```

---

## 🚀 Nächste Schritte

### ✅ Abgeschlossen
1. ✅ Allergie- & Ernährungsmodelle (dietary_preference.dart)
2. ✅ Intelligenter Substitution Service
3. ✅ User Model erweitert (allergies-Feld)
4. ✅ Dietary Preferences Screen (UI)
5. ✅ SQL Migration für Supabase

### 🔄 In Arbeit
6. ⏳ **Recipe Detail Screen Integration**
   - Toggle zwischen Original/Angepasst
   - Zutaten mit Badges anzeigen (z.B. "Milch → Hafermilch 🌱")
   - Warnungen bei fehlenden Ersatzprodukten

7. ⏳ **Recipe List Screen Enhancement**
   - Badges für Kompatibilität (✅/✏️/❌)
   - Filter nach Ernährungsform & Allergien
   - Sortierung nach Passgenauigkeit

8. ⏳ **Profil-Screen Integration**
   - Link zu Dietary Preferences Screen
   - Zusammenfassung der aktuellen Präferenzen

### 📋 Zukünftige Features
- 🔍 Volltext-Suche mit Allergie-Filter
- 📊 Statistiken (Anzahl passender Rezepte)
- 🤖 ML-basierte Vorschläge für Ersatzprodukte
- 🌐 Community-Substitutionen (User können eigene hinzufügen)
- 🔔 Warnung bei versehentlicher Auswahl ungeeigneter Rezepte

---

## 💡 Beispiel-Workflow

### Szenario: Veganer mit Glutenintoleranz

**1. User setzt Präferenzen:**
```dart
user.dietPreferences = ['vegan'];
user.allergies = ['gluten', 'nuts'];
```

**2. User öffnet Rezept "Spaghetti Carbonara":**
```
Original:
- 400g Spaghetti
- 200g Pancetta
- 4 Eier
- 100g Parmesan

Angepasst:
- 400g Glutenfreie Pasta 🌾
- 200g Räuchertofu 🌱
- 4 Leinsamen-Eier (4 EL Leinsamen + 12 EL Wasser) 🌱
- 100g Hefeflocken mit Mandeln 🌱

⚠️ Hinweis: Mandeln vermeiden (Nussallergie)
Alternative: Hefeflocken pur verwenden
```

**3. Rezept zur Einkaufsliste hinzufügen:**
- Alle angepassten Zutaten werden automatisch übernommen
- User kann zwischen Original/Angepasst wählen

---

## 🧪 Testing

```dart
// Test 1: Vegane Anpassung
final veganRecipe = IngredientSubstitutionService.adaptRecipe(
  recipe: carbonara,
  diets: [DietType.vegan],
);
expect(veganRecipe.ingredients.any((i) => i.name.contains('Ei')), false);

// Test 2: Glutenfreie Anpassung
final glutenFreeRecipe = IngredientSubstitutionService.adaptRecipe(
  recipe: pizza,
  allergies: [AllergyType.gluten],
);
expect(glutenFreeRecipe.ingredients
  .any((i) => i.name.contains('Glutenfrei')), true);

// Test 3: Kompatibilitätsprüfung
final compat = IngredientSubstitutionService.checkRecipeCompatibility(
  recipe: salad,
  allergies: [AllergyType.lactose],
  diets: [DietType.vegetarian],
);
expect(compat.isCompatible, true);
```

---

## 📝 Hinweise

- **Automatische Erkennung:** Keywords in Zutatennamen lösen Substitution aus
- **Mehrfachallergien:** Alle Allergien werden berücksichtigt
- **Fallback:** Wenn kein Ersatz gefunden wird, bleibt Original mit Warnung
- **Mengen bleiben erhalten:** `200g Milch` → `200g Hafermilch`
- **Erweiterbar:** Neue Ersatzprodukte können leicht hinzugefügt werden

---

## 🤝 Beitragen

Neue Ersatzprodukte hinzufügen in `lib/data/models/dietary_preference.dart`:

```dart
'NeueZutat': [
  IngredientSubstitution(
    original: 'NeueZutat',
    substitute: 'Ersatzprodukt',
    reason: 'Beschreibung',
    avoidsAllergies: [AllergyType.xxx],
    suitableFor: [DietType.yyy],
  ),
],
```

---

## 📚 Ressourcen

- [EU-Verordnung 1169/2011](https://eur-lex.europa.eu/legal-content/DE/TXT/?uri=CELEX:32011R1169) - EU-14 Allergene
- [DAAB](https://www.daab.de/) - Deutscher Allergie- und Asthmabund
- [Vegan Society](https://www.vegansociety.com/) - Vegane Ersatzprodukte

---

**Status:** ✅ Core-Features implementiert | 🔄 Integration läuft | 📋 Testing ausstehend
