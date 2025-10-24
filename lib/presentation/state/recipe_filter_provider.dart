import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoply/data/models/recipe.dart';
import 'package:shoply/data/models/recipe_filter.dart';

class RecipeFilterState {
  final Set<String> activeQuickFilters;
  final AdvancedFilterOptions advancedFilters;

  const RecipeFilterState({
    this.activeQuickFilters = const {},
    this.advancedFilters = const AdvancedFilterOptions(),
  });

  RecipeFilterState copyWith({
    Set<String>? activeQuickFilters,
    AdvancedFilterOptions? advancedFilters,
  }) {
    return RecipeFilterState(
      activeQuickFilters: activeQuickFilters ?? this.activeQuickFilters,
      advancedFilters: advancedFilters ?? this.advancedFilters,
    );
  }

  int get activeFilterCount {
    return activeQuickFilters.length + 
        (advancedFilters.hasActiveFilters ? 1 : 0);
  }

  bool get hasActiveFilters {
    return activeQuickFilters.isNotEmpty || advancedFilters.hasActiveFilters;
  }
}

class RecipeFilterNotifier extends StateNotifier<RecipeFilterState> {
  RecipeFilterNotifier() : super(const RecipeFilterState());

  void toggleQuickFilter(String filterId) {
    final newFilters = Set<String>.from(state.activeQuickFilters);
    if (newFilters.contains(filterId)) {
      newFilters.remove(filterId);
    } else {
      newFilters.add(filterId);
    }
    state = state.copyWith(activeQuickFilters: newFilters);
  }

  void updateAdvancedFilters(AdvancedFilterOptions options) {
    state = state.copyWith(advancedFilters: options);
  }

  void clearAllFilters() {
    state = const RecipeFilterState();
  }

  List<Recipe> getFilteredRecipes(List<Recipe> recipes) {
    if (!state.hasActiveFilters) {
      return recipes;
    }

    return recipes.where((recipe) {
      // Must match ALL active filters
      for (final filterId in state.activeQuickFilters) {
        if (!_matchesQuickFilter(recipe, filterId)) {
          return false;
        }
      }

      // Must match advanced filters
      if (!_matchesAdvancedFilters(recipe)) {
        return false;
      }

      return true;
    }).toList();
  }

  bool _matchesQuickFilter(Recipe recipe, String filterId) {
    final totalTime = recipe.prepTimeMinutes + recipe.cookTimeMinutes;
    final recipeName = recipe.name.toLowerCase();
    final ingredients = recipe.ingredients.map((i) => i.name.toLowerCase()).toList();

    switch (filterId) {
      // Popular
      case 'top-rated':
        return recipe.likes >= 5;

      // Time
      case 'quick':
        return totalTime <= 15;
      case '30min':
        return totalTime <= 30;
      case 'under-hour':
        return totalTime <= 60;

      // Diet
      case 'vegetarian':
        return !ingredients.any((i) => 
          i.contains('fleisch') || i.contains('fisch') || 
          i.contains('hähnchen') || i.contains('rind') || i.contains('schwein'));
      case 'vegan':
        return !ingredients.any((i) => 
          i.contains('fleisch') || i.contains('fisch') || 
          i.contains('milch') || i.contains('ei') || i.contains('käse') || 
          i.contains('butter') || i.contains('sahne'));
      case 'gluten-free':
        return !ingredients.any((i) => 
          i.contains('mehl') || i.contains('weizen') || 
          i.contains('brot') || i.contains('nudel'));
      case 'keto':
        return !ingredients.any((i) => 
          i.contains('zucker') || i.contains('reis') || 
          i.contains('nudel') || i.contains('kartoffel'));
      case 'low-carb':
        return !ingredients.any((i) => 
          i.contains('reis') || i.contains('nudel') || 
          i.contains('kartoffel') || i.contains('brot'));

      // Meal Type
      case 'breakfast':
        return recipeName.contains('frühstück') || recipeName.contains('müsli') || 
               recipeName.contains('pancake') || recipeName.contains('toast');
      case 'lunch':
        return recipeName.contains('mittag') || recipeName.contains('suppe') || 
               recipeName.contains('salat');
      case 'dinner':
        return recipeName.contains('abend') || recipeName.contains('braten');
      case 'snack':
        return recipeName.contains('snack') || recipeName.contains('happen');

      // Difficulty
      case 'easy':
        return recipe.ingredients.length <= 7 && recipe.instructions.length <= 5;
      case 'medium':
        return recipe.ingredients.length <= 12 && recipe.instructions.length <= 10;
      case 'advanced':
        return recipe.ingredients.length > 12 || recipe.instructions.length > 10;

      // Cuisine
      case 'italian':
        return recipeName.contains('pasta') || recipeName.contains('pizza') || 
               ingredients.any((i) => i.contains('parmesan') || i.contains('mozzarella'));
      case 'asian':
        return recipeName.contains('curry') || recipeName.contains('wok') || 
               ingredients.any((i) => i.contains('soja') || i.contains('ingwer'));
      case 'mexican':
        return recipeName.contains('taco') || recipeName.contains('burrito');
      case 'mediterranean':
        return ingredients.any((i) => i.contains('olive') || i.contains('feta'));

      default:
        return true;
    }
  }

