# Shoply - AI Agent Instructions

## ⚠️ CRITICAL: AI-Specific Directives

**This file is optimized for AI code assistants. Follow these rules strictly:**

1. **ALWAYS verify builds** after ANY code change - DO NOT skip this step
2. **ALWAYS check Data Models Location Map** before importing models
3. **ALWAYS follow Refactoring Checklist** when extracting widgets
4. **NEVER assume file locations** - use grep or check maps
5. **NEVER reduce rate limit delays** - they are hard requirements
6. **NEVER make multiple changes** without building between them

**If you encounter an error pattern listed in "Common Pitfalls", follow the exact solution steps.**

## Project Overview
**Shoply** is a Flutter shopping list app with premium features, AI-powered categorization, recipe integration, and social sharing. The app targets iOS/Android with a Supabase backend and uses Riverpod for state management.

## Architecture

### Tech Stack
- **Frontend**: Flutter 3.5+ (Material 3, adaptive_platform_ui for iOS 26 styling)
- **State Management**: Riverpod (Provider pattern, FutureProvider, StreamProvider)
- **Backend**: Supabase (Auth, PostgreSQL, Edge Functions, Storage)
- **Navigation**: go_router with auth state refreshing
- **AI**: Google Gemini 1.5-flash for smart categorization (cost-optimized with local cache)
- **Monetization**: in_app_purchase (iOS only, Android pending)

### Project Structure
```
lib/
├── core/               # Config, constants, theme, localization
├── data/
│   ├── models/        # Data models (UserModel, RecipeModel, etc.)
│   ├── repositories/  # Data access layer (ItemRepository, ListRepository)
│   └── services/      # Business logic (SubscriptionService, GeminiCategorizationService)
├── presentation/
│   ├── screens/       # Feature-based screens (home/, recipes/, ai/, profile/)
│   ├── widgets/       # Reusable UI components
│   ├── state/         # Riverpod providers (auth_provider, lists_provider)
│   └── routes/        # app_router.dart
└── main.dart          # App initialization
```

### Critical Services (with Import Patterns)

**SupabaseService** (`lib/data/services/supabase_service.dart`):
```dart
import 'package:shoply/data/services/supabase_service.dart';
// Access: SupabaseService.instance.currentUser
// Usage: SupabaseService.instance.client.from('table_name')
```

**SubscriptionService** (`lib/data/services/subscription_service.dart`):
```dart
import 'package:shoply/data/services/subscription_service.dart';
// Usage: await SubscriptionService().getSubscription()
// Check premium: subscription.isPremium
```

**GeminiCategorizationService** (`lib/data/services/gemini_categorization_service.dart`):
```dart
import 'package:shoply/data/services/gemini_categorization_service.dart';
// Usage: await GeminiCategorizationService().categorizeItem('milk')
// ⚠️ Rate-limited to 1 req/sec, check cache first via SharedPreferences
```

**AnalyticsService** (`lib/data/services/analytics_service.dart`):
```dart
import 'package:shoply/data/services/analytics_service.dart';
// Usage: AnalyticsService.instance.logScreenView()
// ⚠️ iOS/Android only - check platform before using
```

### Data Models Location Map

**⚠️ CRITICAL FOR AI: Model classes are NOT always in files named after the class!**

**ALWAYS check this map BEFORE importing a model. DO NOT assume file location.**

| Model Class | Actual File Location | Import Statement |
|-------------|---------------------|------------------|
| `Ingredient` | `lib/data/models/recipe.dart` | `import 'package:shoply/data/models/recipe.dart';` |
| `Recipe` | `lib/data/models/recipe.dart` | `import 'package:shoply/data/models/recipe.dart';` |
| `ShoppingItem` | `lib/data/models/shopping_item_model.dart` | `import 'package:shoply/data/models/shopping_item_model.dart';` |
| `ShoppingList` | `lib/data/models/shopping_list_model.dart` | `import 'package:shoply/data/models/shopping_list_model.dart';` |
| `UserModel` | `lib/data/models/user_model.dart` | `import 'package:shoply/data/models/user_model.dart';` |
| `DietaryPreference` | `lib/data/models/dietary_preference.dart` | `import 'package:shoply/data/models/dietary_preference.dart';` |
| `IngredientSubstitution` | `lib/data/models/dietary_preference.dart` | `import 'package:shoply/data/models/dietary_preference.dart';` |

