import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for handling voice assistant commands (Siri & Google Assistant)
class VoiceAssistantService {
  static const MethodChannel _channel = MethodChannel('com.shoply.voice_assistant');
  final _supabase = Supabase.instance.client;

  /// Initialize voice assistant handlers
  Future<void> initialize() async {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  /// Handle incoming voice commands from native platforms
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'addItemToList':
        return await _handleAddItemToList(call.arguments);
      case 'createList':
        return await _handleCreateList(call.arguments);
      case 'viewList':
        return await _handleViewList(call.arguments);
      default:
        throw PlatformException(
          code: 'UNIMPLEMENTED',
          message: 'Method ${call.method} not implemented',
        );
    }
  }

  /// Handle "Add item to list" command
  Future<Map<String, dynamic>> _handleAddItemToList(dynamic arguments) async {
    try {
      final args = arguments as Map<dynamic, dynamic>;
      final itemName = args['itemName'] as String?;
      final listName = args['listName'] as String?;

      if (itemName == null || itemName.isEmpty) {
        return {
          'success': false,
          'message': 'Item name is required',
        };
      }

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return {
          'success': false,
          'message': 'User not authenticated',
        };
      }

      // Find the target list
      String? targetListId;
      String? targetListName;

      if (listName != null && listName.isNotEmpty) {
        // Search for list by name (fuzzy matching)
        final listsResponse = await _supabase
            .from('shopping_lists')
            .select('id, name')
            .eq('user_id', userId)
            .ilike('name', '%$listName%')
            .limit(1)
            .maybeSingle();

        if (listsResponse != null) {
          targetListId = listsResponse['id'] as String;
          targetListName = listsResponse['name'] as String;
        }
      }

      // If no list specified or not found, use last accessed list
      if (targetListId == null) {
        final lastListResponse = await _supabase
            .from('shopping_lists')
            .select('id, name')
            .eq('user_id', userId)
            .not('last_accessed_at', 'is', null)
            .order('last_accessed_at', ascending: false)
            .limit(1)
            .maybeSingle();

        if (lastListResponse != null) {
          targetListId = lastListResponse['id'] as String;
          targetListName = lastListResponse['name'] as String;
        }
      }

      // If still no list, create a default one
      if (targetListId == null) {
        final newListResponse = await _supabase
            .from('shopping_lists')
            .insert({
              'user_id': userId,
              'name': 'My Shopping List',
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .select('id, name')
            .single();

        targetListId = newListResponse['id'] as String;
        targetListName = newListResponse['name'] as String;
      }

      // Add the item to the list
      await _supabase.from('shopping_items').insert({
        'list_id': targetListId,
        'name': itemName,
        'quantity': 1.0,
        'unit': 'pcs',
        'is_checked': false,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      return {
        'success': true,
        'message': 'Added $itemName to $targetListName',
        'listId': targetListId,
        'listName': targetListName,
        'itemName': itemName,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  /// Handle "Create list" command
  Future<Map<String, dynamic>> _handleCreateList(dynamic arguments) async {
    try {
      final args = arguments as Map<dynamic, dynamic>;
      final listName = args['listName'] as String?;

      if (listName == null || listName.isEmpty) {
        return {
          'success': false,
          'message': 'List name is required',
        };
      }

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return {
          'success': false,
          'message': 'User not authenticated',
        };
      }

      final response = await _supabase
          .from('shopping_lists')
          .insert({
            'user_id': userId,
            'name': listName,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select('id, name')
          .single();

      return {
        'success': true,
        'message': 'Created list: $listName',
        'listId': response['id'],
        'listName': response['name'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  /// Handle "View list" command
  Future<Map<String, dynamic>> _handleViewList(dynamic arguments) async {
    try {
      final args = arguments as Map<dynamic, dynamic>;
      final listName = args['listName'] as String?;

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return {
          'success': false,
          'message': 'User not authenticated',
        };
      }

      String? targetListId;
      String? targetListName;

      if (listName != null && listName.isNotEmpty) {
        // Search for list by name
        final response = await _supabase
            .from('shopping_lists')
            .select('id, name')
            .eq('user_id', userId)
            .ilike('name', '%$listName%')
            .limit(1)
            .maybeSingle();

        if (response != null) {
          targetListId = response['id'] as String;
          targetListName = response['name'] as String;
        }
      } else {
        // Use last accessed list
        final response = await _supabase
            .from('shopping_lists')
            .select('id, name')
            .eq('user_id', userId)
            .not('last_accessed_at', 'is', null)
            .order('last_accessed_at', ascending: false)
            .limit(1)
            .maybeSingle();

        if (response != null) {
          targetListId = response['id'] as String;
          targetListName = response['name'] as String;
        }
      }

      if (targetListId == null) {
        return {
          'success': false,
          'message': 'No list found',
        };
      }

      return {
        'success': true,
        'message': 'Opening $targetListName',
        'listId': targetListId,
        'listName': targetListName,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  /// Register Siri shortcut (iOS)
  Future<void> registerSiriShortcut({
    required String phrase,
    required String action,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      await _channel.invokeMethod('registerSiriShortcut', {
        'phrase': phrase,
        'action': action,
        'parameters': parameters,
      });
    } catch (e) {
      print('Error registering Siri shortcut: $e');
    }
  }

  /// Donate Siri shortcut (iOS) - makes it appear in Siri suggestions
  Future<void> donateSiriShortcut({
    required String action,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      await _channel.invokeMethod('donateSiriShortcut', {
        'action': action,
        'parameters': parameters,
      });
    } catch (e) {
      print('Error donating Siri shortcut: $e');
    }
  }
}
