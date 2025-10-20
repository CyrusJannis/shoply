import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoply/data/models/shopping_item_model.dart';
import 'package:shoply/data/repositories/item_repository.dart';

/// Item repository provider
final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  return ItemRepository();
});

/// Provider for items in a specific list
final listItemsProvider = FutureProvider.family<List<ShoppingItemModel>, String>((ref, listId) async {
  final repository = ref.watch(itemRepositoryProvider);
  return repository.getListItems(listId);
});

/// Provider for items grouped by category
final itemsByCategoryProvider =
    FutureProvider.family<Map<String, List<ShoppingItemModel>>, String>((ref, listId) async {
  final repository = ref.watch(itemRepositoryProvider);
  return repository.getItemsByCategory(listId);
});

/// State notifier for managing items in a list
class ItemsNotifier extends StateNotifier<AsyncValue<List<ShoppingItemModel>>> {
  final ItemRepository _repository;
  final String listId;

  ItemsNotifier(this._repository, this.listId) : super(const AsyncValue.loading()) {
    loadItems();
    _setupRealtimeSubscription();
  }

  void _setupRealtimeSubscription() {
    // Subscribe to item changes for this specific list
    _repository.subscribeToItemChanges(listId, () {
      print('DEBUG: Realtime update for list $listId - reloading items');
      loadItems();
    });
  }

  Future<void> loadItems() async {
    // Don't show loading state if we already have data (for realtime updates)
    if (state is! AsyncData) {
      state = const AsyncValue.loading();
    }
    try {
      final items = await _repository.getListItems(listId);
      state = AsyncValue.data(items);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
  
  @override
  void dispose() {
    _repository.unsubscribeFromItemChanges(listId);
    super.dispose();
  }

  Future<void> addItem({
    required String name,
    double quantity = 1.0,
    String? unit,
    String? category,
    String? notes,
    bool isDietWarning = false,
    String? barcode,
  }) async {
    try {
      await _repository.addItem(
        listId: listId,
        name: name,
        quantity: quantity,
        unit: unit,
        category: category,
        notes: notes,
        isDietWarning: isDietWarning,
        barcode: barcode,
      );
      await loadItems();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> updateItem(String itemId, Map<String, dynamic> updates) async {
    try {
      await _repository.updateItem(itemId, updates);
      await loadItems();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> toggleItemChecked(String itemId, bool isChecked) async {
    try {
      await _repository.toggleItemChecked(itemId, isChecked);
      await loadItems();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> deleteItem(String itemId) async {
    try {
      await _repository.deleteItem(itemId);
      await loadItems();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> updateSortOrder(List<String> itemIds) async {
    try {
      await _repository.updateSortOrder(itemIds);
      await loadItems();
    } catch (error) {
      rethrow;
    }
  }
}

/// Items state notifier provider factory
final itemsNotifierProvider = StateNotifierProvider.family<ItemsNotifier,
    AsyncValue<List<ShoppingItemModel>>, String>((ref, listId) {
  final repository = ref.watch(itemRepositoryProvider);
  return ItemsNotifier(repository, listId);
});
