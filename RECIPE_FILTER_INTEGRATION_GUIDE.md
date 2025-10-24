# Recipe Filter Integration - Step-by-Step Guide

**File:** `lib/presentation/screens/recipes/recipes_screen.dart`  
**Backup:** `lib/presentation/screens/recipes/recipes_screen.dart.backup` ✅  
**Status:** Ready for manual integration  
**Time Required:** 1-2 hours

---

## ⚠️ Important Notes

1. **Backup exists** at `recipes_screen.dart.backup`
2. **File is 885 lines** - large and complex
3. **Test after each step** to catch errors early
4. **All filter components are built and ready**
5. **Provider system is complete**

---

## 📋 Step-by-Step Instructions

### Step 1: Update Imports (Lines 1-13)

**Current:**
```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shoply/core/constants/app_colors.dart';
import 'package:shoply/core/constants/app_dimensions.dart';
import 'package:shoply/core/constants/app_text_styles.dart';
import 'package:shoply/data/models/recipe.dart';
import 'package:shoply/data/services/recipe_service.dart';
import 'package:shoply/core/localization/localization_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';

class RecipesScreen extends StatefulWidget {
```

**Replace with:**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shoply/core/constants/app_colors.dart';
import 'package:shoply/core/constants/app_dimensions.dart';
import 'package:shoply/core/constants/app_text_styles.dart';
import 'package:shoply/data/models/recipe.dart';
import 'package:shoply/data/services/recipe_service.dart';
import 'package:shoply/core/localization/localization_helper.dart';
import 'package:shoply/presentation/state/recipe_filter_provider.dart';
import 'package:shoply/presentation/widgets/recipes/quick_filters_row.dart';
import 'package:shoply/presentation/widgets/recipes/advanced_filters_modal.dart';
import 'package:cached_network_image/cached_network_image.dart';

class RecipesScreen extends ConsumerStatefulWidget {
```

---

### Step 2: Update Class Declaration (Lines 11-22)

**Current:**
```dart
class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  final _recipeService = RecipeService();
  List<Recipe> _recipes = [];
  List<Recipe> _filteredRecipes = [];
  bool _isLoading = true;
  String _searchQuery = '';
  Set<String> _selectedFilters = {};
  String _sortBy = 'newest';
```

**Replace with:**
```dart
class RecipesScreen extends ConsumerStatefulWidget {
  const RecipesScreen({super.key});

  @override
  ConsumerState<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends ConsumerState<RecipesScreen> {
  final _recipeService = RecipeService();
  List<Recipe> _recipes = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _sortBy = 'newest';
```

**Note:** Removed `_filteredRecipes` and `_selectedFilters` - now handled by provider

---

### Step 3: Update _loadRecipes Method (Lines 35-53)

**Current:**
```dart
Future<void> _loadRecipes() async {
  setState(() => _isLoading = true);
  try {
    final recipes = await _recipeService.getRecipes();
    setState(() {
      _recipes = recipes;
      _filteredRecipes = recipes;
      _isLoading = false;
    });
    _applyFilter();
  } catch (e) {
    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading recipes: $e')),
      );
    }
  }
}
```

**Replace with:**
```dart
Future<void> _loadRecipes() async {
  setState(() => _isLoading = true);
  try {
    final recipes = await _recipeService.getRecipes();
    setState(() {
      _recipes = recipes;
      _isLoading = false;
    });
  } catch (e) {
    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading recipes: $e')),
      );
    }
  }
}
```

---

### Step 4: Add New Filter Methods (After _loadRecipes)

**Add these new methods:**
```dart
List<Recipe> _getFilteredRecipes() {
  // Apply filters from provider
  final filteredRecipes = ref.read(recipeFilterProvider.notifier).getFilteredRecipes(_recipes);
  
  // Apply sorting
  final sorted = List<Recipe>.from(filteredRecipes);
  _applySorting(sorted);
  return sorted;
}