**If model not in map**:
```bash
grep -r "class ClassName" lib/data/models/
```

**COMMON AI ERROR**: Importing `Ingredient` from `ingredient.dart` - THIS FILE DOES NOT EXIST. Use `recipe.dart`.

## AI Execution Patterns

### Pattern 1: Import a Model Class

**WRONG (causes errors)**:
```dart
// ❌ Assumption: class name = file name
import 'package:shoply/data/models/ingredient.dart';
```

**CORRECT (check map first)**:
```dart
// 1. Check Data Models Location Map above
// 2. See: Ingredient → lib/data/models/recipe.dart
// 3. Use correct import:
import 'package:shoply/data/models/recipe.dart';  // ✅
```

### Pattern 2: Extract a Widget

**Execute in this EXACT order**:
```bash
# 1. Analyze current file
wc -l lib/presentation/screens/feature/screen.dart
grep "class _" lib/presentation/screens/feature/screen.dart

# 2. Check decision tree: Is widget >100 lines? → Extract

# 3. Identify imports needed
grep "^import" lib/presentation/screens/feature/screen.dart
# Check Data Models Location Map for any model imports

# 4. Create new widget file with ALL imports
# create_file: lib/presentation/screens/feature/widgets/widget_name.dart

# 5. Update parent file: add import, change _Widget → Widget, remove old class

# 6. CRITICAL: Verify build
flutter build ios --simulator --debug 2>&1 | tail -20
# Look for: "✓ Built build/ios/iphonesimulator/Runner.app"

# 7. If build fails, stop and fix before proceeding
```

### Pattern 3: Add Rate-Limited API Calls

**Template for adding items with Gemini categorization**:
```dart
for (int i = 0; i < items.length; i++) {
  final item = items[i];
  
  // Add item (triggers AI categorization)
  await repository.addItem(item);
  
  // CRITICAL: Wait 1.1s for Gemini rate limit
  // DO NOT reduce this delay
  if (i < items.length - 1) {
    await Future.delayed(const Duration(milliseconds: 1100));
  }
}
```

### Pattern 4: Verify After Every Change

**After ANY code modification**:
```bash
# 1. Build
flutter build ios --simulator --debug 2>&1 | tail -20

# 2. Check output
if contains "✓ Built build/ios/iphonesimulator/Runner.app":
    ✅ Success - continue with next step
else:
    ❌ Failed - read error message
    - Check for "No such file" → Wrong model import (check map)
    - Check for "Type not found" → Missing import
    - Fix error
    - Rebuild
    - DO NOT proceed until build succeeds
```

### Pattern 5: Commit with Metrics

**Always include before/after metrics**:
```bash
# 1. Count lines
wc -l original_file.dart new_file1.dart new_file2.dart

# 2. Calculate reduction
# Before: 1524 lines
# After: 1298 lines
# Reduction: 226 lines, 15%

# 3. Commit with metrics
git add file1.dart file2.dart file3.dart
git commit -m "refactor: Extract WidgetName from ScreenName (1524→1298 lines, -15%)"
git push origin main
```

## Development Workflows

### Building & Running
```bash
# Standard Flutter commands
flutter clean && flutter pub get
flutter run -d <device-id>

# iOS Simulator (workaround for code signing issues)
cd ios && pod install
cd .. && flutter build ios --debug --simulator
xcrun simctl install <simulator-id> ios/build/Build/Products/Debug-iphonesimulator/Runner.app
xcrun simctl launch --console <simulator-id> com.dominik.shoply

# Physical iOS device
flutter run -d <device-id> --release
```

**⚠️ CRITICAL: Always Verify Builds After Changes**
After ANY code change, you MUST verify the build succeeds by running:
```bash
cd /Users/jannisdietrich/Documents/shoply
flutter build ios --simulator --debug 2>&1 | tail -20
```
Look for `Xcode build done.` followed by success message. If you see `Failed to build iOS app`, extract the error and fix it immediately. DO NOT proceed with other changes until the build succeeds.

