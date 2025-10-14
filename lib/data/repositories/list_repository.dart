import 'package:shoply/data/models/shopping_list_model.dart';
import 'package:shoply/data/services/supabase_service.dart';

class ListRepository {
  final SupabaseService _supabase;

  ListRepository({SupabaseService? supabase})
      : _supabase = supabase ?? SupabaseService.instance;

  /// Get all lists for the current user
  Future<List<ShoppingListModel>> getUserLists() async {
    final userId = _supabase.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase.from('shopping_lists').select('''
      *,
      items:shopping_items(count)
    ''').or('owner_id.eq.$userId,id.in.(select list_id from list_members where user_id=$userId)');

    return (response as List)
        .map((json) => ShoppingListModel.fromJson(json))
        .toList();
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
    // Generate random 6-digit code
    final code = _generateRandomCode();

    await _supabase.from('shopping_lists').update({
      'share_code': code,
      'is_shared': true,
    }).eq('id', listId);

    return code;
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
    final random = DateTime.now().millisecondsSinceEpoch % 1000000;
    return random.toString().padLeft(6, '0');
  }
}
