import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

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

  Future<void> _searchRecipes(String query) async {
    if (query.isEmpty) {
      _loadRecipes();
      return;
    }

    setState(() => _isLoading = true);
    try {
      final recipes = await _recipeService.searchRecipes(query);
      setState(() {
        _recipes = recipes;
        _searchQuery = query;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching recipes: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    );
  }

  void _showAdvancedFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AdvancedFiltersModal(),
    );
  }

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

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('search')),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter recipe name...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) => _searchQuery = value,
          onSubmitted: (value) {
            Navigator.pop(context);
            _searchRecipes(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _searchRecipes(_searchQuery);
            },
            child: Text(context.tr('search')),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleLike(Recipe recipe) async {
    try {
      await _recipeService.toggleLike(recipe.id, recipe.isLikedByUser);
      _loadRecipes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

// Recipe Card Widget
class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;
  final VoidCallback onLike;

  const _RecipeCard({
    required this.recipe,
    required this.onTap,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingMedium),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (recipe.imageUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: recipe.imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 200,
                  color: Colors.grey.shade200,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 200,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.restaurant, size: 50),
                ),
              ),
            // Content
            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.name,
                    style: AppTextStyles.h3,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    recipe.description,
                    style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '${recipe.totalTimeMinutes} min',
                        style: AppTextStyles.bodySmall.copyWith(color: Colors.grey.shade600),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.restaurant, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '${recipe.defaultServings} servings',
                        style: AppTextStyles.bodySmall.copyWith(color: Colors.grey.shade600),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          recipe.isLikedByUser ? Icons.favorite : Icons.favorite_border,
                          color: recipe.isLikedByUser ? Colors.red : null,
                        ),
                        onPressed: onLike,
                      ),
                      Text(
                        '${recipe.likes}',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