### Common Issues
1. **iOS build failures**: Many packages (mobile_scanner, google_sign_in, local_auth) are commented out in `pubspec.yaml` due to macOS/iOS compatibility issues. Don't re-enable without testing.
2. **adaptive_platform_ui conflicts**: iOS 26 Liquid Glass styling is handled by this package. Avoid modifying its cached files in `.pub-cache/`.
3. **Git push errors**: Use `git reset HEAD && git add <specific-files> && git commit -m "msg" && git push origin main` to avoid pushing sensitive files.

### Testing Premium Features
- iOS IAP only works on **real devices** (not simulator)
- Sandbox accounts required for testing subscriptions
- Premium features are gated via `SubscriptionService.isPremium` checks
- Trial activation: `SubscriptionService().activateTrial()` (14-day free trial)

## Conventions & Patterns

### Riverpod Providers
- Use **FutureProvider** for one-time async data fetching (e.g., `currentUserProvider`)
- Use **StreamProvider** for real-time updates (e.g., `authUserProvider` from Supabase auth stream)
- Use **Provider** for singletons (e.g., `listRepositoryProvider`)
- Access providers via `ref.watch()` in widgets, `ref.read()` in callbacks

Example from `lib/presentation/screens/recipes/recipe_detail_screen.dart`:
```dart
final user = ref.watch(currentUserProvider).value;
final listsAsync = ref.watch(userListsProvider);
```

### Supabase Patterns
- **Auth**: Always check `SupabaseService.instance.currentUser` before authenticated operations
- **RLS**: All tables use Row Level Security; user-specific data filters by `auth.uid()`
- **Realtime**: Use `.stream()` for live updates (e.g., shopping list items)
- **Storage**: `list-backgrounds` bucket for user-uploaded images (requires manual setup)

### Premium Feature Gating
Check subscription status before premium features:
```dart
final subscription = await SubscriptionService().getSubscription();
if (!subscription.isPremium) {
  showModalBottomSheet(
    context: context,
    builder: (_) => PaywallModal(featureName: 'Feature Name'),
  );
  return;
}
```

### AI Categorization
- **Always check cache first**: `GeminiCategorizationService()._categoryCache`
- **Rate limiting**: 1 API call per second enforced
- **Fallback**: Keyword matching via `ProductClassifierService` if Gemini fails
- **Cost optimization**: Cache results in SharedPreferences (survives app restarts)

### Navigation
- Use named routes via `context.go('/route-name')` or `context.push('/route-name')`
- Auth redirects handled by `GoRouterRefreshStream` in `lib/routes/app_router.dart`
- StatefulShellRoute with bottom nav: `MainScaffold` wraps home/recipes/ai/profile tabs

### UI/UX Conventions
- **Theme**: `AppTheme.lightTheme` / `AppTheme.darkTheme` (Material 3)
- **Colors**: `AppColors.lightAccent`, `AppColors.premiumGold` (constants in `lib/core/constants/`)
- **Spacing**: Use `AppDimensions.paddingLarge`, `AppDimensions.spacingMedium`
- **Text Styles**: `AppTextStyles.h1`, `AppTextStyles.bodyMedium`
- **iOS 26 Styling**: Prefer `AdaptiveAlertDialog`, `AdaptiveTextField` from `adaptive_platform_ui`

### Widget File Organization

**Screen-Specific Widgets**:
- **Location**: `lib/presentation/screens/<feature>/widgets/`
- **Examples**:
  - `lib/presentation/screens/home/widgets/list_card_with_animation.dart`
  - `lib/presentation/screens/recipes/widgets/select_list_bottom_sheet.dart`
- **Naming**: Descriptive, action-oriented (e.g., `background_selection_sheet.dart`)

**Shared Widgets**:
- **Location**: `lib/presentation/widgets/<category>/`
- **Categories**: `common/`, `subscription/`, `recipes/`, `recommendations/`
- **Examples**:
  - `lib/presentation/widgets/common/empty_state.dart`
  - `lib/presentation/widgets/subscription/paywall_modal.dart`

