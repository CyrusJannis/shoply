import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoply/core/constants/app_colors.dart';
import 'package:shoply/core/constants/app_dimensions.dart';
import 'package:shoply/core/constants/app_text_styles.dart';
import 'package:shoply/core/constants/categories.dart';
import 'package:shoply/core/utils/category_detector.dart';
import 'package:shoply/core/utils/diet_checker.dart';
import 'package:shoply/data/models/shopping_item_model.dart';
import 'package:shoply/data/services/shopping_history_service.dart';
import 'package:shoply/data/services/supabase_service.dart';
import 'package:shoply/presentation/state/auth_provider.dart';
import 'package:shoply/presentation/state/items_provider.dart';
import 'package:shoply/presentation/state/lists_provider.dart';
import 'package:shoply/presentation/widgets/common/empty_state.dart';
import 'package:shoply/presentation/widgets/common/loading_indicator.dart';
import 'package:shoply/presentation/widgets/list/item_card.dart';
import 'package:share_plus/share_plus.dart';

class ListDetailScreen extends ConsumerStatefulWidget {
  final String listId;
  final String listName;

  const ListDetailScreen({
    super.key,
    required this.listId,
    required this.listName,
  });

  @override
  ConsumerState<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends ConsumerState<ListDetailScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  String _sortMode = 'category';

