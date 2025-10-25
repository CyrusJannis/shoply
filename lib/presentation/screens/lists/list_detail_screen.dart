import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
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
          // Sort button - iOS26 style with glass design
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AdaptivePopupMenuButton.icon(
              icon: PlatformInfo.isIOS26OrHigher() ? 'arrow.up.arrow.down' : Icons.sort,
              buttonStyle: PopupButtonStyle.glass,
              items: [
                AdaptivePopupMenuItem(
                  label: AppLocalizations.of(context).sortByCategory,
                  icon: Icons.category,
                ),
                AdaptivePopupMenuItem(
                  label: AppLocalizations.of(context).sortAlphabetically,
                  icon: Icons.sort_by_alpha,
                ),
                AdaptivePopupMenuItem(
                  label: AppLocalizations.of(context).sortByQuantity,
                  icon: Icons.numbers,
                ),
                AdaptivePopupMenuItem(
                  label: AppLocalizations.of(context).customSort,
                  icon: Icons.tune,
                ),
              ],
              onSelected: (index, entry) {
                final sortModes = ['category', 'alphabetical', 'quantity', 'custom'];
                setState(() {
                  _sortMode = sortModes[index];
                });
              },
            ),
          ),
          // Share button - iOS26 style with glass design
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: AdaptivePopupMenuButton.icon(
              icon: PlatformInfo.isIOS26OrHigher() ? 'square.and.arrow.up' : Icons.share,
              buttonStyle: PopupButtonStyle.glass,
              items: [
                AdaptivePopupMenuItem(
                  label: AppLocalizations.of(context).showCode,
                  icon: Icons.qr_code,
                ),
                AdaptivePopupMenuItem(
                  label: AppLocalizations.of(context).share,
                  icon: Icons.share,
                ),
                const AdaptivePopupMenuDivider(),
                AdaptivePopupMenuItem(
                  label: AppLocalizations.of(context).cancel,
                  icon: Icons.close,
                ),
              ],
              onSelected: (index, entry) {
                if (index == 0) {
                  _showShareCodeDialog();
                } else if (index == 1) {
                  _onShareSelected();
                }
                // index 2 is divider, index 3 is cancel - do nothing
              },
            ),
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

  Future<void> _showShareCodeDialog() async {
    try {
      final code = await ref
          .read(listsNotifierProvider.notifier)
          .generateShareCode(widget.listId);

      AdaptiveAlertDialog.show(
        context: context,
        title: AppLocalizations.of(context).shareCodeTitle,
        message: '${AppLocalizations.of(context).shareCodeMessage}\n\n$code',
        icon: PlatformInfo.isIOS26OrHigher() ? 'qrcode' : Icons.qr_code,
        actions: [
          AlertAction(
            title: AppLocalizations.of(context).cancel,
            style: AlertActionStyle.cancel,
            onPressed: () {},
          ),
          AlertAction(
            title: AppLocalizations.of(context).copy,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
            },
          ),
          AlertAction(
            title: AppLocalizations.of(context).share,
            style: AlertActionStyle.primary,
            onPressed: () {
              _shareListViaSystem(code);
            },
          ),
        ],
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    }
  }

  Future<void> _onShareSelected() async {
    try {
      final code = await ref
          .read(listsNotifierProvider.notifier)
          .generateShareCode(widget.listId);

      AdaptiveAlertDialog.show(
        context: context,
        title: AppLocalizations.of(context).shareDialogTitle,
        message: AppLocalizations.of(context).shareDialogMessage(code),
        icon: PlatformInfo.isIOS26OrHigher() ? 'square.and.arrow.up' : Icons.share,
        actions: [
          AlertAction(
            title: AppLocalizations.of(context).cancel,
            style: AlertActionStyle.cancel,
            onPressed: () {},
          ),
          AlertAction(
            title: AppLocalizations.of(context).share,
            onPressed: () {
              _shareListViaSystem(code);
            },
          ),
          AlertAction(
            title: AppLocalizations.of(context).copyAndContinue,
            style: AlertActionStyle.primary,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              _shareListViaSystem(code);
            },
          ),
        ],
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    }
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

  void _shareListViaSystem([String? code]) {
    final base = 'Schau dir meine Einkaufsliste "${widget.listName}" an!';
    final withCode = code != null && code.isNotEmpty
        ? '\n\nTrete mit diesem Code bei: $code\nÖffne ShoplyAI und tippe auf "Liste beitreten".'
        : '\n\nLade ShoplyAI herunter und trete meiner Liste bei.';
    Share.share(
      '$base $withCode',
      subject: 'Meine ShoplyAI Einkaufsliste',
    );
  }
}
