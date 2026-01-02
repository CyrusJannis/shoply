# Code Documentation Standards

## Purpose
This guide ensures all code in the Shoply project is well-documented for human developers and AI assistants.

## General Principles

1. **Write for the next developer** (human or AI) who has never seen this code
2. **Explain WHY, not just WHAT** - The code shows what it does, comments explain why
3. **Document gotchas and non-obvious behavior** - Rate limits, special cases, workarounds
4. **Keep docs close to code** - Comments should be right where they're needed
5. **Update docs when code changes** - Stale docs are worse than no docs

## File-Level Documentation

Every file should start with a documentation block:

```dart
/// [Brief one-line description of file's purpose]
///
/// This file contains [detailed explanation of what's in the file].
///
/// **Key Features**:
/// - Feature 1: Description
/// - Feature 2: Description
///
/// **Dependencies**:
/// - Service/Provider dependencies that are critical to understand
///
/// **Usage Example**:
/// ```dart
/// // Example of how to use the main class/function
/// ```
///
/// **Important Notes**:
/// - Any gotchas, rate limits, platform-specific behavior
///
/// See also:
/// - Related files or documentation
```

### Example:

```dart
/// Widget for selecting gradient backgrounds for shopping lists.
///
/// This bottom sheet provides a 3-column grid of gradient options
/// that users can select to customize their list's appearance.
/// Selection is saved immediately to the database.
///
/// **Key Features**:
/// - 3-column grid layout with gradient previews
/// - Haptic feedback on selection
/// - Immediate database persistence
/// - Auto-closes after successful save
///
/// **Dependencies**:
/// - Requires `listsNotifierProvider` to save background
/// - Uses `ListBackgroundGradients` constants for gradient definitions
///
/// **Usage Example**:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   builder: (context) => BackgroundSelectionSheet(listId: listId),
/// );
/// ```
///
/// **Important Notes**:
/// - Only works with gradient backgrounds (not solid colors or images)
/// - Requires valid listId that exists in database
```

## Class Documentation

### Widget Classes

```dart
/// [One-line description of what this widget displays/does]
///
/// [Detailed description including when to use this widget,
/// what data it displays, and any important behavior]
///
/// **Parameters**:
/// - `param1`: Description of what this is and valid values
/// - `param2`: Description including any constraints or special handling
///
/// **State Management**:
/// - Providers used: `providerName` - what data it provides
///
/// **Example**:
/// ```dart
/// WidgetName(
///   param1: 'value',
///   param2: 42,
/// )
/// ```
///
/// See also: [Related widgets or documentation]
class WidgetName extends StatelessWidget {
  /// [Description of this parameter and its purpose]
  /// 
  /// Valid values: [constraints or examples]
  final String param1;
  
  /// [Description including any special behavior]
  ///
  /// Default: [default value if optional]
  final int param2;
  
  const WidgetName({
    super.key,
    required this.param1,
    this.param2 = 0,
  });
  
