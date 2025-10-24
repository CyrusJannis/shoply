import 'package:shoply/data/models/shopping_history.dart';
import 'package:shoply/data/models/shopping_item_model.dart';
import 'package:shoply/data/services/purchase_tracking_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ShoppingHistoryService {
  final _supabase = Supabase.instance.client;
  final _trackingService = PurchaseTrackingService();

  /// Complete a shopping trip and move items to history
  Future<void> completeShoppingTrip({
    required String listName,
    required List<ShoppingItemModel> items,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Create history entry
      final historyData = {
        'user_id': userId,
        'list_name': listName,
        'total_items': items.length,
        'completed_at': DateTime.now().toIso8601String(),
      };

      final historyResponse = await _supabase
          .from('shopping_history')
          .insert(historyData)
          .select()
          .single();

      final historyId = historyResponse['id'] as String;

      // Add items to history
      final historyItems = items.map((item) => {
        'history_id': historyId,
        'name': item.name,
        'quantity': item.quantity,
        'unit': item.unit,
        'category': item.category,
      }).toList();

      await _supabase.from('shopping_history_items').insert(historyItems);

      // Track purchases for recommendations
      await _trackingService.trackPurchases(items);

      print('Shopping trip completed: $historyId');
    } catch (e) {
      print('Error completing shopping trip: $e');
      rethrow;
    }
  }

  /// Get shopping history for current user
  Future<List<ShoppingHistory>> getShoppingHistory() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('shopping_history')
          .select('*, items:shopping_history_items(*)')
          .eq('user_id', userId)
          .order('completed_at', ascending: false);

      print('Shopping history response: $response');

      return (response as List)
          .map((json) {
            print('Processing history entry: $json');
            return ShoppingHistory.fromJson(json as Map<String, dynamic>);
          })
          .toList();
    } catch (e) {
      print('Error fetching shopping history: $e');
      rethrow;
    }
  }

  /// Get recent shopping history (last 3)
  Future<List<ShoppingHistory>> getRecentHistory() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('shopping_history')
          .select('*, items:shopping_history_items(*)')
          .eq('user_id', userId)
          .order('completed_at', ascending: false)
          .limit(3);

      return (response as List)
          .map((json) => ShoppingHistory.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching recent history: $e');
      rethrow;
    }
  }

  /// Delete a shopping history entry
  Future<void> deleteHistory(String historyId) async {
    try {
      await _supabase.from('shopping_history').delete().eq('id', historyId);
      print('History deleted: $historyId');
    } catch (e) {
      print('Error deleting history: $e');
      rethrow;
    }
  }
}
