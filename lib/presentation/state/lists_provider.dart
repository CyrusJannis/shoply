import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoply/data/models/shopping_list_model.dart';
import 'package:shoply/data/repositories/list_repository.dart';

/// List repository provider
final listRepositoryProvider = Provider<ListRepository>((ref) {
  return ListRepository();
});

/// Provider for all user lists
final userListsProvider = FutureProvider<List<ShoppingListModel>>((ref) async {
  final repository = ref.watch(listRepositoryProvider);
  return repository.getUserLists();
});

/// Provider for a single list by ID
final listByIdProvider = FutureProvider.family<ShoppingListModel?, String>((ref, listId) async {
  final repository = ref.watch(listRepositoryProvider);
  return repository.getListById(listId);
});

/// State notifier for managing lists
class ListsNotifier extends StateNotifier<AsyncValue<List<ShoppingListModel>>> {
  final ListRepository _repository;

  ListsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadLists();
    _setupRealtimeSubscription();
  }

  void _setupRealtimeSubscription() {
    // Subscribe to shopping_items changes to refresh lists when items change
    _repository.subscribeToItemChanges(() {
      loadLists();
    });
  }

  Future<void> loadLists() async {
    state = const AsyncValue.loading();
    try {
      final lists = await _repository.getUserLists();
      state = AsyncValue.data(lists);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
  
  @override
  void dispose() {
    _repository.unsubscribeFromItemChanges();
    super.dispose();
  }

  Future<void> createList(String name) async {
    try {
      await _repository.createList(name);
      await loadLists();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> updateList(String listId, Map<String, dynamic> updates) async {
    try {
      await _repository.updateList(listId, updates);
      await loadLists();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> deleteList(String listId) async {
    try {
      await _repository.deleteList(listId);
      await loadLists();
    } catch (error) {
      rethrow;
    }
  }

  Future<String> generateShareCode(String listId) async {
    try {
      final code = await _repository.generateShareCode(listId);
      await loadLists();
      return code;
    } catch (error) {
      rethrow;
    }
  }

  Future<ShoppingListModel?> joinListWithCode(String shareCode) async {
    try {
      final list = await _repository.joinListWithCode(shareCode);
      await loadLists();
      return list;
    } catch (error) {
      rethrow;
    }
  }

  Future<ShoppingListModel?> joinListWithLink(String shareLink) async {
    try {
      final list = await _repository.joinListWithLink(shareLink);
      await loadLists();
      return list;
    } catch (error) {
      rethrow;
    }
  }

  Future<String?> getShareLink(String listId) async {
    try {
      return await _repository.getShareLink(listId);
    } catch (error) {
      rethrow;
    }
  }
}

/// Lists state notifier provider
final listsNotifierProvider =
    StateNotifierProvider<ListsNotifier, AsyncValue<List<ShoppingListModel>>>((ref) {
  final repository = ref.watch(listRepositoryProvider);
  return ListsNotifier(repository);
});