  @override
  Widget build(BuildContext context) {
    // Implementation
  }
}
```

### Service Classes

```dart
/// [One-line description of service's responsibility]
///
/// This service handles [detailed explanation of business logic].
///
/// **Responsibilities**:
/// - Responsibility 1
/// - Responsibility 2
///
/// **Dependencies**:
/// - External service/API dependencies
/// - Other internal services
///
/// **Rate Limits / Constraints**:
/// - Any API rate limits
/// - Platform-specific behavior
/// - Performance considerations
///
/// **Usage**:
/// ```dart
/// final service = ServiceName();
/// final result = await service.method();
/// ```
///
/// **Error Handling**:
/// - What exceptions can be thrown
/// - How errors should be handled
class ServiceName {
  // Implementation
}
```

### Model/Data Classes

```dart
/// [One-line description of what this model represents]
///
/// This model represents [detailed domain explanation].
///
/// **Fields**:
/// - `field1`: Description and valid values
/// - `field2`: Description including any business rules
///
/// **Database Mapping**:
/// - Table: `table_name`
/// - Key relationships: References to other tables
///
/// **Validation Rules**:
/// - Any constraints or validation logic
///
/// **Example**:
/// ```dart
/// final model = ModelName(
///   field1: 'value',
///   field2: 42,
/// );
/// ```
class ModelName {
  // Implementation
}
```

## Method Documentation

### Public Methods

```dart
/// [One-line description of what this method does]
///
/// [Detailed explanation including side effects, async behavior,
/// database operations, API calls, etc.]
///
/// **Parameters**:
/// - `param1`: Description and valid values
/// - `param2`: Description of purpose
///
/// **Returns**:
/// - Description of return value and possible states
///
/// **Throws**:
/// - `ExceptionType`: When this is thrown
///
/// **Side Effects**:
/// - Database writes
/// - API calls
/// - State changes
///
/// **Example**:
/// ```dart
/// final result = await methodName('value', 42);
/// ```
///
/// **Important**:
/// - Rate limits, caching behavior, or other gotchas
Future<ReturnType> methodName(String param1, int param2) async {
  // Implementation
}
```

### Private/Helper Methods

```dart
/// [Brief description of helper's purpose]
///
/// Called by: [Which public methods use this]
///
/// Note: [Any important implementation details]
void _helperMethod() {
  // Implementation
}
```

## Inline Comments

### When to Add Inline Comments

✅ **DO add comments for**:
- Complex business logic
- Non-obvious workarounds
- Performance optimizations
- Platform-specific code
- Rate limiting / delays
- Regex patterns or complex calculations
- TODOs with context

❌ **DON'T add comments for**:
- Obvious code (e.g., `// Set the name` above `name = value;`)
- Self-explanatory variable names
- Standard Flutter patterns

### Good Inline Comments

```dart
// Wait 1.1 seconds between API calls to respect Gemini's 1 req/sec rate limit
await Future.delayed(const Duration(milliseconds: 1100));

// Calculate text color based on background luminance
// Dark backgrounds need white text, light backgrounds need black text
final luminance = backgroundColor.computeLuminance();
final textColor = luminance > 0.5 ? Colors.black : Colors.white;

// HACK: iOS 26 simulator requires skipping code signing
// Remove this for production builds on physical devices
if (Platform.isIOS && kDebugMode) {
  // Skip signing
}

// TODO(jannis): Replace with proper pagination when recipe count > 100
// Current implementation loads all recipes at once (acceptable for MVP)
final recipes = await _recipeService.getAllRecipes();
```

### Section Comments

For long methods, use section comments:

```dart
Future<void> addIngredientsToList() async {
  // === Validation ===
  if (ingredients.isEmpty) return;
  
  // === Prepare batch operation ===
  final items = ingredients.map((i) => ShoppingItem(...)).toList();
  
  // === Execute with rate limiting ===
  for (final item in items) {
    await _addWithDelay(item);
  }
  
  // === Update UI state ===
  ref.invalidate(listsProvider);
}
```

## Constants and Configuration

```dart
/// Maximum number of items to show before pagination
///
/// Current limit is based on typical shopping list size.
/// May need adjustment if users create very large lists.
static const int maxItemsPerPage = 50;

/// Gemini API rate limit in requests per second
///
/// According to Google Cloud documentation, Gemini 1.5-flash
/// has a rate limit of 60 requests per minute (1 req/sec).
/// We use 1.1s to add safety margin.
static const Duration apiCallDelay = Duration(milliseconds: 1100);

/// Background gradient options for shopping lists
///
/// Each gradient is defined by 2+ colors and a direction.
/// Gradient names are user-facing and should be localized.
/// 
/// To add new gradient:
/// 1. Add to this map with unique key
/// 2. Add localized name to app_localizations.dart
/// 3. Update BackgroundSelectionSheet if needed
static const Map<String, Gradient> gradients = {
  'sunset': LinearGradient(...),
  // ...
};
```

## Special Cases

### Rate Limiting / Delays

Always explain WHY there's a delay:

