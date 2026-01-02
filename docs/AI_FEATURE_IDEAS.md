# AI Feature Ideas for Shoply (Gemini API)

## Currently Implemented

### 1. Smart Categorization (✅ Done)
- **Service**: `GeminiCategorizationService`
- **Model**: `gemini-2.0-flash-lite` (cheapest option)
- **Feature**: Automatically categorizes shopping list items (e.g., "Apples" → Fruits & Vegetables)
- **Cost**: ~$0.075 per 1M input tokens

### 2. Ingredient Parsing (✅ Done)
- **Method**: `parseIngredient()`
- **Feature**: Extracts name, amount, and unit from free-text input
- **Example**: "2 cups flour" → {name: "flour", amount: 2, unit: "cups"}
- **Fallback**: Regex patterns for offline support

### 3. Recipe Tag Generation (✅ Done)
- **Method**: `generateRecipeTags()`
- **Feature**: Auto-generates tags for new recipes (cuisine, diet, meal type)
- **Use case**: When users create recipes, tags are automatically assigned

---

## Recommended AI Features (Easy to Implement)

### 4. Smart Recipe Suggestions
**Effort**: Medium | **Value**: High
```dart
/// Suggest recipes based on what ingredients user has
Future<List<String>> suggestRecipesFromIngredients(List<String> availableIngredients)
```
- User inputs what they have in fridge
- AI suggests matching recipes from database
- Prioritizes recipes with highest ingredient match %

### 5. Ingredient Substitutions
**Effort**: Low | **Value**: High
```dart
/// Suggest alternatives for missing/allergenic ingredients
Future<List<String>> suggestSubstitutions(String ingredient, {List<String>? allergies})
```
- "No eggs? Try: banana, applesauce, flax eggs"
- Considers user allergies/preferences

### 6. Meal Planning Assistant
**Effort**: Medium | **Value**: Very High
```dart
/// Generate weekly meal plan based on preferences
Future<Map<String, List<Recipe>>> generateMealPlan({
  required int days,
  required List<String> dietPreferences,
  required int budget, // optional
})
```
- Creates balanced weekly meal plans
- Considers nutritional variety
- Generates consolidated shopping list

### 7. Recipe Scaling Intelligence
**Effort**: Low | **Value**: Medium
```dart
/// Smart scaling with cooking adjustments
Future<Map<String, dynamic>> smartScaleRecipe(Recipe recipe, int newServings)
```
- Not just math: "If doubling, don't double salt"
- Adjusts cooking times for larger portions
- Warns about pan size requirements

---

## Advanced AI Features (Higher Effort)

### 8. Recipe Image Analysis
**Effort**: High | **Value**: High
```dart
/// Extract recipe from photo of dish or handwritten recipe
Future<Recipe> extractRecipeFromImage(File imageFile)
```
- Analyze food photos to identify dish
- Extract text from handwritten recipe cards
- Suggest matching recipes from database

### 9. Nutritional Analysis
**Effort**: Medium | **Value**: High
```dart
/// Calculate nutrition facts for recipe
Future<NutritionInfo> analyzeNutrition(Recipe recipe)
```
- Estimate calories, macros, vitamins
- Flag potential allergens
- Compare to daily recommended values

### 10. Voice Recipe Assistant
**Effort**: High | **Value**: Very High
```dart
/// Hands-free cooking mode
Future<String> handleVoiceCommand(String command, Recipe currentRecipe)
```
- "What's the next step?"
- "How much flour do I need?"
- "Set timer for 15 minutes"
- "Add milk to shopping list"

### 11. Smart Shopping List Optimization
**Effort**: Medium | **Value**: High
```dart
/// Optimize shopping route by store layout
Future<List<ShoppingItem>> optimizeShoppingList(List<ShoppingItem> items)
```
- Group by store aisle/section
- Suggest store with best prices
- Identify sales on needed items

### 12. Recipe Creator from Description
**Effort**: Medium | **Value**: High
```dart
/// Generate full recipe from simple description
Future<Recipe> createRecipeFromDescription(String description)
```
- "Quick pasta with chicken and sun-dried tomatoes"
- Generates complete recipe with ingredients/instructions
- User can edit and save

---

## Cost Optimization Tips

### Model Selection
| Model | Cost (1M tokens) | Best For |
|-------|------------------|----------|
| gemini-2.0-flash-lite | $0.075 in / $0.30 out | Simple categorization |
| gemini-1.5-flash | $0.15 in / $0.60 out | Complex reasoning |
| gemini-1.5-pro | $1.25 in / $5.00 out | Avoid unless necessary |

### Caching Strategy
- Cache all API responses locally
- Use SharedPreferences for persistence
- Implement TTL (e.g., 30 days for categories)

### Rate Limiting
- Implement 1-second delay between calls
- Batch similar requests when possible
- Use offline fallbacks for common cases

### Fallback Patterns
- Always have keyword-based fallback
- Train regex patterns on common inputs
- Cache successful API responses

---

## Implementation Priority

### Phase 1 (Quick Wins)
1. ✅ Smart Categorization
2. ✅ Ingredient Parsing
3. ✅ Recipe Tag Generation
4. 🔜 Ingredient Substitutions

### Phase 2 (High Value)
5. Smart Recipe Suggestions
6. Recipe Scaling Intelligence
7. Nutritional Analysis

### Phase 3 (Premium Features)
8. Meal Planning Assistant
9. Recipe Creator from Description
10. Voice Recipe Assistant

---

## Notes

- Always use `gemini-2.0-flash-lite` for simple tasks
- Implement robust offline fallbacks
- Cache aggressively to minimize API costs
- Consider making AI features premium/subscription
