import 'package:shoply/core/constants/app_config.dart';
import 'package:shoply/data/models/shopping_list_model.dart';
import 'package:shoply/data/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ListRepository {
  final SupabaseService _supabase;
  RealtimeChannel? _itemsChannel;

  ListRepository({SupabaseService? supabase})
      : _supabase = supabase ?? SupabaseService.instance;

  /// Get all lists for the current user
  Future<List<ShoppingListModel>> getUserLists() async {
    final userId = _supabase.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    print('DEBUG: Current user ID: $userId');

    // First, get list IDs where user is a member
    final memberResponse = await _supabase
        .from('list_members')
        .select('list_id')
        .eq('user_id', userId);
    
    final memberListIds = (memberResponse as List)
        .map((m) => m['list_id'] as String)
        .toSet();
    
    print('DEBUG: User is member of ${memberListIds.length} lists');

    // Get all lists where user is owner
    final ownedLists = await _supabase.from('shopping_lists').select('''
      *,
      items:shopping_items(count)
    ''').eq('owner_id', userId);

    // Get all lists where user is a member (but not owner)
    List sharedLists = [];
    if (memberListIds.isNotEmpty) {
      sharedLists = await _supabase.from('shopping_lists').select('''
        *,
        items:shopping_items(count)
      ''').inFilter('id', memberListIds.toList());
    }

    // Combine both lists and remove duplicates
    final allListsMap = <String, dynamic>{};
    for (var list in [...(ownedLists as List), ...sharedLists]) {
      allListsMap[list['id']] = list;
    }

    final allLists = allListsMap.values.toList();
    
    print('DEBUG: Found ${allLists.length} lists total');
    for (var list in allLists) {
      print('DEBUG: List "${list['name']}" - owner_id: ${list['owner_id']}');
    }

    final lists = allLists
        .map((json) => ShoppingListModel.fromJson(json))
        .toList();
    
    // Sort by order_index (nulls last)
    lists.sort((a, b) {
      final aOrder = a.orderIndex ?? 999999;
      final bOrder = b.orderIndex ?? 999999;
      return aOrder.compareTo(bOrder);
    });
    
    return lists;
  }

  /// Get a single list by ID
  Future<ShoppingListModel?> getListById(String listId) async {
    final response = await _supabase
        .from('shopping_lists')
        .select()
        .eq('id', listId)
        .maybeSingle();

    if (response == null) return null;
    return ShoppingListModel.fromJson(response);
  }

  /// Create a new shopping list
  Future<ShoppingListModel> createList(String name) async {
    final userId = _supabase.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase.from('shopping_lists').insert({
      'name': name,
      'owner_id': userId,
    }).select().single();

    // Also add user as owner in list_members
    await _supabase.from('list_members').insert({
      'list_id': response['id'],
      'user_id': userId,
      'role': 'owner',
    });

    return ShoppingListModel.fromJson(response);
  }

  /// Update a list
  Future<ShoppingListModel> updateList(
    String listId,
    Map<String, dynamic> updates,
  ) async {
    final response = await _supabase
        .from('shopping_lists')
        .update(updates)
        .eq('id', listId)
        .select()
        .single();

    return ShoppingListModel.fromJson(response);
  }

  /// Delete a list
  Future<void> deleteList(String listId) async {
    await _supabase.from('shopping_lists').delete().eq('id', listId);
  }

  /// Generate and set share code for a list
  Future<String> generateShareCode(String listId) async {
    print('DEBUG: Generating share code for list: $listId');
    
    // Generate random 6-digit code
    final code = _generateRandomCode();
    print('DEBUG: Generated code: $code');

    // Generate share link
    final shareLink = AppConfig.generateShareLink(code);
    print('DEBUG: Generated share link: $shareLink');

    try {
      await _supabase.from('shopping_lists').update({
        'share_code': code,
        'share_link': shareLink,
        'is_shared': true,
      }).eq('id', listId);
      
      print('DEBUG: Share code and link saved successfully');
    } catch (e) {
      print('DEBUG: Error saving share code: $e');
      rethrow;
    }

    return code;
  }

  /// Get share link for a list
  Future<String?> getShareLink(String listId) async {
    final list = await getListById(listId);
    return list?.shareLink;
  }

  /// Join a list using share code
  Future<ShoppingListModel?> joinListWithCode(String shareCode) async {
    final userId = _supabase.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Find list with share code
    final listResponse = await _supabase
        .from('shopping_lists')
        .select()
        .eq('share_code', shareCode)
        .maybeSingle();

    if (listResponse == null) return null;

    // Add user as member
    await _supabase.from('list_members').insert({
      'list_id': listResponse['id'],
      'user_id': userId,
      'role': 'member',
    });

    return ShoppingListModel.fromJson(listResponse);
  }

  /// Join a list using share link
  Future<ShoppingListModel?> joinListWithLink(String shareLink) async {
    // Extract share code from link
    final shareCode = AppConfig.extractShareCodeFromLink(shareLink);
    if (shareCode == null) {
      throw Exception('Invalid share link');
    }

    // Use existing joinListWithCode method
    return joinListWithCode(shareCode);
  }

  /// Get list members
  Future<List<Map<String, dynamic>>> getListMembers(String listId) async {
    final response = await _supabase
        .from('list_members')
        .select('*, user:users(*)')
        .eq('list_id', listId);

    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Leave a list
  Future<void> leaveList(String listId) async {
    final userId = _supabase.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase
        .from('list_members')
        .delete()
        .eq('list_id', listId)
        .eq('user_id', userId);
  }

  String _generateRandomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    var code = '';
    for (var i = 0; i < 6; i++) {
      code += chars[(random + i) % chars.length];
    }
    return code;
  }

  /// Subscribe to shopping items changes for realtime updates
  void subscribeToItemChanges(Function() onUpdate) {
    _itemsChannel = _supabase.client
        .channel('shopping_items_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'shopping_items',
          callback: (payload) {
            print('DEBUG: Realtime update received for shopping_items');
            onUpdate();
          },
        )
        .subscribe();
  }

  /// Unsubscribe from shopping items changes
  void unsubscribeFromItemChanges() {
    _itemsChannel?.unsubscribe();
    _itemsChannel = null;
  }
}