  bool _matchesAdvancedFilters(Recipe recipe) {
    final options = state.advancedFilters;
    final totalTime = recipe.prepTimeMinutes + recipe.cookTimeMinutes;

    // Time range
    if (options.minTimeMinutes != null && totalTime < options.minTimeMinutes!) {
      return false;
    }
    if (options.maxTimeMinutes != null && totalTime > options.maxTimeMinutes!) {
      return false;
    }

    // Diet restrictions
    for (final diet in options.dietRestrictions) {
      if (!_matchesQuickFilter(recipe, diet)) {
        return false;
      }
    }

    // Meal types (OR logic - match any)
    if (options.mealTypes.isNotEmpty) {
      bool matchesAnyMealType = false;
      for (final mealType in options.mealTypes) {
        if (_matchesQuickFilter(recipe, mealType)) {
          matchesAnyMealType = true;
          break;
        }
      }
      if (!matchesAnyMealType) return false;
    }

    // Difficulty
    if (options.difficulty != null) {
      if (!_matchesQuickFilter(recipe, options.difficulty!)) {
        return false;
      }
    }

    // Cuisine types (OR logic - match any)
    if (options.cuisineTypes.isNotEmpty) {
      bool matchesAnyCuisine = false;
      for (final cuisine in options.cuisineTypes) {
        if (_matchesQuickFilter(recipe, cuisine)) {
          matchesAnyCuisine = true;
          break;
        }
      }
      if (!matchesAnyCuisine) return false;
    }

    // Servings range
    if (options.minServings != null && recipe.defaultServings < options.minServings!) {
      return false;
    }
    if (options.maxServings != null && recipe.defaultServings > options.maxServings!) {
      return false;
    }

    // Include ingredients
    if (options.includeIngredients.isNotEmpty) {
      final ingredients = recipe.ingredients.map((i) => i.name.toLowerCase()).toList();
      for (final required in options.includeIngredients) {
        if (!ingredients.any((i) => i.contains(required.toLowerCase()))) {
          return false;
        }
      }
    }

    // Exclude ingredients
    if (options.excludeIngredients.isNotEmpty) {
      final ingredients = recipe.ingredients.map((i) => i.name.toLowerCase()).toList();
      for (final excluded in options.excludeIngredients) {
        if (ingredients.any((i) => i.contains(excluded.toLowerCase()))) {
          return false;
        }
      }
    }

    // High protein
    if (options.highProtein) {
      final ingredients = recipe.ingredients.map((i) => i.name.toLowerCase()).toList();
      if (!ingredients.any((i) => 
        i.contains('hähnchen') || i.contains('fisch') || 
        i.contains('ei') || i.contains('tofu') || i.contains('quark'))) {
        return false;
      }
    }

    // Low calorie
    if (options.lowCalorie) {
      final ingredients = recipe.ingredients.map((i) => i.name.toLowerCase()).toList();
      if (!ingredients.any((i) => i.contains('gemüse') || i.contains('salat'))) {
        return false;
      }
    }

    // High fiber
    if (options.highFiber) {
      final ingredients = recipe.ingredients.map((i) => i.name.toLowerCase()).toList();
      if (!ingredients.any((i) => i.contains('vollkorn') || i.contains('haferflocken'))) {
        return false;
      }
    }

    return true;
  }
}

final recipeFilterProvider = StateNotifierProvider<RecipeFilterNotifier, RecipeFilterState>((ref) {
  return RecipeFilterNotifier();
});
