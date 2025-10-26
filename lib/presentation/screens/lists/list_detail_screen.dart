import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shoply/core/constants/app_colors.dart';
import 'package:shoply/core/constants/app_dimensions.dart';
import 'package:shoply/core/constants/app_text_styles.dart';
import 'package:shoply/core/constants/categories.dart';
import 'package:shoply/core/localization/app_localizations.dart';
import 'package:shoply/core/utils/category_detector.dart';
import 'package:shoply/core/utils/diet_checker.dart';
import 'package:shoply/data/models/shopping_item_model.dart';
import 'package:shoply/data/services/shopping_history_service.dart';
import 'package:shoply/data/services/purchase_tracking_service.dart';
import 'package:shoply/data/services/supabase_service.dart';
import 'package:shoply/presentation/state/auth_provider.dart';
import 'package:shoply/presentation/state/items_provider.dart';
import 'package:shoply/presentation/state/lists_provider.dart';
import 'package:shoply/presentation/state/last_list_provider.dart';
import 'package:shoply/presentation/widgets/common/empty_state.dart';
import 'package:shoply/presentation/widgets/common/loading_indicator.dart';
import 'package:shoply/presentation/widgets/list/shopping_item_grid_card.dart';
import 'package:shoply/presentation/widgets/recommendations/recommendations_section.dart';
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
      // Track this list as last accessed
      ref.read(lastAccessedListProvider.notifier).setLastAccessedList(widget.listId);
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
        centerTitle: true,
        title: Text(
          widget.listName,
          style: AppTextStyles.h2.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 26,
          ),
        ),
        leading: Container(
          margin: const EdgeInsets.fromLTRB(12, 8, 8, 8), // Etwas nach rechts
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
          child: Center(
            child: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black
                    : Colors.white,
              ),
              padding: EdgeInsets.zero, // Kein padding für mittige Ausrichtung
              constraints: const BoxConstraints(), // Keine default constraints
              onPressed: () => context.pop(),
            ),
          ),
        ),
        actions: [
          // View All Lists button
          IconButton(
            icon: const Icon(Icons.view_list_rounded),
            tooltip: 'View All Lists',
            onPressed: () => context.push('/home'),
          ),
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
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).addItem,
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
                    title: AppLocalizations.of(context).emptyList,
                    subtitle: 'Füge Produkte hinzu, um mit dem Einkaufen zu beginnen',
                    actionText: AppLocalizations.of(context).addItem,
                    onActionPressed: () => _showAddItemDialog(context),
                  );
                }

                // Sort items first
                final sortedItems = _sortItems(items);
                
                // Group items by category (only if sorting by category)
                final groupedItems = _sortMode == 'category' 
                    ? _groupItemsByCategory(sortedItems)
                    : [{'category': '', 'items': sortedItems}];

                return ListView.builder(
                  padding: const EdgeInsets.only(
                    left: AppDimensions.screenHorizontalPadding,
                    right: AppDimensions.screenHorizontalPadding,
                    bottom: 100, // Extra Padding für Navigation Bar
                  ),
                  itemCount: groupedItems.length + 2, // +1 for recommendations, +1 for Complete Button
                  itemBuilder: (context, index) {
                    // Recommendations Section at the top
                    if (index == 0) {
                      return RecommendationsSection(
                        currentItems: items,
                        onAddItem: (itemName, category, quantity) {
                          _addItemFromRecommendation(itemName, category, quantity);
                        },
                      );
                    }
                    
                    // Complete Shopping Button am Ende
                    if (index == groupedItems.length + 1) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 24, bottom: 24),
                        child: ElevatedButton.icon(
                          onPressed: () => _completeShoppingTrip(context, ref, items),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26), // iOS 18 Style - extrem rund
                            ),
                          ),
                          icon: const Icon(Icons.check_circle),
                          label: Text(AppLocalizations.of(context).completeShopping),
                        ),
                      );
                    }
                    
                    final entry = groupedItems[index - 1]; // -1 because recommendations is at index 0
                    final category = entry['category'] as String;
                    final categoryItems = entry['items'] as List<ShoppingItemModel>;
                    final icon = CategoryDetector.getCategoryIcon(category);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Header (only show if category is not empty)
                        if (category.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(
                              top: AppDimensions.spacingLarge,
                              bottom: AppDimensions.spacingSmall,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  icon,
                                  size: 24,
                                  color: CategoryDetector.getCategoryColor(category),
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
                        // Category Items - Grid Layout
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.3,
                          ),
                          itemCount: categoryItems.length,
                          itemBuilder: (context, itemIndex) {
                            final item = categoryItems[itemIndex];
                            return ShoppingItemGridCard(
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
        ],
      ),
      // FloatingActionButton removed - add items via search bar
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
      case 'custom':
        // Keep original order (from database order_index)
        list.sort((a, b) {
          final aOrder = a.orderIndex ?? 999999;
          final bOrder = b.orderIndex ?? 999999;
          return aOrder.compareTo(bOrder);
        });
        break;
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
            Text(AppLocalizations.of(context).addItem, style: AppTextStyles.h2),
            const SizedBox(height: AppDimensions.spacingMedium),
            
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).itemName,
                hintText: 'z.B. Milch, Brot, Äpfel',
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
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
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).notes,
                hintText: 'z.B. Bio, Vollmilch, 1l',
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
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
              child: Text(AppLocalizations.of(context).addItem),
            ),
            
            const SizedBox(height: AppDimensions.spacingMedium),
          ],
        ),
      ),
    );
  }

  void _showEditItemDialog(BuildContext context, ShoppingItemModel item) {
    final nameController = TextEditingController(text: item.name);
    // Display quantity as whole number if it's a whole number
    final quantityText = item.quantity % 1 == 0 
        ? item.quantity.toInt().toString() 
        : item.quantity.toString();
    final quantityController = TextEditingController(text: quantityText);
    final notesController = TextEditingController(text: item.notes ?? '');
    String selectedUnit = item.unit ?? 'pcs';

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
            Text(AppLocalizations.of(context).editItem, style: AppTextStyles.h2),
            const SizedBox(height: AppDimensions.spacingMedium),
            
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: AppLocalizations.of(context).itemName),
              textCapitalization: TextCapitalization.sentences,
            ),
            
            const SizedBox(height: AppDimensions.spacingMedium),
            
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: quantityController,
                    decoration: InputDecoration(labelText: AppLocalizations.of(context).quantity),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingSmall),
                Expanded(
                  flex: 1,
                  child: StatefulBuilder(
                    builder: (context, setState) => DropdownButtonFormField<String>(
                      value: selectedUnit,
                      decoration: InputDecoration(labelText: AppLocalizations.of(context).unit),
                      items: Categories.units.map((unit) {
                        return DropdownMenuItem(
                          value: unit,
                          child: Text(unit),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedUnit = value ?? 'pcs';
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppDimensions.spacingMedium),
            
            TextField(
              controller: notesController,
              decoration: InputDecoration(labelText: AppLocalizations.of(context).notes),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
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
                    child: Text(AppLocalizations.of(context).delete),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingSmall),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final quantity = double.tryParse(quantityController.text) ?? 1.0;
                      ref
                          .read(itemsNotifierProvider(widget.listId).notifier)
                          .updateItem(item.id, {
                        'name': nameController.text.trim(),
                        'quantity': quantity,
                        'unit': selectedUnit,
                        'notes': notesController.text.trim().isEmpty
                            ? null
                            : notesController.text.trim(),
                      });
                      Navigator.pop(context);
                    },
                    child: Text(AppLocalizations.of(context).save),
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
            leading: const Icon(Icons.swap_vert),
            title: Text(AppLocalizations.of(context).customSort),
            trailing: _sortMode == 'custom' ? const Icon(Icons.check) : null,
            onTap: () {
              setState(() => _sortMode = 'custom');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.category),
            title: Text(AppLocalizations.of(context).sortByCategory),
            trailing: _sortMode == 'category' ? const Icon(Icons.check) : null,
            onTap: () {
              setState(() => _sortMode = 'category');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.sort_by_alpha),
            title: Text(AppLocalizations.of(context).sortAlphabetically),
            trailing: _sortMode == 'alphabetical' ? const Icon(Icons.check) : null,
            onTap: () {
              setState(() => _sortMode = 'alphabetical');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.numbers),
            title: Text(AppLocalizations.of(context).sortByQuantity),
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
        title: Text(AppLocalizations.of(context).shareList),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Erstelle einen Freigabecode, um andere zu dieser Liste einzuladen.'),
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
                        title: const Text('Freigabecode'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Teile diesen Code mit anderen:'),
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
                              'Code läuft in 24 Stunden ab',
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
                                      const SnackBar(content: Text('Code in Zwischenablage kopiert')),
                                    );
                                  },
                                  icon: const Icon(Icons.copy, size: 18),
                                  label: const Text('Kopieren'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Share.share(
                                      'Trete meiner Einkaufsliste bei mit Code: $code\n\nÖffne die ShoplyAI App und tippe auf "Liste beitreten" um diesen Code einzugeben.',
                                      subject: 'Meine ShoplyAI Liste',
                                    );
                                  },
                                  icon: const Icon(Icons.share, size: 18),
                                  label: const Text('Teilen'),
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
                            child: const Text('Schließen'),
                          ),
                        ],
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
              },
              icon: const Icon(Icons.qr_code),
              label: const Text('Freigabecode erstellen'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).cancel),
          ),
        ],
      ),
    );
  }

  Future<void> _addItemFromRecommendation(
    String? itemName,
    String? category,
    double? quantity,
  ) async {
    if (itemName == null || itemName.isEmpty) return;
    
    try {
      await ref.read(itemsNotifierProvider(widget.listId).notifier).addItem(
        name: itemName,
        quantity: quantity ?? 1.0,
        category: category,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$itemName zur Liste hinzugefügt'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    }
  }

  Future<void> _completeShoppingTrip(
    BuildContext context,
    WidgetRef ref,
    List<ShoppingItemModel> items,
  ) async {
    // Filter only checked items
    final checkedItems = items.where((item) => item.isChecked).toList();
    
    if (checkedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keine markierten Artikel zum Abschließen'),
        ),
      );
      return;
    }
    
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Einkauf abschließen?'),
        content: Text(
          'Möchtest du den Einkauf mit ${checkedItems.length} markierten Artikel(n) abschließen?\n\n'
          'Nur die markierten Artikel werden in deiner Einkaufshistorie gespeichert und aus der Liste entfernt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).cancel),
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
      // Save only checked items to history
      final historyService = ShoppingHistoryService();
      await historyService.completeShoppingTrip(
        listName: widget.listName,
        items: checkedItems,
      );

      // Track purchases for recommendations
      try {
        final trackingService = PurchaseTrackingService();
        await trackingService.trackPurchases(checkedItems);
      } catch (e) {
        // Log but don't fail the whole operation if tracking fails
        debugPrint('Purchase tracking failed: $e');
      }

      // Delete only checked items from the list
      final itemIds = checkedItems.map((item) => item.id).toList();
      await SupabaseService.instance
          .from('shopping_items')
          .delete()
          .inFilter('id', itemIds);

      // Refresh the items list
      ref.invalidate(itemsNotifierProvider(widget.listId));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${checkedItems.length} Artikel erfolgreich abgeschlossen!'),
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
