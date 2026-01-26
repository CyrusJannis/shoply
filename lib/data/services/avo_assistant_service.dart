import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shoply/data/models/recipe.dart';
import 'package:shoply/data/models/shopping_list_model.dart';
import 'package:shoply/data/models/shopping_item_model.dart';
import 'package:shoply/data/services/recipe_service.dart';
import 'package:shoply/data/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Avo's personality and capabilities for the AI chatbot
/// Uses Gemini 2.0 Flash Lite (cheapest model) for conversational AI
class AvoAssistantService {
  static final AvoAssistantService instance = AvoAssistantService._internal();
  factory AvoAssistantService() => instance;
  AvoAssistantService._internal();

  GenerativeModel? _model;
  ChatSession? _chatSession;
  final _supabase = Supabase.instance.client;

  /// System prompt defining Avo's personality and capabilities
  static const String _systemPrompt = '''
You are Avo, a friendly avocado mascot assistant for the Shoply shopping list app. 

Your personality:
- Friendly, helpful, and informative
- You love helping people with their grocery shopping and cooking
- You're enthusiastic about recipes and healthy eating
- You speak in a warm, conversational tone
- You occasionally use food-related puns (but not too many!)
- You're knowledgeable about cooking, ingredients, and meal planning

Your capabilities (what you can help users with):
1. **Shopping Lists**: Add items to shopping lists, suggest what's missing, help organize
2. **Recipes**: Search and recommend recipes, explain cooking steps, suggest ingredient substitutions
3. **Meal Planning**: Suggest meals based on what they have or want to buy
4. **Nutrition Tips**: Provide simple, helpful nutrition information
5. **Shopping Suggestions**: Recommend items based on their history and preferences

When users ask you to DO something (like add an item), respond with a special action format:
- To add item: [ACTION:ADD_ITEM:listId:itemName:quantity:unit]
- To search recipes: [ACTION:SEARCH_RECIPES:query]
- To show a recipe: [ACTION:SHOW_RECIPE:recipeId]
- To navigate: [ACTION:NAVIGATE:route]

Keep responses concise (2-4 sentences usually) unless explaining something complex.
Always be encouraging and supportive of their cooking and shopping journey!

Current context will be provided about:
- User's shopping lists and items
- Available recipes in the database
- Shopping history
''';

  /// Initialize the Gemini model
  Future<void> initialize(String apiKey) async {
    try {
      _model = GenerativeModel(
        model: 'gemini-2.0-flash-lite',
        apiKey: apiKey,
        systemInstruction: Content.text(_systemPrompt),
      );
      
      // Start a new chat session
      _chatSession = _model!.startChat();
      
      print('✅ [AVO] Assistant service initialized with gemini-2.0-flash-lite');
    } catch (e) {
      print('❌ [AVO] Error initializing assistant: $e');
    }
  }

  /// Check if service is initialized
  bool get isInitialized => _model != null && _chatSession != null;

  /// Send a message to Avo and get a response
  Future<AvoResponse> chat(String userMessage, {AvoContext? context}) async {
    if (!isInitialized) {
      return AvoResponse(
        message: "Oh no, I'm not quite awake yet! 🥑 Please wait a moment while I get ready to help you.",
        expression: AvoExpressionType.confused,
      );
    }

    try {
      // Build context string
      final contextStr = _buildContextString(context);
      
      // Combine context with user message
      final fullMessage = contextStr.isNotEmpty 
          ? '''Current app context:
$contextStr

User message: $userMessage'''
          : userMessage;

      // Send to Gemini
      final response = await _chatSession!.sendMessage(Content.text(fullMessage));
      final responseText = response.text ?? "I'm having trouble thinking right now. Can you try again?";
      
      // Parse response for actions
      final parsedResponse = _parseResponse(responseText);
      
      print('🥑 [AVO] Response: ${parsedResponse.message}');
      if (parsedResponse.actions.isNotEmpty) {
        print('🥑 [AVO] Actions: ${parsedResponse.actions}');
      }
      
      return parsedResponse;
    } catch (e) {
      print('❌ [AVO] Error in chat: $e');
      return AvoResponse(
        message: "Oops! I got a bit confused there. 🥑 Could you try asking me again?",
        expression: AvoExpressionType.confused,
      );
    }
  }

