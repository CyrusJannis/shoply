import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoply/data/models/recipe.dart';

/// Service for caching recipes offline
class OfflineCacheService {
  static final OfflineCacheService instance = OfflineCacheService._();
  OfflineCacheService._();

  static const String _cachedRecipesKey = 'cached_recipes';
  static const String _cachedSavedRecipeIdsKey = 'cached_saved_recipe_ids';
  static const String _lastSyncKey = 'last_cache_sync';
  static const Duration _cacheExpiry = Duration(hours: 24);

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // =============================================
  // RECIPE CACHING
  // =============================================

  /// Cache a list of recipes
  Future<void> cacheRecipes(List<Recipe> recipes) async {
    try {
      final prefs = await _preferences;
      final recipesJson = recipes.map((r) => jsonEncode(r.toJson())).toList();
      await prefs.setStringList(_cachedRecipesKey, recipesJson);
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
      print('✅ [OFFLINE] Cached ${recipes.length} recipes');
    } catch (e) {
      print('❌ [OFFLINE] Error caching recipes: $e');
    }
  }

  /// Get cached recipes
  Future<List<Recipe>> getCachedRecipes() async {
    try {
      final prefs = await _preferences;
      final recipesJson = prefs.getStringList(_cachedRecipesKey);
      
      if (recipesJson == null || recipesJson.isEmpty) {
        return [];
      }

      final recipes = recipesJson.map((json) {
        final map = jsonDecode(json) as Map<String, dynamic>;
        return Recipe.fromJson(map);
      }).toList();

      print('📦 [OFFLINE] Loaded ${recipes.length} cached recipes');
      return recipes;
    } catch (e) {
      print('❌ [OFFLINE] Error loading cached recipes: $e');
      return [];
    }
  }

  /// Cache a single recipe (for viewed recipes)
  Future<void> cacheRecipe(Recipe recipe) async {
    try {
      final prefs = await _preferences;
      final key = 'recipe_${recipe.id}';
      await prefs.setString(key, jsonEncode(recipe.toJson()));
      print('✅ [OFFLINE] Cached recipe: ${recipe.name}');
    } catch (e) {
      print('❌ [OFFLINE] Error caching recipe: $e');
    }
  }

  /// Get a single cached recipe by ID
  Future<Recipe?> getCachedRecipe(String recipeId) async {
    try {
      final prefs = await _preferences;
      final key = 'recipe_$recipeId';
      final json = prefs.getString(key);
      
      if (json == null) return null;

      final map = jsonDecode(json) as Map<String, dynamic>;
      return Recipe.fromJson(map);
    } catch (e) {
      print('❌ [OFFLINE] Error loading cached recipe: $e');
      return null;
    }
  }

  // =============================================
  // SAVED RECIPES CACHING
  // =============================================

  /// Cache saved recipe IDs
  Future<void> cacheSavedRecipeIds(Set<String> ids) async {
    try {
      final prefs = await _preferences;
      await prefs.setStringList(_cachedSavedRecipeIdsKey, ids.toList());
      print('✅ [OFFLINE] Cached ${ids.length} saved recipe IDs');
    } catch (e) {
      print('❌ [OFFLINE] Error caching saved recipe IDs: $e');
    }
  }

  /// Get cached saved recipe IDs
  Future<Set<String>> getCachedSavedRecipeIds() async {
    try {
      final prefs = await _preferences;
      final ids = prefs.getStringList(_cachedSavedRecipeIdsKey);
      return ids?.toSet() ?? {};
    } catch (e) {
      return {};
    }
  }

  // =============================================
  // CACHE MANAGEMENT
  // =============================================

  /// Check if cache is expired
  Future<bool> isCacheExpired() async {
    try {
      final prefs = await _preferences;
      final lastSyncStr = prefs.getString(_lastSyncKey);
      
      if (lastSyncStr == null) return true;

      final lastSync = DateTime.parse(lastSyncStr);
      return DateTime.now().difference(lastSync) > _cacheExpiry;
    } catch (e) {
      return true;
    }
  }

  /// Get last sync time
  Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await _preferences;
      final lastSyncStr = prefs.getString(_lastSyncKey);
      if (lastSyncStr == null) return null;
      return DateTime.parse(lastSyncStr);
    } catch (e) {
      return null;
    }
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    try {
      final prefs = await _preferences;
      final keys = prefs.getKeys().where((k) => 
        k.startsWith('cached_') || 
        k.startsWith('recipe_') || 
        k == _lastSyncKey
      ).toList();
      
      for (final key in keys) {
        await prefs.remove(key);
      }
      
      print('✅ [OFFLINE] Cache cleared');
    } catch (e) {
      print('❌ [OFFLINE] Error clearing cache: $e');
    }
  }

  /// Get cache size info
  Future<CacheInfo> getCacheInfo() async {
    try {
      final prefs = await _preferences;
      final keys = prefs.getKeys().where((k) => 
        k.startsWith('cached_') || 
        k.startsWith('recipe_')
      ).toList();
      
      int totalSize = 0;
      int recipeCount = 0;
      
      for (final key in keys) {
        if (key.startsWith('recipe_')) {
          recipeCount++;
        }
        final value = prefs.getString(key) ?? prefs.getStringList(key)?.join() ?? '';
        totalSize += value.length;
      }

      return CacheInfo(
        recipeCount: recipeCount,
        sizeBytes: totalSize,
        lastSync: await getLastSyncTime(),
        isExpired: await isCacheExpired(),
      );
    } catch (e) {
      return CacheInfo(recipeCount: 0, sizeBytes: 0, lastSync: null, isExpired: true);
    }
  }
}

/// Information about the cache
class CacheInfo {
  final int recipeCount;
  final int sizeBytes;
  final DateTime? lastSync;
  final bool isExpired;

  const CacheInfo({
    required this.recipeCount,
    required this.sizeBytes,
    required this.lastSync,
    required this.isExpired,
  });

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }
}
