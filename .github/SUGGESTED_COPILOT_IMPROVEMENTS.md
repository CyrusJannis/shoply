# Suggested Improvements to Copilot Instructions

## 1. Add "Common Pitfalls & Solutions" Section

Add this after "Tips for AI Agents":

```markdown
## Common Pitfalls & Solutions

### Import Errors
**Problem**: Model classes are not always in files named after the class.
**Solutions**:
- `Ingredient` class → `lib/data/models/recipe.dart` (not ingredient.dart)
- `ShoppingItem` → `lib/data/models/shopping_item_model.dart`
- Always search for `class ClassName` in `lib/data/models/*.dart` before assuming file location

### Widget Extraction Pattern
When extracting widgets from large files:
1. **Create widget file first** in `lib/presentation/screens/<feature>/widgets/`
2. **Add all necessary imports** (check original file for dependencies)
3. **Make class public** (remove leading `_` from class name)
4. **Update parent file**:
   - Add import: `import 'package:shoply/presentation/screens/<feature>/widgets/<widget_file>.dart';`
   - Change `_WidgetName(` → `WidgetName(` (all usages)
   - Remove old class definition
5. **Verify build**: `flutter build ios --simulator --debug 2>&1 | tail -20`
6. **Commit immediately** with descriptive message

### Import Order (Standard Pattern)
```dart
// 1. Dart core
import 'dart:ui';
import 'dart:async';

// 2. Flutter framework
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 3. Third-party packages (alphabetical)
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// 4. App imports (grouped)
// Core
import 'package:shoply/core/constants/app_colors.dart';
import 'package:shoply/core/constants/app_dimensions.dart';
// Data
import 'package:shoply/data/models/recipe.dart';
import 'package:shoply/data/services/supabase_service.dart';
// Presentation
import 'package:shoply/presentation/state/auth_provider.dart';
import 'package:shoply/presentation/widgets/common/loading_indicator.dart';
```
```

## 2. Add "Data Model Location Map"

Add this to "Architecture" section:

```markdown
### Data Models Location Map
Common models and their actual file locations:

| Model Class | File Location | Notes |
|-------------|---------------|-------|
| `Ingredient` | `lib/data/models/recipe.dart` | Part of Recipe model |
| `Recipe` | `lib/data/models/recipe.dart` | Main + Ingredient classes |
| `ShoppingItem` | `lib/data/models/shopping_item_model.dart` | Main item model |
| `ShoppingList` | `lib/data/models/shopping_list_model.dart` | List model |
| `UserModel` | `lib/data/models/user_model.dart` | User profile |
| `DietaryPreference` | `lib/data/models/dietary_preference.dart` | Diet + substitutions |

**Search pattern**: If model not found, use:
```bash
grep -r "class ClassName" lib/data/models/
```
```

## 3. Add "Widget Organization Standards"

Add to "Conventions & Patterns":

```markdown
### Widget File Organization

**Screen-Specific Widgets**:
- Location: `lib/presentation/screens/<feature>/widgets/`
- Examples:
  - `lib/presentation/screens/home/widgets/list_card_with_animation.dart`
  - `lib/presentation/screens/recipes/widgets/select_list_bottom_sheet.dart`
- Naming: Descriptive, action-oriented (e.g., `background_selection_sheet.dart`)

**Shared Widgets**:
- Location: `lib/presentation/widgets/<category>/`
- Categories: `common/`, `subscription/`, `recipes/`, `recommendations/`
- Examples:
  - `lib/presentation/widgets/common/empty_state.dart`
  - `lib/presentation/widgets/subscription/paywall_modal.dart`

**When to Extract**:
- Widget > 50 lines AND used in multiple places → Extract to shared
- Widget > 100 lines → Extract to feature-specific widgets/
- Private class (`_ClassName`) > 150 lines → Always extract

**Widget File Template**:
```dart
import 'package:flutter/material.dart';
// ... other imports

/// Brief description of what this widget does
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
```

## 4. Add "Refactoring Checklist"

Add new section before "Tips for AI Agents":

```markdown
## Refactoring Checklist

### Before Starting
- [ ] Read entire file to understand context
- [ ] Identify all dependencies (imports, providers, models)
- [ ] Check for private classes that should be extracted
- [ ] Note current line count for metrics

### During Extraction
- [ ] Create new widget file with all necessary imports
- [ ] Make class public (remove `_` prefix)
- [ ] Add doc comment explaining widget purpose
- [ ] Copy exact code (preserve whitespace/formatting)
- [ ] Update parent file imports
- [ ] Change all `_WidgetName` → `WidgetName` usages
- [ ] Remove old class definition from parent file

### After Extraction
- [ ] Build verification: `flutter build ios --simulator --debug 2>&1 | tail -20`
- [ ] Check for "✓ Built build/ios/iphonesimulator/Runner.app"
- [ ] Count lines: `wc -l <files>` to verify reduction
- [ ] Git add ONLY affected files (no auto-add)
- [ ] Commit with metrics: "refactor: Extract X from Y (before→after lines, -N%)"
- [ ] Push immediately to verify CI/CD passes

### Error Recovery
If build fails:
1. Read full error message (last 30 lines)
2. Common causes:
   - Missing import in extracted widget
   - Model class in unexpected file (search with grep)
   - Typo in widget name (case-sensitive)
3. Fix and rebuild immediately
4. DO NOT proceed with other changes until build succeeds
```

## 5. Add "Quick Reference Commands"

Add to "Development Workflows":

```markdown
### Quick Reference Commands

**Search for model class**:
```bash
grep -r "class ModelName" lib/data/models/
```

**Find widget usages**:
```bash
grep -r "WidgetName(" lib/presentation/
```

**Check file size**:
```bash
wc -l lib/presentation/screens/feature/screen.dart
```

**Verify build (fast)**:
```bash
flutter build ios --simulator --debug 2>&1 | tail -20
```

**Git add specific files only**:
```bash
git add file1.dart file2.dart file3.dart
git commit -m "message"
git push origin main
```

**Check imports in file**:
```bash
grep "^import" lib/path/to/file.dart
```
```

## 6. Add "Decision Trees"

Add new section for common scenarios:

```markdown
## AI Decision Trees

### "Should I extract this widget?"

```
Is it a private class (_ClassName)?
├─ YES: Is it > 100 lines?
│   ├─ YES: Extract to feature/widgets/
│   └─ NO: Is it used in multiple places?
│       ├─ YES: Extract to widgets/common/
│       └─ NO: Leave inline
└─ NO: Is it in widgets/ already?
    └─ YES: Check if it should move to common/
```

### "Where should this widget file go?"

```
Is it used across multiple features?
├─ YES: lib/presentation/widgets/<category>/
│   Categories: common/, subscription/, recipes/
└─ NO: Is it specific to one screen?
    └─ YES: lib/presentation/screens/<feature>/widgets/
```

### "How to find a model class?"

```
1. Check lib/data/models/<model_name>.dart
   ├─ Found? Use it
   └─ Not found? ↓
2. Search: grep -r "class ClassName" lib/data/models/
   ├─ Found in another file? Note location in instructions
   └─ Still not found? ↓
3. Check if it's part of another model (e.g., Ingredient in recipe.dart)
   └─ Import the parent model file
```
```

## 7. Update "Critical Services" with Import Examples

Replace current "Critical Services" with:

```markdown
### Critical Services (with Import Patterns)

**SupabaseService** (`lib/data/services/supabase_service.dart`):
```dart
import 'package:shoply/data/services/supabase_service.dart';
// Access: SupabaseService.instance.currentUser
```

**SubscriptionService** (`lib/data/services/subscription_service.dart`):
```dart
import 'package:shoply/data/services/subscription_service.dart';
// Usage: await SubscriptionService().getSubscription()
```

**GeminiCategorizationService** (`lib/data/services/gemini_categorization_service.dart`):
```dart
import 'package:shoply/data/services/gemini_categorization_service.dart';
// Note: Rate-limited to 1 req/sec, check cache first
```

**AnalyticsService** (`lib/data/services/analytics_service.dart`):
```dart
import 'package:shoply/data/services/analytics_service.dart';
// Usage: AnalyticsService.instance.logScreenView()
// iOS/Android only - check platform before using
```
```
