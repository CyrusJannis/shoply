import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shoply/core/constants/app_colors.dart';
import 'package:shoply/core/constants/app_dimensions.dart';
import 'package:shoply/core/constants/app_text_styles.dart';
import 'package:shoply/data/models/recipe.dart';
import 'package:shoply/data/repositories/item_repository.dart';
import 'package:shoply/data/services/ingredient_substitution_service.dart';
import 'package:shoply/presentation/state/items_provider.dart';
import 'package:shoply/presentation/state/lists_provider.dart';

/// Bottom sheet for selecting shopping lists to add recipe ingredients.
///
/// Displays all user's shopping lists with servings selector and a preview 
/// of how many ingredients will be added. Shows confirmation with substitutions.
class SelectListBottomSheet extends ConsumerStatefulWidget {
  /// Ingredients with substitution info
  final List<IngredientWithSubstitution> ingredientsWithInfo;
  
  /// Current servings selected by user
  final int defaultServings;
  
  /// Original recipe servings (for scaling)
  final int recipeDefaultServings;
  
  /// Whether to use adapted/substituted ingredients
  final bool useAdaptedIngredients;

  const SelectListBottomSheet({
    super.key,
    required this.ingredientsWithInfo,
    this.defaultServings = 2,
    this.recipeDefaultServings = 2,
    this.useAdaptedIngredients = true,
  });

  @override
  ConsumerState<SelectListBottomSheet> createState() => _SelectListBottomSheetState();
}

class _SelectListBottomSheetState extends ConsumerState<SelectListBottomSheet> {
  late int _servings;
  late bool _useAdapted;
  bool _showConfirmation = false;
  String? _selectedListId;
  String? _selectedListName;
  
  @override
  void initState() {
    super.initState();
    _servings = widget.defaultServings;
    _useAdapted = widget.useAdaptedIngredients;
  }
  
  /// Get final ingredients to add (adapted or original, scaled for servings)
  List<Ingredient> get _finalIngredients {
    return widget.ingredientsWithInfo.map((info) {
      final ingredient = _useAdapted ? info.adaptedIngredient : info.original;
      // Scale for servings difference
      return ingredient.adjustForServings(widget.recipeDefaultServings, _servings);
    }).toList();
  }
  
  /// Check if any ingredients have substitutions
  bool get _hasSubstitutions {
    return widget.ingredientsWithInfo.any((info) => info.needsSubstitution && info.bestSubstitute != null);
  }

