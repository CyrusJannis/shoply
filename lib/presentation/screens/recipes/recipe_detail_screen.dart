import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shoply/core/constants/app_colors.dart';
import 'package:shoply/core/constants/app_dimensions.dart';
import 'package:shoply/core/constants/app_text_styles.dart';
import 'package:shoply/data/models/recipe.dart';
import 'package:shoply/data/services/recipe_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class RecipeDetailScreen extends StatefulWidget {
  final String recipeId;

  const RecipeDetailScreen({
    super.key,
    required this.recipeId,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final _recipeService = RecipeService();
  Recipe? _recipe;
  bool _isLoading = true;
  int _servings = 0;

  @override
  void initState() {
    super.initState();
    _loadRecipe();
  }

  Future<void> _loadRecipe() async {
    setState(() => _isLoading = true);
    try {
      final recipe = await _recipeService.getRecipeById(widget.recipeId);
      setState(() {
        _recipe = recipe;
        _servings = recipe.defaultServings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading recipe: $e')),
        );
      }
    }
  }

  List<Ingredient> get _adjustedIngredients {
    if (_recipe == null) return [];
    return _recipe!.ingredients
        .map((ing) => ing.adjustForServings(_recipe!.defaultServings, _servings))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_recipe == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Recipe not found')),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: CachedNetworkImage(
                imageUrl: _recipe!.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.restaurant, size: 80),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _recipe!.isLikedByUser ? Icons.favorite : Icons.favorite_border,
                  color: _recipe!.isLikedByUser ? Colors.red : null,
                ),
                onPressed: _toggleLike,
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: _shareRecipe,
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(_recipe!.name, style: AppTextStyles.h1),
                  const SizedBox(height: AppDimensions.spacingSmall),

                  // Author & Likes
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        _recipe!.authorName,
                        style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.favorite, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${_recipe!.likes} likes',
                        style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppDimensions.spacingMedium),

                  // Time Info
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons.schedule,
                        label: '${_recipe!.totalTimeMinutes} min',
                      ),
                      const SizedBox(width: 8),
                      _InfoChip(
                        icon: Icons.restaurant,
                        label: 'Prep: ${_recipe!.prepTimeMinutes} min',
                      ),
                      const SizedBox(width: 8),
                      _InfoChip(
                        icon: Icons.local_fire_department,
                        label: 'Cook: ${_recipe!.cookTimeMinutes} min',
                      ),
                    ],
                  ),

                  const SizedBox(height: AppDimensions.spacingLarge),

                  // Description
                  Text('Description', style: AppTextStyles.h3),
                  const SizedBox(height: AppDimensions.spacingSmall),
                  Text(
                    _recipe!.description,
                    style: AppTextStyles.bodyMedium,
                  ),

                  const SizedBox(height: AppDimensions.spacingLarge),

                  // Servings Adjuster
                  Row(
                    children: [
                      Text('Servings:', style: AppTextStyles.h3),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: _servings > 1 ? () => setState(() => _servings--) : null,
                      ),
                      Text(
                        '$_servings',
                        style: AppTextStyles.h2.copyWith(
                          color: AppColors.info,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => setState(() => _servings++),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppDimensions.spacingMedium),

                  // Ingredients
                  Text('Ingredients', style: AppTextStyles.h3),
                  const SizedBox(height: AppDimensions.spacingSmall),
                  ..._adjustedIngredients.map((ingredient) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.circle, size: 6, color: Colors.grey),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                ingredient.displayText,
                                style: AppTextStyles.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      )),

                  const SizedBox(height: AppDimensions.spacingLarge),

                  // Add to Shopping List Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _addToShoppingList,
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('Add to Shopping List'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppDimensions.spacingLarge),

                  // Instructions
                  Text('Instructions', style: AppTextStyles.h3),
                  const SizedBox(height: AppDimensions.spacingSmall),
                  ...List.generate(_recipe!.instructions.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.info,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _recipe!.instructions[index],
                              style: AppTextStyles.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: AppDimensions.spacingLarge),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleLike() async {
    try {
      await _recipeService.toggleLike(_recipe!.id, _recipe!.isLikedByUser);
      _loadRecipe();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _shareRecipe() {
    final link = _recipeService.getShareLink(_recipe!.id);
    Share.share(
      'Check out this recipe: ${_recipe!.name}\n\n$link',
      subject: _recipe!.name,
    );
  }

  void _addToShoppingList() {
    // Show dialog to select shopping list
    showModalBottomSheet(
      context: context,
      builder: (context) => _SelectListBottomSheet(
        ingredients: _adjustedIngredients,
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectListBottomSheet extends StatelessWidget {
  final List<Ingredient> ingredients;

  const _SelectListBottomSheet({
    required this.ingredients,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: Load actual shopping lists from database
    final mockLists = [
      {'id': '1', 'name': 'Weekly Shopping'},
      {'id': '2', 'name': 'Quick Groceries'},
      {'id': '3', 'name': 'Party Supplies'},
    ];

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select Shopping List', style: AppTextStyles.h3),
          const SizedBox(height: AppDimensions.spacingMedium),
          ...mockLists.map((list) => ListTile(
                leading: const Icon(Icons.shopping_cart),
                title: Text(list['name']!),
                onTap: () {
                  Navigator.pop(context);
                  _addIngredientsToList(context, list['id']!, list['name']!);
                },
              )),
          const SizedBox(height: AppDimensions.spacingSmall),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Navigate to create new list
              },
              icon: const Icon(Icons.add),
              label: const Text('Create New List'),
            ),
          ),
        ],
      ),
    );
  }

  void _addIngredientsToList(BuildContext context, String listId, String listName) {
    // TODO: Implement actual add to list logic
    // For now, just show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${ingredients.length} ingredients to $listName'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            context.go('/lists/$listId');
          },
        ),
      ),
    );
  }
}