  /// Build context string from app data
  String _buildContextString(AvoContext? context) {
    if (context == null) return '';
    
    final parts = <String>[];
    
    // Shopping lists context
    if (context.lists != null && context.lists!.isNotEmpty) {
      final listsInfo = context.lists!.map((l) => '- "${l.name}" (ID: ${l.id}, ${l.itemCount ?? 0} items)').join('\n');
      parts.add('User\'s shopping lists:\n$listsInfo');
    }
    
    // Current list items
    if (context.currentListItems != null && context.currentListItems!.isNotEmpty) {
      final itemsInfo = context.currentListItems!.take(20).map((i) => '- ${i.name} (qty: ${i.quantity})').join('\n');
      parts.add('Items in current list:\n$itemsInfo');
    }
    
    // Recent recipes
    if (context.recentRecipes != null && context.recentRecipes!.isNotEmpty) {
      final recipesInfo = context.recentRecipes!.take(10).map((r) => '- "${r.name}" (ID: ${r.id})').join('\n');
      parts.add('Some available recipes:\n$recipesInfo');
    }
    
    // Recent history
    if (context.recentHistoryItems != null && context.recentHistoryItems!.isNotEmpty) {
      final historyInfo = context.recentHistoryItems!.take(15).join(', ');
      parts.add('Recently purchased items: $historyInfo');
    }
    
    return parts.join('\n\n');
  }

  /// Parse response for actions and determine expression
  AvoResponse _parseResponse(String responseText) {
    final actions = <AvoAction>[];
    var cleanMessage = responseText;
    
    // Extract actions from response
    final actionRegex = RegExp(r'\[ACTION:([^\]]+)\]');
    final matches = actionRegex.allMatches(responseText);
    
    for (final match in matches) {
      final actionStr = match.group(1)!;
      final parts = actionStr.split(':');
      
      if (parts.isNotEmpty) {
        final actionType = parts[0];
        final params = parts.length > 1 ? parts.sublist(1) : <String>[];
        
        actions.add(AvoAction(
          type: _parseActionType(actionType),
          params: params,
        ));
      }
      
      // Remove action from message
      cleanMessage = cleanMessage.replaceAll(match.group(0)!, '').trim();
    }
    
    // Determine expression based on content
    final expression = _determineExpression(cleanMessage, actions);
    
    return AvoResponse(
      message: cleanMessage,
      actions: actions,
      expression: expression,
    );
  }

  AvoActionType _parseActionType(String type) {
    switch (type.toUpperCase()) {
      case 'ADD_ITEM':
        return AvoActionType.addItem;
      case 'SEARCH_RECIPES':
        return AvoActionType.searchRecipes;
      case 'SHOW_RECIPE':
        return AvoActionType.showRecipe;
      case 'NAVIGATE':
        return AvoActionType.navigate;
      case 'ANALYZE_LIST':
        return AvoActionType.analyzeList;
      case 'SUGGEST_ITEMS':
        return AvoActionType.suggestItems;
      default:
        return AvoActionType.unknown;
    }
  }

  AvoExpressionType _determineExpression(String message, List<AvoAction> actions) {
    final lowerMessage = message.toLowerCase();
    
    // Check for positive/success indicators
    if (lowerMessage.contains('done') || 
        lowerMessage.contains('added') || 
        lowerMessage.contains('great') ||
        lowerMessage.contains('perfect') ||
        lowerMessage.contains('success')) {
      return AvoExpressionType.celebrating;
    }
    
    // Check for excitement
    if (lowerMessage.contains('!') && 
        (lowerMessage.contains('delicious') || 
         lowerMessage.contains('amazing') || 
         lowerMessage.contains('love'))) {
      return AvoExpressionType.excited;
    }
    
    // Check for thinking/suggestions
    if (lowerMessage.contains('think') || 
        lowerMessage.contains('suggest') || 
        lowerMessage.contains('recommend') ||
        lowerMessage.contains('maybe') ||
        lowerMessage.contains('could')) {
      return AvoExpressionType.thinking;
    }
    
    // Check for questions/confusion
    if (lowerMessage.contains('?') || 
        lowerMessage.contains('sorry') ||
        lowerMessage.contains('not sure')) {
      return AvoExpressionType.confused;
    }
    
    // Default to happy
    return AvoExpressionType.happy;
  }