```dart
// Wait 1.1 seconds to comply with Gemini API rate limit (1 req/sec)
// This prevents "429 Too Many Requests" errors
await Future.delayed(const Duration(milliseconds: 1100));
```

### Platform-Specific Code

Always document which platforms and why:

```dart
// iOS only: Analytics requires Firebase which doesn't work on web
if (Platform.isIOS || Platform.isAndroid) {
  AnalyticsService.instance.logEvent('recipe_viewed');
}
```

### Workarounds

Explain the problem and the workaround:

```dart
// WORKAROUND: adaptive_platform_ui has a bug where it doesn't
// properly handle dark mode on iOS 26. Force light mode for now.
// See: https://github.com/package/issue/123
// TODO: Remove when fixed in adaptive_platform_ui v2.0
```

### TODOs

Always include context:

```dart
// TODO(jannis): Implement pagination when recipe count exceeds 100
// Current approach loads all recipes which is fine for MVP but won't
// scale. Need to add cursor-based pagination with Supabase.

// TODO(premium): Gate this feature behind subscription check
// Should show PaywallModal if user is not premium
```

## Debug Logging

Use consistent prefixes and meaningful messages:

```dart
// Good debug logs
debugPrint('🔵 [RECIPE] Starting to add ${ingredients.length} ingredients');
debugPrint('✅ [RECIPE] Successfully added "${ingredient.name}" (${duration}ms)');
debugPrint('❌ [RECIPE] Failed to add "${ingredient.name}": $error');
debugPrint('⚠️ [RECIPE] Rate limit approaching, added delay');

// Bad debug logs
debugPrint('here');  // Too vague
debugPrint('error: $e');  // No context
debugPrint('test');  // Not helpful for production debugging
```

### Log Prefixes

- 🔵 `[FEATURE]` - General flow/info
- ✅ `[FEATURE]` - Success
- ❌ `[FEATURE]` - Error
- ⚠️ `[FEATURE]` - Warning
- 🔧 `[FEATURE]` - Debug/development only

## Examples of Well-Documented Code

### Example 1: Service Method