  @override
  Widget build(BuildContext context) {
    final listsAsync = ref.watch(userListsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.paddingLarge,
        AppDimensions.paddingLarge,
        AppDimensions.paddingLarge,
        AppDimensions.paddingLarge + bottomPadding, // Safe area padding
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.recipeDarkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          Text('Add to Shopping List', style: AppTextStyles.h3),
          const SizedBox(height: AppDimensions.spacingLarge),
          
          // Servings selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.recipeDarkInput : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.restaurant_rounded,
                  color: AppColors.recipeTextSecondary(context),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Servings',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.recipeTextPrimary(context),
                        ),
                      ),
                      Text(
                        'Adjust ingredient amounts',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Servings controls
                Container(
                  decoration: BoxDecoration(
                  color: isDark ? AppColors.recipeDarkBorder : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 20),
                        onPressed: _servings > 1 
                            ? () => setState(() => _servings--) 
                            : null,
                        color: AppColors.recipeTextPrimary(context),
                        disabledColor: Colors.grey,
                      ),
                      Container(
                        constraints: const BoxConstraints(minWidth: 40),
                        alignment: Alignment.center,
                        child: Text(
                          '$_servings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.recipeTextPrimary(context),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 20),
                        onPressed: _servings < 20 
                            ? () => setState(() => _servings++) 
                            : null,
                        color: AppColors.recipeTextPrimary(context),
                        disabledColor: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppDimensions.spacingLarge),
          
          // Show loading or error states
          listsAsync.when(
            data: (lists) {
              if (lists.isEmpty) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                      child: Text(
                        'No lists yet. Create one first!',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          context.go('/lists');
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Create First List'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
              
              // Show confirmation if list selected, otherwise show list selection
              if (_showConfirmation && _selectedListId != null) {
                return _buildConfirmationView(isDark);
              }
              
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Show substitution toggle if there are substitutions
                  if (_hasSubstitutions) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.swap_horiz, color: AppColors.recipeAccentColor(context), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Use adapted ingredients',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.recipeTextPrimary(context),
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Switch(
                            value: _useAdapted,
                            activeColor: Colors.orange,
                            onChanged: (value) => setState(() => _useAdapted = value),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  Text(
                    'Select List',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...lists.map((list) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.recipeDarkInput : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.recipeDarkBorder : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.shopping_cart_rounded, size: 20),
                      ),
                      title: Text(
                        list.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.recipeTextPrimary(context),
                        ),
                      ),
                      subtitle: Text(
                        '${widget.ingredientsWithInfo.length} ingredients for $_servings servings',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: Colors.grey.shade400,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedListId = list.id;
                          _selectedListName = list.name;
                          _showConfirmation = true;
                        });
                      },
                    ),
                  )),
                  const SizedBox(height: AppDimensions.spacingSmall),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        context.go('/lists');
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Create New List'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppDimensions.paddingLarge),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingLarge),
              child: Text('Error loading lists: $error'),
            ),
          ),
        ],
      ),
    );
  }

  /// Build confirmation view showing ingredients that will be added
  Widget _buildConfirmationView(bool isDark) {
    final ingredients = _finalIngredients;
    final substitutedCount = widget.ingredientsWithInfo.where(
      (info) => info.needsSubstitution && info.bestSubstitute != null && _useAdapted
    ).length;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
              onPressed: () => setState(() => _showConfirmation = false),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Adding to "$_selectedListName"',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: AppColors.recipeTextPrimary(context),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Summary card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.recipeDarkInput : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.restaurant_menu, size: 20, color: AppColors.recipeGreenColor(context)),
                  const SizedBox(width: 8),
                  Text(
                    '${ingredients.length} ingredients for $_servings servings',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.recipeTextPrimary(context),
                    ),
                  ),
                ],
              ),
              if (substitutedCount > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.swap_horiz, size: 20, color: AppColors.recipeAccentColor(context)),
                    const SizedBox(width: 8),
                    Text(
                      '$substitutedCount adapted for your diet',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.recipeAccentColor(context),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Ingredients preview (scrollable)
        Text(
          'Ingredients to add:',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          decoration: BoxDecoration(
            color: isDark ? AppColors.recipeDarkInput : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.all(12),
            itemCount: widget.ingredientsWithInfo.length,
            separatorBuilder: (_, __) => Divider(
              height: 16,
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
            ),
            itemBuilder: (context, index) {
              final info = widget.ingredientsWithInfo[index];
              final isSubstituted = info.needsSubstitution && info.bestSubstitute != null && _useAdapted;
              final ingredient = ingredients[index];
              
              return Row(
                children: [
                  if (isSubstituted)
                    Icon(Icons.swap_horiz, size: 16, color: AppColors.recipeAccentColor(context))
                  else
                    Icon(Icons.check_circle_outline, size: 16, color: AppColors.recipeGreenColor(context)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${ingredient.amount > 0 ? "${ingredient.amount % 1 == 0 ? ingredient.amount.toInt() : ingredient.amount} " : ""}${ingredient.unit ?? ""} ${ingredient.name}',
                          style: TextStyle(
                            color: AppColors.recipeTextPrimary(context),
                            fontWeight: isSubstituted ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        if (isSubstituted)
                          Text(
                            'instead of ${info.original.name}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Confirm button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(context);
              _addIngredientsToList(context, ref, _selectedListId!, _selectedListName!, ingredients);
            },
            icon: const Icon(Icons.add_shopping_cart),
            label: Text('Add ${ingredients.length} Ingredients'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.recipeGreenColor(context),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Adds all ingredients to the selected shopping list with rate limiting.
  ///
  /// This method processes ingredients sequentially with a 1.1 second delay
  /// between each item to respect Gemini API's rate limit during categorization.
  ///
  /// **Process Flow**:
  /// 1. Initialize tracking variables (success/failure counts)
  /// 2. Loop through each ingredient
  /// 3. Add to list via ItemRepository (triggers AI categorization)
  /// 4. Wait 1.1s before next ingredient (except for last one)
  /// 5. Update UI with appropriate feedback
  ///
  /// **Error Handling**:
  /// - Individual failures are logged but don't stop the batch
  /// - Failed items are tracked for user feedback
  /// - All errors are collected for debugging
  ///
  /// **Performance**:
  /// - 10 ingredients ≈ 11 seconds
  /// - 20 ingredients ≈ 22 seconds
  /// - Network latency adds ~0.5-1s per item
  ///
  /// **Side Effects**:
  /// - Writes to database for each ingredient
  /// - Calls Gemini API for categorization (if not cached)
  /// - Invalidates providers to refresh UI
  /// - Shows snackbar with results
  ///
  /// See also:
  /// - [ItemRepository.addItem] for individual item addition
  Future<void> _addIngredientsToList(
    BuildContext context,
    WidgetRef ref,
    String listId,
    String listName,
    List<Ingredient> adjustedIngredients,
  ) async {
    try {
      final itemRepository = ItemRepository();
      int addedCount = 0;
      int failedCount = 0;
      List<String> failedItems = [];
      List<String> errorMessages = [];

      debugPrint('🔵 [RECIPE] Starting to add ${adjustedIngredients.length} ingredients to list $listName');

      // === Process each ingredient with rate limiting ===
      for (int i = 0; i < adjustedIngredients.length; i++) {
        final ingredient = adjustedIngredients[i];
        debugPrint('🔵 [RECIPE] Processing ingredient ${i + 1}/${adjustedIngredients.length}: ${ingredient.name}');
        
        try {
          final startTime = DateTime.now();
          
          // Add item to list (triggers AI categorization internally)
          await itemRepository.addItem(
            listId: listId,
            name: ingredient.name,
            quantity: ingredient.amount,
            unit: ingredient.unit,
            category: null, // Auto-detect category via Gemini
          );
          
          final duration = DateTime.now().difference(startTime);
          addedCount++;
          
          debugPrint('✅ [RECIPE] Successfully added "${ingredient.name}" (took ${duration.inMilliseconds}ms)');
          
          // Wait 1.1 seconds to comply with Gemini API rate limit (1 req/sec)
          // This prevents "429 Too Many Requests" errors during AI categorization
          // Skip delay for last ingredient since there's nothing after it
          if (i < adjustedIngredients.length - 1) {
            await Future.delayed(const Duration(milliseconds: 1100));
          }
        } catch (e, stackTrace) {
          failedCount++;
          failedItems.add(ingredient.name);
          final errorMsg = e.toString();
          errorMessages.add(errorMsg);
          
          debugPrint('❌ [RECIPE] Failed to add "${ingredient.name}": $errorMsg');
          debugPrint('❌ [RECIPE] StackTrace: $stackTrace');
        }
      }

      debugPrint('🔵 [RECIPE] Finished: $addedCount added, $failedCount failed');

      // === Update UI state ===
      if (context.mounted) {
        // Refresh the items in the list
        ref.invalidate(itemsNotifierProvider(listId));
        ref.invalidate(listsNotifierProvider);
        
        // Show appropriate message based on results
        if (addedCount > 0 && failedCount == 0) {
          // All succeeded
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Added all $addedCount ingredients to $listName'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'View',
                textColor: Colors.white,
                onPressed: () {
                  context.go('/lists/$listId');
                },
              ),
            ),
          );
        } else if (addedCount > 0 && failedCount > 0) {
          // Partial success
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ Added $addedCount of ${adjustedIngredients.length} ingredients\n${failedItems.length} failed: ${failedItems.take(3).join(", ")}${failedItems.length > 3 ? "..." : ""}'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'View',
                textColor: Colors.white,
                onPressed: () {
                  context.go('/lists/$listId');
                },
              ),
            ),
          );
        } else {
          // All failed
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Failed to add ingredients\nFirst error: ${errorMessages.isNotEmpty ? errorMessages.first : "Unknown error"}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 6),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [RECIPE] Critical error in _addIngredientsToList: $e');
      debugPrint('❌ [RECIPE] StackTrace: $stackTrace');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