**When to Extract a Widget**:
1. Widget > 50 lines AND used in multiple places → Extract to `widgets/<category>/`
2. Widget > 100 lines (single use) → Extract to `screens/<feature>/widgets/`
3. Private class (`_ClassName`) > 150 lines → Always extract

**Widget File Template**:
```dart
import 'package:flutter/material.dart';
// ... other imports in standard order (see Import Order below)

/// Brief description of what this widget does and when to use it.
/// 
/// Example usage:
/// ```dart
/// WidgetName(
///   requiredParam: 'value',
/// )
/// ```
class WidgetName extends StatelessWidget {
  final String requiredParam;
  
  const WidgetName({
    super.key,
    required this.requiredParam,
  });
  
  @override
  Widget build(BuildContext context) {
    // Implementation
  }
}
```

### Standard Import Order

**Always follow this order to maintain consistency**:

```dart
// 1. Dart core libraries
import 'dart:ui';
import 'dart:async';

// 2. Flutter framework packages
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 3. Third-party packages (alphabetical)
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

// 4. App imports (grouped by layer)
// Core layer
import 'package:shoply/core/constants/app_colors.dart';
import 'package:shoply/core/constants/app_dimensions.dart';
import 'package:shoply/core/localization/app_localizations.dart';

// Data layer
import 'package:shoply/data/models/recipe.dart';
import 'package:shoply/data/repositories/item_repository.dart';
import 'package:shoply/data/services/supabase_service.dart';

// Presentation layer
import 'package:shoply/presentation/state/auth_provider.dart';
import 'package:shoply/presentation/state/lists_provider.dart';
import 'package:shoply/presentation/widgets/common/loading_indicator.dart';
```

## Integration Points

### Supabase Database Schema
Key tables (see `database/migrations/`):
- **users**: Auth + subscription columns (`subscription_tier`, `subscription_status`, `subscription_expires_at`)
- **shopping_lists**: Lists with background customization (`background_type`, `background_color`, `background_image_url`)
- **list_items**: Items with AI-categorized `category` field
- **recipes**: Community recipes with ratings
- **subscription_transactions**: IAP purchase audit trail

### Edge Functions
- **expire-subscriptions**: Daily cron job to update expired subscriptions
  - Deployed at: `https://rtwzzerhgieyxsijemsd.supabase.co/functions/v1/expire-subscriptions`
  - Test via: `curl -X POST <url> -H "Authorization: Bearer <anon-key>"`

### Environment Configuration
`lib/core/config/env.dart` contains **sensitive keys** (committed for simplicity):
- Supabase URL/keys
- Gemini API key
- Google OAuth client IDs

**NEVER push changes that expose these in logs/screenshots.**

### Cross-Component Communication
- **Shopping list → Recipe**: Add recipe ingredients via `ItemRepository.addItems()`
- **AI categorization**: Called on item creation in `ItemRepository`
- **Analytics**: Track screen views via `AnalyticsService.instance.logScreenView()` (iOS/Android only)

## Key Files Reference
- **App entry**: `lib/main.dart` (initializes services)
- **Routes**: `lib/routes/app_router.dart` (90+ routes)
- **Auth state**: `lib/presentation/state/auth_provider.dart`
- **Shopping lists**: `lib/data/repositories/list_repository.dart`
- **Subscription logic**: `lib/data/services/subscription_service.dart` (465 lines)
- **Paywall UI**: `lib/presentation/widgets/subscription/paywall_modal.dart`
- **AI categorization**: `lib/data/services/gemini_categorization_service.dart`

## Status & Known Issues
- ✅ **Completed**: Recipe system, iOS subscriptions, AI categorization, premium UI
- ⚠️ **Partial**: Android IAP not implemented, simulator testing limited
- 🚫 **Disabled**: OCR/scanner features removed (see `IMPLEMENTATION_STATUS.md`)
- 📋 **Manual Setup Required**: App Store IAP products, Supabase storage bucket (see `MANUAL_SETUP_REQUIRED.md`)