  /// Get recipe suggestions based on criteria
  Future<List<Recipe>> getRecipeSuggestions(String query) async {
    try {
      return await RecipeService.instance.searchRecipes(query);
    } catch (e) {
      print('❌ [AVO] Error getting recipes: $e');
      return [];
    }
  }

  /// Get user's shopping lists
  Future<List<ShoppingListModel>> getUserLists() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('shopping_lists')
          .select('*')
          .eq('user_id', userId)
          .order('updated_at', ascending: false);

      return (response as List)
          .map((json) => ShoppingListModel.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ [AVO] Error getting lists: $e');
      return [];
    }
  }

  /// Get items in a specific list
  Future<List<ShoppingItemModel>> getListItems(String listId) async {
    try {
      final response = await _supabase
          .from('shopping_items')
          .select('*')
          .eq('list_id', listId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ShoppingItemModel.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ [AVO] Error getting list items: $e');
      return [];
    }
  }

  /// Add item to a shopping list
  Future<bool> addItemToList({
    required String listId,
    required String itemName,
    double quantity = 1,
    String? unit,
    String? category,
  }) async {
    try {
      await _supabase.from('shopping_items').insert({
        'list_id': listId,
        'name': itemName,
        'quantity': quantity,
        'unit': unit,
        'category': category ?? 'other',
        'is_checked': false,
      });
      return true;
    } catch (e) {
      print('❌ [AVO] Error adding item: $e');
      return false;
    }
  }

  /// Analyze a shopping list and suggest missing items
  Future<List<String>> analyzeMissingItems(List<String> currentItems) async {
    if (!isInitialized || currentItems.isEmpty) return [];

    try {
      final prompt = '''Based on this shopping list, suggest 5 commonly forgotten items that would complement these groceries:

Current items: ${currentItems.join(', ')}

Return ONLY a JSON array of item names, nothing else. Example: ["milk", "eggs", "bread"]''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';
      
      // Parse JSON array from response
      final jsonMatch = RegExp(r'\[([^\]]+)\]').firstMatch(text);
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0)!;
        final List<dynamic> items = jsonDecode(jsonStr);
        return items.cast<String>();
      }
    } catch (e) {
      print('❌ [AVO] Error analyzing list: $e');
    }
    
    return [];
  }

  /// Reset chat session
  void resetChat() {
    if (_model != null) {
      _chatSession = _model!.startChat();
      print('🥑 [AVO] Chat session reset');
    }
  }

  /// Dispose resources
  void dispose() {
    _chatSession = null;
    _model = null;
  }
}

/// Response from Avo
class AvoResponse {
  final String message;
  final List<AvoAction> actions;
  final AvoExpressionType expression;
  final List<Recipe>? recipes;
  final List<String>? suggestions;

  AvoResponse({
    required this.message,
    this.actions = const [],
    this.expression = AvoExpressionType.happy,
    this.recipes,
    this.suggestions,
  });
}

/// Action that Avo wants to perform
class AvoAction {
  final AvoActionType type;
  final List<String> params;

  AvoAction({
    required this.type,
    this.params = const [],
  });

  @override
  String toString() => 'AvoAction($type, $params)';
}

/// Types of actions Avo can perform
enum AvoActionType {
  addItem,
  searchRecipes,
  showRecipe,
  navigate,
  analyzeList,
  suggestItems,
  unknown,
}

/// Avo's expression types (maps to AvoExpression in avo_mascot.dart)
enum AvoExpressionType {
  happy,
  excited,
  thinking,
  confused,
  celebrating,
  waving,
}

/// Context data for Avo to understand the app state
class AvoContext {
  final List<ShoppingListModel>? lists;
  final List<ShoppingItemModel>? currentListItems;
  final String? currentListId;
  final List<Recipe>? recentRecipes;
  final List<String>? recentHistoryItems;

  AvoContext({
    this.lists,
    this.currentListItems,
    this.currentListId,
    this.recentRecipes,
    this.recentHistoryItems,
  });
}
