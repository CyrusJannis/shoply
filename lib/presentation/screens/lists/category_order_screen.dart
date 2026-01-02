import 'dart:convert';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoply/core/constants/app_colors.dart';
import 'package:shoply/core/constants/categories.dart';
import 'package:shoply/core/localization/localization_helper.dart';

/// Per-list custom category management and category ordering.

/// Service for managing category order and custom categories per shopping list.
class CategoryOrderService {
  static final CategoryOrderService _instance = CategoryOrderService._internal();
  factory CategoryOrderService() => _instance;
  CategoryOrderService._internal();

  /// Get the category order for a specific list
  Future<List<String>> getCategoryOrder(String listId) async {
    final prefs = await SharedPreferences.getInstance();
    final order = prefs.getStringList('category_order_$listId');
    if (order != null && order.isNotEmpty) {
      return order;
    }
    // Return default order: custom categories first, then built-in
    final customCategories = await getCustomCategories(listId);
    final customIds = customCategories.map((c) => c.id).toList();
    return [...customIds, ...Categories.allIds];
  }

  /// Save the category order for a specific list
  Future<void> saveCategoryOrder(String listId, List<String> order) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('category_order_$listId', order);
  }

  /// Get custom categories for a specific list
  Future<List<CustomCategory>> getCustomCategories(String listId) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('custom_categories_$listId');
    if (json == null) return [];
    
    final List<dynamic> list = jsonDecode(json);
    return list.map((e) => CustomCategory.fromJson(e)).toList();
  }

  /// Save custom categories for a specific list
  Future<void> saveCustomCategories(String listId, List<CustomCategory> categories) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(categories.map((e) => e.toJson()).toList());
    await prefs.setString('custom_categories_$listId', json);
  }

  /// Add a custom category to a specific list (inserted at top)
  Future<CustomCategory> addCustomCategory(String listId, String name, Color color) async {
    final categories = await getCustomCategories(listId);
    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    final category = CustomCategory(
      id: id,
      name: name,
      color: color,
    );
    categories.insert(0, category);
    await saveCustomCategories(listId, categories);
    
    // Also update the category order to include this new category at the top
    final order = await getCategoryOrder(listId);
    if (!order.contains(id)) {
      order.insert(0, id);
      await saveCategoryOrder(listId, order);
    }
    
    return category;
  }

  /// Delete a custom category from a specific list
  Future<void> deleteCustomCategory(String listId, String categoryId) async {
    final categories = await getCustomCategories(listId);
    categories.removeWhere((c) => c.id == categoryId);
    await saveCustomCategories(listId, categories);
    
    // Also remove from category order
    final order = await getCategoryOrder(listId);
    order.remove(categoryId);
    await saveCategoryOrder(listId, order);
  }

  /// Update a custom category
  Future<void> updateCustomCategory(String listId, CustomCategory category) async {
    final categories = await getCustomCategories(listId);
    final index = categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      categories[index] = category;
      await saveCustomCategories(listId, categories);
    }
  }
}

/// A custom category created by the user for a specific list.
class CustomCategory {
  final String id;
  final String name;
  final Color color;

  CustomCategory({
    required this.id,
    required this.name,
    required this.color,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'color': color.value,
  };

  factory CustomCategory.fromJson(Map<String, dynamic> json) => CustomCategory(
    id: json['id'],
    name: json['name'],
    color: Color(json['color']),
  );
}

/// Screen for managing category order and custom categories for a specific list.
class CategoryOrderScreen extends StatefulWidget {
  final String listId;
  final String listName;

  const CategoryOrderScreen({
    super.key,
    required this.listId,
    required this.listName,
  });

  @override
  State<CategoryOrderScreen> createState() => _CategoryOrderScreenState();
}

class _CategoryOrderScreenState extends State<CategoryOrderScreen> {
  final _service = CategoryOrderService();
  List<_CategoryItem> _categories = [];
  bool _isLoading = true;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final order = await _service.getCategoryOrder(widget.listId);
    final customCategories = await _service.getCustomCategories(widget.listId);
    
    final customMap = {for (var c in customCategories) c.id: c};
    final builtInIds = Categories.allIds;
    
    final items = <_CategoryItem>[];
    