## Testing Strategy
- **Unit tests**: Not implemented (focus on manual testing)
- **iOS device testing**: Required for IAP, camera, biometrics
- **Supabase testing**: Use SQL migrations in `database/migrations/` to replicate schema

## Tips for AI Agents
1. **Before editing `pubspec.yaml`**: Check comments—many packages are disabled for compatibility
2. **iOS builds failing?**: Check terminal history for Xcode errors; often requires `pod install` or `flutter clean`
3. **Adding premium features?**: Gate with `SubscriptionService.isPremium`, add to `PaywallModal` benefits list
4. **Modifying categories?**: Update both `lib/core/constants/categories.dart` AND Gemini prompt in `GeminiCategorizationService`
5. **Supabase migrations?**: Run SQL in Supabase dashboard, then document in `database/migrations/`

## Common Pitfalls & Solutions

### AI Error Pattern 1: Wrong Model Import
**Symptom**: `Error: Error when reading 'lib/data/models/ingredient.dart': No such file`
**Root Cause**: AI assumes model class name = file name
**Solution**: ALWAYS check Data Models Location Map first. `Ingredient` is in `recipe.dart`.
**Prevention**: Before any import, check the map above.

### AI Error Pattern 2: Missing Imports After Widget Extraction
**Symptom**: `Error: Type 'ClassName' not found` after extracting widget
**Root Cause**: Forgot to copy imports from original file
**Solution**: 
1. Open original file
2. Run: `grep "^import" original_file.dart`
3. Copy ALL imports that the extracted widget uses
4. Check Data Models Location Map for any model imports
**Prevention**: Use the Refactoring Checklist below (step: "Add ALL necessary imports")

### AI Error Pattern 3: Private Class Name Kept After Extraction
**Symptom**: Build succeeds but widget not found when trying to use it
**Root Cause**: Class still has `_` prefix (private) after extraction
**Solution**: 
1. Change `class _WidgetName` → `class WidgetName`
2. Update ALL usages: `_WidgetName(` → `WidgetName(`
**Prevention**: Use the Refactoring Checklist (step: "Make class public")

### AI Error Pattern 4: Rate Limiting Not Respected
**Symptom**: "429 Too Many Requests" errors from Gemini API
**Root Cause**: Removed or reduced the 1.1s delay between API calls
**Solution**: Keep delays at 1100ms minimum. This is NOT a performance issue, it's a hard requirement.
**Prevention**: Never modify delays in recipe ingredient addition code.

### AI Error Pattern 5: Build Not Verified Before Continuing
**Symptom**: Multiple files broken, unclear which change caused the issue
**Root Cause**: Made several changes without building between them
**Solution**: 
1. Stop all other work
2. Run: `flutter build ios --simulator --debug 2>&1 | tail -30`
3. Read ENTIRE error message
4. Fix the error
5. Rebuild to verify
6. Only then continue with other changes
**Prevention**: Use Refactoring Checklist (step: "Build verification - CRITICAL")

## Refactoring Checklist

### Before Starting Widget Extraction
- [ ] Read entire file to understand dependencies
- [ ] Identify all imports the widget needs
- [ ] Check Data Models Location Map for any model imports
- [ ] Note current file line count: `wc -l path/to/file.dart`
- [ ] Identify all private classes (`_ClassName`) > 100 lines

### During Widget Extraction
- [ ] Create new file in correct location (see Widget File Organization)
- [ ] Add doc comment explaining widget purpose and usage
- [ ] Copy widget code preserving exact formatting
- [ ] Add ALL necessary imports (check original file)
- [ ] Make class public: `_ClassName` → `ClassName`
- [ ] Update parent file:
  - [ ] Add import: `import 'package:shoply/presentation/screens/<feature>/widgets/<file>.dart';`
  - [ ] Change all usages: `_ClassName(` → `ClassName(`
  - [ ] Remove old class definition (entire class block)

### After Widget Extraction
- [ ] **CRITICAL**: Build verification
  ```bash
  flutter build ios --simulator --debug 2>&1 | tail -20
  ```