void _applySorting(List<Recipe> recipes) {
  switch (_sortBy) {
    case 'newest':
      recipes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      break;
    case 'oldest':
      recipes.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      break;
    case 'rating-high':
      recipes.sort((a, b) {
        final likesCompare = b.likes.compareTo(a.likes);
        if (likesCompare != 0) return likesCompare;
        return b.createdAt.compareTo(a.createdAt);
      });
      break;
    case 'rating-low':
      recipes.sort((a, b) {
        final likesCompare = a.likes.compareTo(b.likes);
        if (likesCompare != 0) return likesCompare;
        return b.createdAt.compareTo(a.createdAt);
      });
      break;
  }
}
```

---

### Step 5: Delete Old Filter Methods (Lines 55-255)

**Delete these entire methods:**
- `_applyFilter()` (lines 55-102)
- `_applySorting()` (lines 104-129) - duplicate, keep the new one from Step 4
- `_matchesFilter()` (lines 131-255) - 200+ lines of filter logic

**These are replaced by the provider's `getFilteredRecipes()` method**

---

### Step 6: Update AppBar (Lines 278-296)

**Current:**
```dart
appBar: AppBar(
  title: Text(context.tr('recipes'), style: AppTextStyles.h2),
  actions: [
    IconButton(
      icon: const Icon(Icons.search),
      onPressed: () => _showSearchDialog(),
    ),
    IconButton(
      icon: const Icon(Icons.add),
      onPressed: () => context.push('/recipes/add'),
    ),
  ],
),
```

**Replace with:**
```dart
appBar: AppBar(
  title: Text(context.tr('recipes'), style: AppTextStyles.h2),
  actions: [
    IconButton(
      icon: const Icon(Icons.search),
      onPressed: () => _showSearchDialog(),
    ),
    Consumer(
      builder: (context, ref, child) {
        final filterState = ref.watch(recipeFilterProvider);
        return IconButton(
          icon: Badge(
            label: Text('${filterState.activeFilterCount}'),
            isLabelVisible: filterState.hasActiveFilters,
            child: const Icon(Icons.filter_list_rounded),
          ),
          onPressed: () => _showAdvancedFilters(),
        );
      },
    ),
    IconButton(
      icon: const Icon(Icons.add),
      onPressed: () => context.push('/recipes/add'),
    ),
  ],
),
```

---

### Step 7: Update Body (Lines 297-365)

**Current:**
```dart
body: Column(
  children: [
    // Filter Button
    Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showFilterDialog(),
              icon: Icon(
                Icons.filter_list,
                color: _selectedFilters.isEmpty ? null : AppColors.info,
              ),
              label: Text(
                _selectedFilters.isEmpty 
                    ? context.tr('filter') 
                    : context.tr('filters_active', params: {'count': '${_selectedFilters.length}'}),
                // ... more code
              ),
            ),
          ),
          if (_selectedFilters.isNotEmpty) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                setState(() => _selectedFilters.clear());
                _applyFilter();
              },
              icon: const Icon(Icons.clear),
              tooltip: context.tr('clear_all_filters'),
            ),
          ],
        ],
      ),
    ),
    const Divider(height: 1),
    // Recipes List
    Expanded(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredRecipes.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadRecipes,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(
                      left: AppDimensions.paddingMedium,
                      right: AppDimensions.paddingMedium,
                      top: AppDimensions.paddingMedium,
                      bottom: 120,
                    ),
                    itemCount: _filteredRecipes.length,
                    itemBuilder: (context, index) {
                      return _RecipeCard(
                        recipe: _filteredRecipes[index],
                        onTap: () => context.push('/recipes/${_filteredRecipes[index].id}'),
                        onLike: () => _toggleLike(_filteredRecipes[index]),
                      );
                    },
                  ),
                ),
    ),
  ],
),
```

**Replace with:**
```dart
body: Column(
  children: [
    // Quick Filters Row
    const QuickFiltersRow(),
    const Divider(height: 1),
    // Recipes List
    Expanded(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _getFilteredRecipes().isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadRecipes,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(
                      left: AppDimensions.paddingMedium,
                      right: AppDimensions.paddingMedium,
                      top: AppDimensions.paddingMedium,
                      bottom: 120,
                    ),
                    itemCount: _getFilteredRecipes().length,
                    itemBuilder: (context, index) {
                      final filteredRecipes = _getFilteredRecipes();
                      return _RecipeCard(
                        recipe: filteredRecipes[index],
                        onTap: () => context.push('/recipes/${filteredRecipes[index].id}'),
                        onLike: () => _toggleLike(filteredRecipes[index]),
                      );
                    },
                  ),
                ),
    ),
  ],
),
```

---

### Step 8: Add _showAdvancedFilters Method (After build method)

**Add this new method:**
```dart
void _showAdvancedFilters() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const AdvancedFiltersModal(),
  );
}
```

---

### Step 9: Delete Old Filter Dialog Methods (Lines 368-507)

**Delete these entire methods:**
- `_buildFilterSectionDialog()` (lines 368-391)
- `_buildSortChip()` (lines 393-415)
- `_buildFilterChipDialog()` (lines 417-444)
- `_showFilterDialog()` (lines 489-507)

**These are replaced by the AdvancedFiltersModal component**

---

### Step 10: Update _buildEmptyState Method (Lines 446-487)

**Current:**
```dart
Widget _buildEmptyState() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.restaurant_menu,
          size: 80,
          color: Colors.grey,
        ),
        const SizedBox(height: AppDimensions.spacingMedium),
        Text(
          context.tr('no_recipes_yet'),
          style: AppTextStyles.h2,
        ),
        const SizedBox(height: AppDimensions.spacingSmall),
        Text(
          context.tr('add_your_first_recipe'),
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.spacingMedium),
        ElevatedButton.icon(
          onPressed: () => context.push('/recipes/add'),
          icon: const Icon(Icons.add),
          label: Text(context.tr('add_recipe')),
        ),
      ],
    ),
  );
}
```

**Replace with:**
```dart
Widget _buildEmptyState() {
  final filterState = ref.watch(recipeFilterProvider);
  final hasFilters = filterState.hasActiveFilters;

  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.restaurant_menu,
          size: 80,
          color: Colors.grey,
        ),
        const SizedBox(height: AppDimensions.spacingMedium),
        Text(
          hasFilters ? context.tr('no_recipes_found') : context.tr('no_recipes_yet'),
          style: AppTextStyles.h2,
        ),
        const SizedBox(height: AppDimensions.spacingSmall),
        Text(
          hasFilters
              ? context.tr('try_other_filters_or_add_recipe')
              : context.tr('add_your_first_recipe'),
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.spacingMedium),
        if (hasFilters)
          ElevatedButton(
            onPressed: () {
              ref.read(recipeFilterProvider.notifier).clearAllFilters();
            },
            child: Text(context.tr('clear_all_filters')),
          )
        else
          ElevatedButton.icon(
            onPressed: () => context.push('/recipes/add'),
            icon: const Icon(Icons.add),
            label: Text(context.tr('add_recipe')),
          ),
      ],
    ),
  );
}
```

---

### Step 11: Delete _FilterScreen Class (Lines 557-757)

**Delete the entire `_FilterScreen` class and `_FilterScreenState` class**

This is 200 lines of old filter UI that's replaced by `AdvancedFiltersModal`

---

### Step 12: Keep _RecipeCard Class (Lines 759-850)

**No changes needed** - this widget is fine as-is

---

## ✅ Testing Checklist

After completing all steps:

1. **Compile Check**
   ```bash
   flutter analyze lib/presentation/screens/recipes/recipes_screen.dart
   ```

2. **Run App**
   ```bash
   flutter run
   ```

3. **Test Quick Filters**
   - [ ] Quick filters display at top
   - [ ] Tapping filter activates it
   - [ ] Multiple filters work together
   - [ ] Filters update recipe list

4. **Test Advanced Filters**
   - [ ] Badge shows filter count
   - [ ] Modal opens on button tap
   - [ ] All filter options work
   - [ ] Apply button works
   - [ ] Clear all works

5. **Test Empty State**
   - [ ] Shows "no recipes" when empty
   - [ ] Shows "no results" when filtered
   - [ ] Clear filters button appears
   - [ ] Add recipe button works

6. **Test Search**
   - [ ] Search still works
   - [ ] Combines with filters

7. **Test Sorting**
   - [ ] Newest/oldest works
   - [ ] Rating high/low works

---

## 📊 Summary

**Lines to Delete:** ~400 lines
**Lines to Add:** ~100 lines
**Net Change:** -300 lines (cleaner code!)

**Before:** 885 lines
**After:** ~585 lines

**Old System:**
- Custom filter logic (200+ lines)
- Custom filter dialog (200+ lines)
- State management in widget

**New System:**
- Provider-based filtering
- Reusable filter components
- Centralized state management

---

## 🆘 If You Get Stuck

1. **Restore backup:**
   ```bash
   cp lib/presentation/screens/recipes/recipes_screen.dart.backup lib/presentation/screens/recipes/recipes_screen.dart
   ```

2. **Check this guide** - follow steps exactly

3. **Test after each step** - don't do all at once

4. **Check provider file** - `lib/presentation/state/recipe_filter_provider.dart`

5. **Check widget files:**
   - `lib/presentation/widgets/recipes/quick_filters_row.dart`
   - `lib/presentation/widgets/recipes/advanced_filters_modal.dart`

---

## 🎯 Success Criteria

When done correctly:
- ✅ No compile errors
- ✅ App runs without crashes
- ✅ Quick filters display and work
- ✅ Advanced filters modal opens
- ✅ Filters actually filter recipes
- ✅ Empty state shows correctly
- ✅ Badge shows filter count

---

**Good luck! Take your time and test after each step. 🚀**
