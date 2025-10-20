import 'dart:io';
import 'package:shoply/data/models/recipe.dart';
import 'package:shoply/data/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RecipeService {
  final _supabase = SupabaseService.instance.client;

  /// Get all recipes
  Future<List<Recipe>> getRecipes() async {
    try {
      final response = await _supabase
          .from('recipes')
          .select('''
            *,
            recipe_likes!left(user_id)
          ''')
          .order('created_at', ascending: false);

      final userId = _supabase.auth.currentUser?.id;
      
      return (response as List).map((json) {
        final likes = (json['recipe_likes'] as List?)?.length ?? 0;
        final isLiked = userId != null &&
            (json['recipe_likes'] as List?)
                ?.any((like) => like['user_id'] == userId) ==
            true;

        return Recipe.fromJson({
          ...json,
          'likes': likes,
          'is_liked_by_user': isLiked,
        });
      }).toList();
    } catch (e) {
      print('Error fetching recipes: $e');
      rethrow;
    }
  }

  /// Get recipe by ID
  Future<Recipe> getRecipeById(String id) async {
    try {
      final response = await _supabase
          .from('recipes')
          .select('''
            *,
            recipe_likes!left(user_id)
          ''')
          .eq('id', id)
          .single();

      final userId = _supabase.auth.currentUser?.id;
      final likes = (response['recipe_likes'] as List?)?.length ?? 0;
      final isLiked = userId != null &&
          (response['recipe_likes'] as List?)
              ?.any((like) => like['user_id'] == userId) ==
          true;

      return Recipe.fromJson({
        ...response,
        'likes': likes,
        'is_liked_by_user': isLiked,
      });
    } catch (e) {
      print('Error fetching recipe: $e');
      rethrow;
    }
  }

  /// Create new recipe
  Future<Recipe> createRecipe(Recipe recipe) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _supabase.from('recipes').insert({
        'name': recipe.name,
        'description': recipe.description,
        'image_url': recipe.imageUrl,
        'prep_time_minutes': recipe.prepTimeMinutes,
        'cook_time_minutes': recipe.cookTimeMinutes,
        'default_servings': recipe.defaultServings,
        'ingredients': recipe.ingredients.map((i) => i.toJson()).toList(),
        'instructions': recipe.instructions,
        'author_id': user.id,
        'author_name': user.email ?? 'Anonymous',
      }).select().single();

      return Recipe.fromJson(response);
    } catch (e) {
      print('Error creating recipe: $e');
      rethrow;
    }
  }

  /// Like/Unlike recipe
  Future<void> toggleLike(String recipeId, bool currentlyLiked) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      if (currentlyLiked) {
        // Unlike
        await _supabase
            .from('recipe_likes')
            .delete()
            .eq('recipe_id', recipeId)
            .eq('user_id', userId);
      } else {
        // Like
        await _supabase.from('recipe_likes').insert({
          'recipe_id': recipeId,
          'user_id': userId,
        });
      }
    } catch (e) {
      print('Error toggling like: $e');
      rethrow;
    }
  }

  /// Get share link for recipe
  String getShareLink(String recipeId) {
    return 'https://shoply.app/recipe/$recipeId';
  }

  /// Upload recipe image
  Future<String> uploadRecipeImage(String filePath, String fileName) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final path = 'recipes/$userId/$fileName';
      final file = File(filePath);
      
      await _supabase.storage.from('recipe-images').upload(
            path,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      final url = _supabase.storage.from('recipe-images').getPublicUrl(path);
      return url;
    } catch (e) {
      print('Error uploading image: $e');
      rethrow;
    }
  }

  /// Search recipes
  Future<List<Recipe>> searchRecipes(String query) async {
    try {
      final response = await _supabase
          .from('recipes')
          .select('''
            *,
            recipe_likes!left(user_id)
          ''')
          .ilike('name', '%$query%')
          .order('created_at', ascending: false);

      final userId = _supabase.auth.currentUser?.id;
      
      return (response as List).map((json) {
        final likes = (json['recipe_likes'] as List?)?.length ?? 0;
        final isLiked = userId != null &&
            (json['recipe_likes'] as List?)
                ?.any((like) => like['user_id'] == userId) ==
            true;

        return Recipe.fromJson({
          ...json,
          'likes': likes,
          'is_liked_by_user': isLiked,
        });
      }).toList();
    } catch (e) {
      print('Error searching recipes: $e');
      rethrow;
    }
  }
}