  @override
  void initState() {
    super.initState();
    // Reload items when entering the list
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(itemsNotifierProvider(widget.listId).notifier).loadItems();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(itemsNotifierProvider(widget.listId));

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(widget.listName, style: AppTextStyles.h2),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'sort') {
                _showSortOptions(context);
              } else if (value == 'share') {
                _showShareDialog(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'sort',
                child: Row(
                  children: [
                    Icon(Icons.sort),
                    SizedBox(width: 8),
                    Text('Sort'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share),
                    SizedBox(width: 8),
                    Text('Share List'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search/Add Bar
          Padding(
            padding: const EdgeInsets.all(AppDimensions.screenHorizontalPadding),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              autofocus: false,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: 'Add item...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showAddItemDialog(context),
                ),
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  _quickAddItem(value.trim());
                  // Keep focus in text field after adding
                  _focusNode.requestFocus();
                }
              },
            ),
          ),

          // Items List
          Expanded(
            child: itemsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return EmptyState(
                    icon: Icons.shopping_cart,
                    title: 'No items yet',
                    subtitle: 'Add your first item to get started',
                    actionText: 'Add Item',
                    onActionPressed: () => _showAddItemDialog(context),
                  );
                }

                // Group items by category
                final groupedItems = _groupItemsByCategory(items);

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.screenHorizontalPadding,
                  ),
                  itemCount: groupedItems.length,
                  itemBuilder: (context, index) {
                    final entry = groupedItems[index];
                    final category = entry['category'] as String;
                    final categoryItems = entry['items'] as List<ShoppingItemModel>;
                    final icon = CategoryDetector.getCategoryIcon(category);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Header
                        Padding(
                          padding: const EdgeInsets.only(
                            top: AppDimensions.spacingLarge,
                            bottom: AppDimensions.spacingSmall,
                          ),
                          child: Row(
                            children: [
                              Text(
                                icon,
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                category,
                                style: AppTextStyles.h3.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '(${categoryItems.length})',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Category Items with Reorderable List
                        ReorderableListView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          buildDefaultDragHandles: false,
                          onReorder: (oldIndex, newIndex) {
                            HapticFeedback.mediumImpact();
                            _reorderItemsInCategory(categoryItems, oldIndex, newIndex);
                            HapticFeedback.lightImpact();
                          },
                          children: categoryItems.asMap().entries.map((entry) {
                            final itemIndex = entry.key;
                            final item = entry.value;
                            return ReorderableDragStartListener(
                              key: ValueKey(item.id),
                              index: itemIndex,
                              child: ItemCard(
                                item: item,
                                onTap: () => _showEditItemDialog(context, item),
                                onCheckedChanged: (checked) {
                                  ref
                                      .read(itemsNotifierProvider(widget.listId).notifier)
                                      .toggleItemChecked(item.id, checked ?? false);
                                },
                                onDelete: () {
                                  ref
                                      .read(itemsNotifierProvider(widget.listId).notifier)
                                      .deleteItem(item.id);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    );
                  },
                );
              },
              loading: () => const LoadingIndicator(message: 'Loading items...'),
              error: (error, stack) => Center(
                child: Text('Error: $error'),
              ),
            ),
          ),
          // Complete Shopping Button at bottom
          itemsAsync.when(
            data: (items) {
              if (items.isEmpty) return const SizedBox.shrink();
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _completeShoppingTrip(context, ref, items),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Einkauf abschließen'),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  List<Map<String, dynamic>> _groupItemsByCategory(List<ShoppingItemModel> items) {
    // Group items by category
    final Map<String, List<ShoppingItemModel>> categoryMap = {};
    
    for (final item in items) {
      final category = item.category ?? 'Sonstiges';
      if (!categoryMap.containsKey(category)) {
        categoryMap[category] = [];
      }
      categoryMap[category]!.add(item);
    }

    // Sort categories in the order defined in Categories.all
    final sortedCategories = <String>[];
    for (final category in Categories.all) {
      if (categoryMap.containsKey(category)) {
        sortedCategories.add(category);
      }
    }

    // Convert to list of maps for ListView
    return sortedCategories.map((category) {
      return {
        'category': category,
        'items': categoryMap[category]!,
      };
    }).toList();
  }

  void _reorderItemsInCategory(
    List<ShoppingItemModel> categoryItems,
    int oldIndex,
    int newIndex,
  ) {
    // Adjust newIndex if moving down
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    // Reorder the items
    final item = categoryItems.removeAt(oldIndex);
    categoryItems.insert(newIndex, item);

    // Update sort order in database
    final itemIds = categoryItems.map((item) => item.id).toList();
    ref.read(itemsNotifierProvider(widget.listId).notifier).updateSortOrder(itemIds);
  }

  List<ShoppingItemModel> _sortItems(List<ShoppingItemModel> items) {
    final list = List<ShoppingItemModel>.from(items);
    
    switch (_sortMode) {
      case 'category':
        list.sort((a, b) {
          final catA = a.category ?? 'Sonstiges';
          final catB = b.category ?? 'Sonstiges';
          return catA.compareTo(catB);
        });
        break;
      case 'alphabetical':
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'quantity':
        list.sort((a, b) => b.quantity.compareTo(a.quantity));
        break;
    }

    return list;
  }

  void _quickAddItem(String name) {
    final user = ref.read(currentUserProvider).value;
    final category = CategoryDetector.detectCategory(name);
    final isDietWarning = user != null
        ? DietChecker.checkDietWarning(name, user.dietPreferences)
        : false;

    ref.read(itemsNotifierProvider(widget.listId).notifier).addItem(
          name: name,
          category: category,
          isDietWarning: isDietWarning,
        );

    _searchController.clear();
  }

  void _showAddItemDialog(BuildContext context) {
    final nameController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final notesController = TextEditingController();
    String? selectedUnit;
    String? selectedCategory;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.bottomSheetBorderRadius),
        ),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: AppDimensions.screenHorizontalPadding,
          right: AppDimensions.screenHorizontalPadding,
          top: AppDimensions.screenVerticalPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add Item', style: AppTextStyles.h2),
            const SizedBox(height: AppDimensions.spacingMedium),
            
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Item Name',
                hintText: 'e.g., Milk',
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
            ),
            
            const SizedBox(height: AppDimensions.spacingMedium),
            
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingSmall),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedUnit,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                    ),
                    items: ['pcs', 'kg', 'g', 'l', 'ml', 'pack']
                        .map((unit) => DropdownMenuItem(
                              value: unit,
                              child: Text(unit),
                            ))
                        .toList(),
                    onChanged: (value) => selectedUnit = value,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppDimensions.spacingMedium),
            
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'e.g., Low fat, organic',
              ),
              maxLines: 2,
            ),
            
            const SizedBox(height: AppDimensions.spacingLarge),
            
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;

                final name = nameController.text.trim();
                final user = ref.read(currentUserProvider).value;
                final autoCategory = CategoryDetector.detectCategory(name);
                final isDietWarning = user != null
                    ? DietChecker.checkDietWarning(name, user.dietPreferences)
                    : false;

                ref.read(itemsNotifierProvider(widget.listId).notifier).addItem(
                      name: name,
                      quantity: double.tryParse(quantityController.text) ?? 1.0,
                      unit: selectedUnit,
                      category: selectedCategory ?? autoCategory,
                      notes: notesController.text.trim().isEmpty
                          ? null
                          : notesController.text.trim(),
                      isDietWarning: isDietWarning,
                    );

                Navigator.pop(context);
              },
              child: const Text('Add Item'),
            ),
            
            const SizedBox(height: AppDimensions.spacingMedium),
          ],
        ),
      ),
    );
  }

  void _showEditItemDialog(BuildContext context, ShoppingItemModel item) {
    final nameController = TextEditingController(text: item.name);
    final quantityController = TextEditingController(text: item.quantity.toString());
    final notesController = TextEditingController(text: item.notes ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.bottomSheetBorderRadius),
        ),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: AppDimensions.screenHorizontalPadding,
          right: AppDimensions.screenHorizontalPadding,
          top: AppDimensions.screenVerticalPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Edit Item', style: AppTextStyles.h2),
            const SizedBox(height: AppDimensions.spacingMedium),
            
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Item Name'),
            ),
            
            const SizedBox(height: AppDimensions.spacingMedium),
            
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
            ),
            
            const SizedBox(height: AppDimensions.spacingMedium),
            
            TextField(
              controller: notesController,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 2,
            ),
            
            const SizedBox(height: AppDimensions.spacingLarge),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref
                          .read(itemsNotifierProvider(widget.listId).notifier)
                          .deleteItem(item.id);
                      Navigator.pop(context);
                    },
                    child: const Text('Delete'),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingSmall),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ref
                          .read(itemsNotifierProvider(widget.listId).notifier)
                          .updateItem(item.id, {
                        'name': nameController.text.trim(),
                        'quantity':
                            double.tryParse(quantityController.text) ?? 1.0,
                        'notes': notesController.text.trim().isEmpty
                            ? null
                            : notesController.text.trim(),
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppDimensions.spacingMedium),
          ],
        ),
      ),
    );
  }

  void _showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('By Category'),
            trailing: _sortMode == 'category' ? const Icon(Icons.check) : null,
            onTap: () {
              setState(() => _sortMode = 'category');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.sort_by_alpha),
            title: const Text('Alphabetical'),
            trailing: _sortMode == 'alphabetical' ? const Icon(Icons.check) : null,
            onTap: () {
              setState(() => _sortMode = 'alphabetical');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.numbers),
            title: const Text('By Quantity'),
            trailing: _sortMode == 'quantity' ? const Icon(Icons.check) : null,
            onTap: () {
              setState(() => _sortMode = 'quantity');
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showShareDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share List'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Generate a share code to invite others to this list.'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  final code = await ref
                      .read(listsNotifierProvider.notifier)
                      .generateShareCode(widget.listId);
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Share Code'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Share this code with others:'),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: SelectableText(
                                code,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Code expires in 24 hours',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: code));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Code copied to clipboard')),
                                    );
                                  },
                                  icon: const Icon(Icons.copy, size: 18),
                                  label: const Text('Copy'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Share.share(
                                      'Join my shopping list with code: $code\n\nOpen the ShoplyAI app and tap the "Join List" button to enter this code.',
                                      subject: 'Join my ShoplyAI list',
                                    );
                                  },
                                  icon: const Icon(Icons.share, size: 18),
                                  label: const Text('Share'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.qr_code),
              label: const Text('Generate Share Code'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeShoppingTrip(
    BuildContext context,
    WidgetRef ref,
    List<ShoppingItemModel> items,
  ) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Einkauf abschließen?'),
        content: Text(
          'Möchtest du den Einkauf mit ${items.length} Artikel(n) abschließen?\n\n'
          'Die Liste wird geleert und in deiner Einkaufshistorie gespeichert.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: const Text('Abschließen'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Save to history
      final historyService = ShoppingHistoryService();
      await historyService.completeShoppingTrip(
        listName: widget.listName,
        items: items,
      );

      // Delete all items from the list at once
      final itemIds = items.map((item) => item.id).toList();
      await SupabaseService.instance
          .from('shopping_items')
          .delete()
          .inFilter('id', itemIds);

      // Refresh the items list
      ref.invalidate(itemsNotifierProvider(widget.listId));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Einkauf erfolgreich abgeschlossen!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    }
  }
}
