import 'package:shoply/data/models/shopping_item_model.dart';
import 'package:shoply/data/services/supabase_service.dart';

class ItemRepository {
  final SupabaseService _supabase;

  ItemRepository({SupabaseService? supabase})
      : _supabase = supabase ?? SupabaseService.instance;

  /// Get all items for a list
  Future<List<ShoppingItemModel>> getListItems(String listId) async {
    final response = await _supabase
        .from('shopping_items')
        .select()
        .eq('list_id', listId)
        .order('created_at', ascending: true);

    return (response as List)
        .map((json) => ShoppingItemModel.fromJson(json))
        .toList();
  }

  /// Add a new item to a list
  Future<ShoppingItemModel> addItem({
    required String listId,
    required String name,
    double quantity = 1.0,
    String? unit,
    String? category,
    String? notes,
    bool isDietWarning = false,
    String? barcode,
  }) async {
    final userId = _supabase.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase.from('shopping_items').insert({
      'list_id': listId,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'category': category,
      'notes': notes,
      'is_diet_warning': isDietWarning,
      'barcode': barcode,
      'added_by': userId,
    }).select().single();

    return ShoppingItemModel.fromJson(response);
  }

  /// Update an item
  Future<ShoppingItemModel> updateItem(
    String itemId,
    Map<String, dynamic> updates,
  ) async {
    final response = await _supabase
        .from('shopping_items')
        .update(updates)
        .eq('id', itemId)
        .select()
        .single();

    return ShoppingItemModel.fromJson(response);
  }

  /// Toggle item checked status
  Future<ShoppingItemModel> toggleItemChecked(
    String itemId,
    bool isChecked,
  ) async {
    final updates = {
      'is_checked': isChecked,
      'checked_at': isChecked ? DateTime.now().toIso8601String() : null,
    };

    return updateItem(itemId, updates);
  }

  /// Delete an item
  Future<void> deleteItem(String itemId) async {
    await _supabase.from('shopping_items').delete().eq('id', itemId);
  }

  /// Update sort order for items
  Future<void> updateSortOrder(List<String> itemIds) async {
    for (var i = 0; i < itemIds.length; i++) {
      await _supabase
          .from('shopping_items')
          .update({'sort_order': i})
          .eq('id', itemIds[i]);
    }
  }

  /// Get items by category
  Future<Map<String, List<ShoppingItemModel>>> getItemsByCategory(
    String listId,
  ) async {
    final items = await getListItems(listId);
    final grouped = <String, List<ShoppingItemModel>>{};

    for (final item in items) {
      final category = item.category ?? 'Other';
      grouped.putIfAbsent(category, () => []).add(item);
    }

    return grouped;
  }

  /// Search items
  Future<List<ShoppingItemModel>> searchItems(
    String listId,
    String query,
  ) async {
    final response = await _supabase
        .from('shopping_items')
        .select()
        .eq('list_id', listId)
        .or('name.ilike.%$query%,category.ilike.%$query%,notes.ilike.%$query%');

    return (response as List)
        .map((json) => ShoppingItemModel.fromJson(json))
        .toList();
  }
}