    // Add categories in order
    for (final id in order) {
      if (customMap.containsKey(id)) {
        final custom = customMap[id]!;
        items.add(_CategoryItem(
          id: id,
          name: custom.name,
          color: custom.color,
          isCustom: true,
        ));
      } else if (builtInIds.contains(id)) {
        final cat = Categories.getById(id);
        items.add(_CategoryItem(
          id: id,
          name: id, // Store ID for translation lookup
          color: cat.color,
          isCustom: false,
        ));
      }
    }
    
    // Add any built-in categories not in order yet
    for (final id in builtInIds) {
      if (!order.contains(id)) {
        final cat = Categories.getById(id);
        items.add(_CategoryItem(
          id: id,
          name: id, // Store ID for translation lookup
          color: cat.color,
          isCustom: false,
        ));
      }
    }
    
    // Add any custom categories not in order yet (at top)
    for (final custom in customCategories) {
      if (!order.contains(custom.id)) {
        items.insert(0, _CategoryItem(
          id: custom.id,
          name: custom.name,
          color: custom.color,
          isCustom: true,
        ));
      }
    }

    setState(() {
      _categories = items;
      _isLoading = false;
    });
  }

  Future<void> _saveOrder() async {
    final order = _categories.map((c) => c.id).toList();
    await _service.saveCategoryOrder(widget.listId, order);
    setState(() => _hasChanges = true);
  }

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    Color selectedColor = AppColors.lightAccent;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    context.tr('add_category'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: context.tr('category_name'),
                      hintText: context.tr('category_name_hint'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                    ),
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    context.tr('select_color'),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      Colors.red,
                      Colors.pink,
                      Colors.purple,
                      Colors.deepPurple,
                      Colors.indigo,
                      Colors.blue,
                      Colors.lightBlue,
                      Colors.cyan,
                      Colors.teal,
                      Colors.green,
                      Colors.lightGreen,
                      Colors.lime,
                      Colors.amber,
                      Colors.orange,
                      Colors.deepOrange,
                      Colors.brown,
                    ].map((color) => GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setDialogState(() => selectedColor = color);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: selectedColor == color
                              ? Border.all(color: isDark ? Colors.white : Colors.black, width: 3)
                              : Border.all(color: Colors.transparent, width: 3),
                          boxShadow: selectedColor == color
                              ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8, spreadRadius: 2)]
                              : null,
                        ),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () async {
                      if (nameController.text.trim().isEmpty) return;
                      
                      final category = await _service.addCustomCategory(
                        widget.listId,
                        nameController.text.trim(),
                        selectedColor,
                      );
                      
                      Navigator.pop(context);
                      
                      setState(() {
                        _categories.insert(0, _CategoryItem(
                          id: category.id,
                          name: category.name,
                          color: category.color,
                          isCustom: true,
                        ));
                        _hasChanges = true;
                      });
                      await _saveOrder();
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(context.tr('add')),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showEditCategoryDialog(_CategoryItem category) {
    final nameController = TextEditingController(text: category.name);
    Color selectedColor = category.color;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    context.tr('edit_category'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: context.tr('category_name'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    context.tr('select_color'),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      Colors.red,
                      Colors.pink,
                      Colors.purple,
                      Colors.deepPurple,
                      Colors.indigo,
                      Colors.blue,
                      Colors.lightBlue,
                      Colors.cyan,
                      Colors.teal,
                      Colors.green,
                      Colors.lightGreen,
                      Colors.lime,
                      Colors.amber,
                      Colors.orange,
                      Colors.deepOrange,
                      Colors.brown,
                    ].map((color) => GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setDialogState(() => selectedColor = color);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: selectedColor == color
                              ? Border.all(color: isDark ? Colors.white : Colors.black, width: 3)
                              : Border.all(color: Colors.transparent, width: 3),
                          boxShadow: selectedColor == color
                              ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8, spreadRadius: 2)]
                              : null,
                        ),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _showDeleteConfirmation(category),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(context.tr('delete')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: () async {
                            if (nameController.text.trim().isEmpty) return;
                            
                            final updated = CustomCategory(
                              id: category.id,
                              name: nameController.text.trim(),
                              color: selectedColor,
                            );
                            await _service.updateCustomCategory(widget.listId, updated);
                            
                            Navigator.pop(context);
                            
                            setState(() {
                              final index = _categories.indexWhere((c) => c.id == category.id);
                              if (index != -1) {
                                _categories[index] = _CategoryItem(
                                  id: category.id,
                                  name: nameController.text.trim(),
                                  color: selectedColor,
                                  isCustom: true,
                                );
                              }
                              _hasChanges = true;
                            });
                          },
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(context.tr('save')),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(_CategoryItem category) {
    Navigator.pop(context); // Close edit sheet first
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('delete_category')),
        content: Text(context.tr('delete_category_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              await _service.deleteCustomCategory(widget.listId, category.id);
              Navigator.pop(context);
              setState(() {
                _categories.removeWhere((c) => c.id == category.id);
                _hasChanges = true;
              });
            },
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIOS26 = PlatformInfo.isIOS26OrHigher();
    
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: isIOS26
            ? Padding(
                padding: const EdgeInsets.only(left: 8),
                child: AdaptiveButton.sfSymbol(
                  sfSymbol: const SFSymbol('xmark'),
                  style: AdaptiveButtonStyle.glass,
                  size: AdaptiveButtonSize.small,
                  onPressed: () => Navigator.pop(context, _hasChanges),
                ),
              )
            : IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.close, size: 20),
                ),
                onPressed: () => Navigator.pop(context, _hasChanges),
              ),
        title: Text(
          context.tr('category_order'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          // Add button
          isIOS26
              ? Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: AdaptiveButton.sfSymbol(
                    sfSymbol: const SFSymbol('plus'),
                    style: AdaptiveButtonStyle.glass,
                    size: AdaptiveButtonSize.small,
                    onPressed: _showAddCategoryDialog,
                  ),
                )
              : IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add, size: 20),
                  ),
                  onPressed: _showAddCategoryDialog,
                ),
          // Done button
          isIOS26
              ? Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AdaptiveButton.sfSymbol(
                    sfSymbol: const SFSymbol('checkmark'),
                    style: AdaptiveButtonStyle.prominentGlass,
                    size: AdaptiveButtonSize.small,
                    onPressed: () => Navigator.pop(context, _hasChanges),
                  ),
                )
              : IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.lightAccent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.lightAccent.withOpacity(0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.check, size: 20, color: Colors.white),
                  ),
                  onPressed: () => Navigator.pop(context, _hasChanges),
                ),
          if (!isIOS26) const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Info text
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[850] : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.grey[500],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          context.tr('drag_to_reorder'),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Categories list
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _categories.length,
                    onReorder: (oldIndex, newIndex) {
                      HapticFeedback.mediumImpact();
                      setState(() {
                        if (newIndex > oldIndex) newIndex--;
                        final item = _categories.removeAt(oldIndex);
                        _categories.insert(newIndex, item);
                      });
                      _saveOrder();
                    },
                    proxyDecorator: (child, index, animation) {
                      return AnimatedBuilder(
                        animation: animation,
                        builder: (context, child) {
                          final scale = Tween<double>(begin: 1.0, end: 1.05).animate(animation);
                          return Transform.scale(
                            scale: scale.value,
                            child: Material(
                              elevation: 8,
                              borderRadius: BorderRadius.circular(16),
                              shadowColor: Colors.black26,
                              child: child,
                            ),
                          );
                        },
                        child: child,
                      );
                    },
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return _buildCategoryTile(category, isDark);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCategoryTile(_CategoryItem category, bool isDark) {
    return Container(
      key: ValueKey(category.id),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: category.color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            category.isCustom ? Icons.label : _getCategoryIcon(category.id),
            color: category.color,
            size: 24,
          ),
        ),
        title: Text(
          category.isCustom 
              ? category.name 
              : Categories.getById(category.id).getName(Localizations.localeOf(context).languageCode),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: category.isCustom 
            ? Text(
                context.tr('custom_category'),
                style: TextStyle(
                  fontSize: 12,
                  color: category.color,
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (category.isCustom)
              IconButton(
                icon: Icon(Icons.edit_outlined, color: Colors.grey[500], size: 20),
                onPressed: () => _showEditCategoryDialog(category),
              ),
            Icon(Icons.drag_handle, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String categoryId) {
    try {
      return Categories.getById(categoryId).icon;
    } catch (e) {
      return Icons.category;
    }
  }
}

class _CategoryItem {
  final String id;
  final String name;
  final Color color;
  final bool isCustom;

  _CategoryItem({
    required this.id,
    required this.name,
    required this.color,
    required this.isCustom,
  });
}
