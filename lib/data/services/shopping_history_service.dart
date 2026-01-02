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

    } catch (e) {
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


      return (response as List)
          .map((json) {
            return ShoppingHistory.fromJson(json as Map<String, dynamic>);
          })
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get recent shopping history
  Future<List<ShoppingHistory>> getRecentHistory({int limit = 3}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('shopping_history')
          .select('*, items:shopping_history_items(*)')
          .eq('user_id', userId)
          .order('completed_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => ShoppingHistory.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a shopping history entry
  Future<void> deleteHistory(String historyId) async {
    try {
      await _supabase.from('shopping_history').delete().eq('id', historyId);
    } catch (e) {
      rethrow;
    }
  }
}