- [ ] Check for success: `✓ Built build/ios/iphonesimulator/Runner.app`
- [ ] If build fails:
  - [ ] Read error message carefully
  - [ ] Check for missing imports (most common issue)
  - [ ] Verify model imports use correct file (check Location Map)
  - [ ] Fix and rebuild - DO NOT proceed until build succeeds
- [ ] Count lines to verify reduction:
  ```bash
  wc -l lib/presentation/screens/<feature>/<screen>.dart
  ```
- [ ] Git add ONLY the files you changed:
  ```bash
  git add file1.dart file2.dart file3.dart
  ```
- [ ] Commit with metrics:
  ```bash
  git commit -m "refactor: Extract WidgetName from ScreenName (before→after lines, -N%)"
  ```
- [ ] Push to verify CI/CD:
  ```bash
  git push origin main
  ```

## Quick Reference Commands

### Search & Navigation
```bash
# Find model class location
grep -r "class ModelName" lib/data/models/

# Find all usages of a widget
grep -r "WidgetName(" lib/presentation/

# Check imports in a file
grep "^import" lib/path/to/file.dart

# Find files by name pattern
find lib -name "*recipe*.dart"
```

### File Analysis
```bash
# Count lines in file
wc -l lib/presentation/screens/feature/screen.dart

# Count lines in multiple files
wc -l file1.dart file2.dart file3.dart

# Find large files (>500 lines)
find lib/presentation/screens -name "*.dart" -exec wc -l {} \; | sort -rn | head -20
```

### Build & Verification
```bash
# Fast build verification (recommended)
flutter build ios --simulator --debug 2>&1 | tail -20

# Full build (if needed)
flutter clean && flutter pub get && flutter build ios --simulator --debug

# Check for build errors only
flutter build ios --simulator --debug 2>&1 | grep -E "Error|Failed|error:"
```

### Git Operations
```bash
# Add specific files only (RECOMMENDED)
git add lib/path/file1.dart lib/path/file2.dart
git commit -m "descriptive message"
git push origin main

# Check what would be committed
git status
git diff --cached

# Undo last add (before commit)
git reset HEAD

# Check recent commits
git log --oneline -5
```

## Decision Trees for Common Scenarios

### "Should I extract this widget?"

```
Is it a private class (_ClassName)?
├─ YES: How many lines?
│   ├─ >150 lines → ALWAYS extract to feature/widgets/
│   ├─ 100-150 lines + complex logic → Extract to feature/widgets/
│   ├─ 50-100 lines:
│   │   ├─ Used in multiple files? → Extract to widgets/common/
│   │   └─ Single use + simple? → Keep inline (for now)
│   └─ <50 lines → Keep inline
└─ NO: Is it already in widgets/ folder?
    └─ YES: Is it used across features?
        ├─ YES + currently in feature/widgets/ → Move to widgets/common/
        └─ NO → Keep in feature/widgets/
```

### "Where should this extracted widget go?"

```
Is the widget used in multiple features/screens?
├─ YES → lib/presentation/widgets/<category>/
│   ├─ Common UI (buttons, cards, dialogs) → widgets/common/
│   ├─ Subscription/paywall related → widgets/subscription/
│   ├─ Recipe display/interaction → widgets/recipes/
│   └─ ML/recommendations → widgets/recommendations/
│
└─ NO → Is it specific to one screen/feature?
    └─ YES → lib/presentation/screens/<feature>/widgets/
        Examples:
        ├─ Home screen widgets → screens/home/widgets/
        ├─ Recipe detail widgets → screens/recipes/widgets/
        └─ List detail widgets → screens/lists/widgets/
```

### "How do I find a model class?"

```
1. Check obvious location first:
   lib/data/models/<model_name>.dart
   ├─ Found? → Use it ✓
   └─ Not found? → Continue to step 2

2. Check Data Models Location Map in this file
   ├─ Found in map? → Use that file path ✓
   └─ Not in map? → Continue to step 3

3. Search all model files:
   grep -r "class ClassName" lib/data/models/
   ├─ Found? → Note the file path, use it ✓
   │           Consider adding to Location Map!
   └─ Still not found? → Continue to step 4

4. Check if it's a nested class:
   - Ingredient is inside recipe.dart
   - IngredientSubstitution is inside dietary_preference.dart
   → Import the parent model file
```