```dart
/// Categorizes a shopping item using AI with local caching.
///
/// First checks local SharedPreferences cache to avoid unnecessary API calls.
/// If not cached, calls Gemini AI to categorize the item, then caches result.
/// Falls back to keyword matching if AI categorization fails.
///
/// **Parameters**:
/// - `itemName`: The name of the shopping item to categorize (e.g., "milk")
///
/// **Returns**:
/// - Category string matching one of the predefined categories in `Categories.all`
/// - Falls back to "Other" if categorization fails completely
///
/// **Rate Limiting**:
/// - Respects Gemini's 1 request/second limit via internal throttling
/// - Use cache hit rate to minimize API calls (currently ~80% hit rate)
///
/// **Caching**:
/// - Cache key: `category_cache_${itemName.toLowerCase()}`
/// - Cache duration: Permanent (cleared only on app reinstall)
/// - Cache is case-insensitive
///
/// **Example**:
/// ```dart
/// final category = await GeminiCategorizationService().categorizeItem('milk');
/// // Returns: "Dairy & Eggs"
/// ```
///
/// **Performance**:
/// - Cached: <10ms
/// - Uncached: 500-2000ms (network dependent)
///
/// See also:
/// - `ProductClassifierService` for fallback keyword matching
/// - `Categories.all` for list of valid categories
Future<String> categorizeItem(String itemName) async {
  // === Check cache first (fast path) ===
  final cached = await _getCachedCategory(itemName);
  if (cached != null) {
    debugPrint('✅ [CATEGORIZATION] Cache hit for "$itemName": $cached');
    return cached;
  }
  
  // === AI categorization (slow path) ===
  try {
    debugPrint('🔵 [CATEGORIZATION] Calling Gemini API for "$itemName"');
    
    final category = await _callGeminiAPI(itemName);
    
    // Cache successful result
    await _cacheCategory(itemName, category);
    
    debugPrint('✅ [CATEGORIZATION] AI categorized "$itemName": $category');
    return category;
    
  } catch (e) {
    debugPrint('❌ [CATEGORIZATION] AI failed for "$itemName": $e');
    
    // === Fallback to keyword matching ===
    final fallbackCategory = ProductClassifierService().classify(itemName);
    debugPrint('⚠️ [CATEGORIZATION] Using fallback for "$itemName": $fallbackCategory');
    
    return fallbackCategory;
  }
}
```

### Example 2: Widget with Complex Logic

```dart
/// Bottom sheet for selecting shopping lists to add recipe ingredients.
///
/// Displays all user's shopping lists with item count preview.
/// Handles adding ingredients with proper rate limiting and error handling.
/// Shows progress feedback and allows creating new lists.
///
/// **Key Features**:
/// - Displays all available shopping lists
/// - Shows how many ingredients will be added
/// - Adds ingredients with 1.1s delay (Gemini rate limit)
/// - Comprehensive error handling with user feedback
/// - Allows creating new list if none exist
///
/// **Parameters**:
/// - `ingredients`: List of recipe ingredients to add to selected list
///
/// **Dependencies**:
/// - Requires `userListsProvider` to fetch user's lists
/// - Uses `ItemRepository` to add items to database
/// - Requires user to be authenticated (checked via Supabase)
///
/// **Rate Limiting**:
/// - Adds 1.1s delay between each ingredient to respect Gemini's
///   1 request/second limit for AI categorization
/// - For 10 ingredients, expect ~11 seconds total
///
/// **Error Handling**:
/// - Shows success snackbar if all ingredients added
/// - Shows warning if some failed (with list of failures)
/// - Shows error if all failed (with first error message)
/// - Individual failures don't stop the batch process
///
/// **Usage Example**:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   builder: (context) => SelectListBottomSheet(
///     ingredients: recipe.ingredients,
///   ),
/// );
/// ```
///
/// **Important Notes**:
/// - Requires active internet for AI categorization
/// - Closes automatically after successful list selection
/// - Does NOT validate ingredient quantities (handled by ItemRepository)
///
/// See also:
/// - `ItemRepository.addItem()` for individual item addition
/// - `GeminiCategorizationService` for AI categorization details
class SelectListBottomSheet extends ConsumerWidget {
  /// List of recipe ingredients to add to the selected shopping list.
  ///
  /// Each ingredient should have at minimum:
  /// - `name`: Required, non-empty string
  /// - `amount`: Optional, defaults to empty string
  /// - `unit`: Optional, defaults to empty string
  final List<Ingredient> ingredients;
  
  const SelectListBottomSheet({
    super.key,
    required this.ingredients,
  });
  
  // ... rest of implementation
}
```

## Migration Guide

When updating existing code:

1. **Start with critical files**: Services, repositories, complex widgets
2. **Don't rewrite everything**: Focus on complex/confusing parts
3. **Add file-level docs first**: Quick wins, high value
4. **Document as you refactor**: Perfect time to add explanations
5. **Explain the "why"**: Especially for workarounds and gotchas

## Tools for Maintaining Documentation

### Pre-commit Checklist

Before committing code, ask:
- [ ] Does my new file have a file-level doc comment?
- [ ] Do new public methods have doc comments?
- [ ] Did I explain any non-obvious logic?
- [ ] Did I update docs if I changed behavior?
- [ ] Are my debug logs clear and contextual?

### Documentation Debt

Keep a list of files that need better docs:
- High complexity, low documentation → Prioritize
- Frequently modified files → Document well
- Files new developers struggle with → Add examples

## Benefits

**For Developers**:
- Faster onboarding
- Less time asking "what does this do?"
- Easier debugging
- Confident refactoring

**For AI Assistants**:
- Better context for suggestions
- Fewer incorrect assumptions
- Faster problem resolution
- More accurate code generation

**For Project**:
- Higher code quality
- Easier maintenance
- Better collaboration
- Knowledge preservation
