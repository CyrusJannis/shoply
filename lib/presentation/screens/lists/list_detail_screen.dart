import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoply/core/constants/app_dimensions.dart';
import 'package:shoply/core/constants/app_text_styles.dart';
import 'package:shoply/core/utils/category_detector.dart';
import 'package:shoply/core/utils/diet_checker.dart';
import 'package:shoply/data/models/shopping_item_model.dart';
import 'package:shoply/presentation/state/auth_provider.dart';
import 'package:shoply/presentation/state/items_provider.dart';
import 'package:shoply/presentation/widgets/common/empty_state.dart';
import 'package:shoply/presentation/widgets/common/loading_indicator.dart';
import 'package:shoply/presentation/widgets/list/item_card.dart';

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
  String _sortMode = 'category';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(itemsNotifierProvider(widget.listId));

    return Scaffold(
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

                final sortedItems = _sortItems(items);

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.screenHorizontalPadding,
                  ),
                  itemCount: sortedItems.length,
                  itemBuilder: (context, index) {
                    final item = sortedItems[index];
                    return ItemCard(
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
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  List<ShoppingItemModel> _sortItems(List<ShoppingItemModel> items) {
    final list = List<ShoppingItemModel>.from(items);
    
    switch (_sortMode) {
      case 'category':
        list.sort((a, b) {
          final catA = a.category ?? 'Other';
          final catB = b.category ?? 'Other';
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share feature coming soon')),
    );
  }
}