### "Build failed - what do I do?"

```
1. Read the FULL error message (last 30 lines):
   flutter build ios --simulator --debug 2>&1 | tail -30

2. Identify error type:
   ├─ "Error: Error when reading 'lib/data/models/X.dart': No such file"
   │   → Check Data Models Location Map
   │   → The model is in a different file
   │   → Fix import path
   │
   ├─ "Error: Type 'ClassName' not found"
   │   → Missing import in extracted widget
   │   → Copy import from original file
   │
   ├─ "Error: 'MethodName' isn't defined for the class"
   │   → Missing dependency (service, repository, etc.)
   │   → Check what the widget actually needs
   │   → Add missing import
   │
   ├─ "error: no such module 'ModuleName'" (Xcode error)
   │   → Run: cd ios && pod install && cd ..
   │   → Then rebuild
   │
   └─ Other compilation errors
       → Read carefully, usually points to exact line
       → Check for typos in widget name changes

3. Fix and verify:
   - Make the fix
   - Rebuild immediately
   - DO NOT make other changes until build succeeds

4. If still failing after fix:
   - Try: flutter clean && flutter pub get
   - Then: flutter build ios --simulator --debug
```

## Code Documentation Standards (AI-Optimized)

### File-Level Documentation Template

**Every new file should start with this**:

```dart
/// [One-line description]
///
/// **AI: Required Imports** (check Data Models Location Map first):
/// - `package:shoply/data/models/recipe.dart` (for Ingredient, Recipe)
/// - `package:shoply/presentation/state/lists_provider.dart`
///
/// **AI: Critical Constraints**:
/// - ⚠️ Rate limit: 1 req/sec for Gemini API (1.1s delay required)
/// - ⚠️ Platform: iOS/Android only (check Platform.isIOS before using)
/// - ⚠️ Network: Requires active internet connection
///
/// **AI: Usage Template**:
/// ```dart
/// // Copy-paste this exact pattern
/// final widget = WidgetName(
///   requiredParam: 'value',
/// );
/// ```
///
/// **AI: Common Mistakes**:
/// - ❌ Don't reduce delay below 1100ms
/// - ❌ Don't assume Ingredient is in ingredient.dart (it's in recipe.dart)
/// - ❌ Don't skip build verification after changes
```

### Inline Comment Standards

**Rate Limiting / Delays** - Always explain WHY:
```dart
// Wait 1.1 seconds to comply with Gemini API rate limit (1 req/sec)
// This prevents "429 Too Many Requests" errors
await Future.delayed(const Duration(milliseconds: 1100));
```

**Platform-Specific Code** - Document which platforms:
```dart
// iOS only: Analytics requires Firebase which doesn't work on web
if (Platform.isIOS || Platform.isAndroid) {
  AnalyticsService.instance.logEvent('recipe_viewed');
}
```

**Workarounds** - Explain problem and solution:
```dart
// WORKAROUND: adaptive_platform_ui has bug in dark mode on iOS 26
// Force light mode until fixed in v2.0
// See: https://github.com/package/issue/123
// TODO: Remove when fixed
```

**Constants** - Mark hard requirements:
```dart
/// ⚠️ AI: DO NOT modify - Gemini API hard requirement
/// Rate limit: 60 req/min = 1 req/sec, using 1.1s for safety
static const Duration apiCallDelay = Duration(milliseconds: 1100);
```

### Debug Logging Standards

**Use consistent prefixes**:
```dart
debugPrint('🔵 [FEATURE] General flow/info');
debugPrint('✅ [FEATURE] Success');
debugPrint('❌ [FEATURE] Error');
debugPrint('⚠️ [FEATURE] Warning');
```

**Example**:
```dart
debugPrint('🔵 [RECIPE] Starting to add ${ingredients.length} ingredients');
debugPrint('✅ [RECIPE] Successfully added "${ingredient.name}" (${duration}ms)');
debugPrint('❌ [RECIPE] Failed to add "${ingredient.name}": $error');
```
