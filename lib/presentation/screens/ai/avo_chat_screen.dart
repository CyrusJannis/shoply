import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shoply/core/constants/app_colors.dart';
import 'package:shoply/core/localization/localization_helper.dart';
import 'package:shoply/core/mascot/avo_mascot.dart';
import 'package:shoply/core/widgets/liquid_glass_widgets.dart';
import 'package:shoply/data/models/recipe.dart';
import 'package:shoply/data/models/shopping_list_model.dart';
import 'package:shoply/data/models/shopping_item_model.dart';
import 'package:shoply/data/services/avo_assistant_service.dart';
import 'package:shoply/data/services/gemini_categorization_service.dart';
import 'package:shoply/data/services/recipe_service.dart';
import 'package:shoply/presentation/state/lists_provider.dart';
import 'package:shoply/presentation/state/items_provider.dart';
import 'package:shoply/presentation/state/shopping_history_provider.dart';
import 'package:shoply/presentation/state/recipes_provider.dart';

/// Chat message model
class ChatMessage {
  final String text;
  final bool isUser;
  final AvoExpressionType? avoExpression;
  final List<AvoAction>? actions;
  final List<Recipe>? recipes;
  final DateTime timestamp;
  final bool isLoading;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.avoExpression,
    this.actions,
    this.recipes,
    DateTime? timestamp,
    this.isLoading = false,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Avo Chat Screen - Full conversational AI assistant
class AvoChatScreen extends ConsumerStatefulWidget {
  const AvoChatScreen({super.key});

  @override
  ConsumerState<AvoChatScreen> createState() => _AvoChatScreenState();
}

class _AvoChatScreenState extends ConsumerState<AvoChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAvo();
  }

  Future<void> _initializeAvo() async {
    try {
      // Get API key from Gemini service (already initialized)
      final geminiService = GeminiCategorizationService.instance;
      final stats = geminiService.getCacheStats();
      
      // Initialize Avo with same API key (stored in environment/config)
      // The Gemini service should already be initialized with the key
      // We'll reuse the same initialization
      if (!AvoAssistantService.instance.isInitialized) {
        // Try to get API key from environment or use the one from GeminiCategorizationService
        // For now, we'll initialize with the key from the app config
        const apiKey = String.fromEnvironment('GEMINI_API_KEY', 
            defaultValue: 'REDACTED_FIREBASE_KEY');
        await AvoAssistantService.instance.initialize(apiKey);
      }
      
      setState(() {
        _isInitialized = true;
        // Add welcome message
        _messages.add(ChatMessage(
          text: "Hey there! 🥑 I'm Avo, your shopping buddy! I can help you with:\n\n"
                "• Adding items to your lists\n"
                "• Finding delicious recipes\n"
                "• Suggesting what you might be missing\n"
                "• Answering cooking questions\n\n"
                "Just chat with me - what would you like to do?",
          isUser: false,
          avoExpression: AvoExpressionType.waving,
        ));
      });
    } catch (e) {
      print('❌ [AVO_CHAT] Error initializing: $e');
      setState(() {
        _isInitialized = true;
        _messages.add(ChatMessage(
          text: "Hi! 🥑 I'm having a little trouble connecting right now, but I'll do my best to help you!",
          isUser: false,
          avoExpression: AvoExpressionType.confused,
        ));
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isTyping) return;

    // Clear input
    _messageController.clear();
    HapticFeedback.lightImpact();

    // Add user message
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isTyping = true;
    });
    _scrollToBottom();

    // Build context for Avo
    final context = await _buildAvoContext();

    // Get response from Avo
    final response = await AvoAssistantService.instance.chat(text, context: context);

    // Process any actions
    await _processActions(response.actions);

    // Add Avo's response
    setState(() {
      _messages.add(ChatMessage(
        text: response.message,
        isUser: false,
        avoExpression: response.expression,
        actions: response.actions,
        recipes: response.recipes,
      ));
      _isTyping = false;
    });
    _scrollToBottom();
  }

  Future<AvoContext> _buildAvoContext() async {
    final listsAsync = ref.read(listsNotifierProvider);
    final lists = listsAsync.hasValue ? listsAsync.value! : <ShoppingListModel>[];
    
    // Get recent recipes
    List<Recipe> recipes = [];
    try {
      recipes = await RecipeService.instance.getPopularRecipes(limit: 10);
    } catch (e) {
      print('⚠️ [AVO_CHAT] Could not load recipes: $e');
    }
    
    // Get recent history items
    List<String> historyItems = [];
    final historyAsync = ref.read(recentHistoryProvider);
    if (historyAsync.hasValue) {
      for (final history in historyAsync.value!) {
        for (final item in history.items.take(5)) {
          if (!historyItems.contains(item.name)) {
            historyItems.add(item.name);
          }
        }
      }
    }

    // Get items from first list if available
    List<ShoppingItemModel> currentItems = [];
    if (lists.isNotEmpty) {
      final itemsAsync = ref.read(itemsNotifierProvider(lists.first.id));
      if (itemsAsync.hasValue) {
        currentItems = itemsAsync.value!;
      }
    }

    return AvoContext(
      lists: lists,
      currentListItems: currentItems,
      currentListId: lists.isNotEmpty ? lists.first.id : null,
      recentRecipes: recipes,
      recentHistoryItems: historyItems.take(15).toList(),
    );
  }

  Future<void> _processActions(List<AvoAction> actions) async {
    for (final action in actions) {
      switch (action.type) {
        case AvoActionType.addItem:
          if (action.params.length >= 2) {
            final listId = action.params[0];
            final itemName = action.params[1];
            final quantity = action.params.length > 2 ? double.tryParse(action.params[2]) ?? 1 : 1.0;
            final unit = action.params.length > 3 ? action.params[3] : null;
            
            try {
              await ref.read(itemsNotifierProvider(listId).notifier).addItem(
                name: itemName,
                quantity: quantity,
                unit: unit,
              );
              HapticFeedback.mediumImpact();
            } catch (e) {
              print('❌ [AVO_CHAT] Error adding item: $e');
            }
          }
          break;
          
        case AvoActionType.searchRecipes:
          if (action.params.isNotEmpty) {
            final query = action.params[0];
            final recipes = await RecipeService.instance.searchRecipes(query);
            if (recipes.isNotEmpty && mounted) {
              _showRecipeResults(recipes);
            }
          }
          break;
          
        case AvoActionType.showRecipe:
          if (action.params.isNotEmpty && mounted) {
            final recipeId = action.params[0];
            context.push('/recipes/$recipeId');
          }
          break;
          
        case AvoActionType.navigate:
          if (action.params.isNotEmpty && mounted) {
            final route = action.params[0];
            context.push(route);
          }
          break;
          
        default:
          break;
      }
    }
  }

  void _showRecipeResults(List<Recipe> recipes) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RecipeResultsSheet(recipes: recipes),
    );
  }

  void _showQuickActions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.black.withValues(alpha: 0.8)
                  : Colors.white.withValues(alpha: 0.9),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 16),
                _buildQuickActionButton(
                  icon: Icons.add_shopping_cart_rounded,
                  label: 'Add item to list',
                  onTap: () {
                    Navigator.pop(context);
                    _messageController.text = 'Add ';
                    _focusNode.requestFocus();
                  },
                ),
                _buildQuickActionButton(
                  icon: Icons.restaurant_menu_rounded,
                  label: 'Find recipes',
                  onTap: () {
                    Navigator.pop(context);
                    _messageController.text = 'Find recipes for ';
                    _focusNode.requestFocus();
                  },
                ),
                _buildQuickActionButton(
                  icon: Icons.lightbulb_outline_rounded,
                  label: 'What\'s missing?',
                  onTap: () {
                    Navigator.pop(context);
                    _sendQuickMessage("What do you think is missing from my shopping list?");
                  },
                ),
                _buildQuickActionButton(
                  icon: Icons.tips_and_updates_rounded,
                  label: 'Suggest dinner',
                  onTap: () {
                    Navigator.pop(context);
                    _sendQuickMessage("What should I cook for dinner tonight?");
                  },
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: LiquidGlassButton(
        text: label,
        icon: icon,
        onPressed: onTap,
        isPrimary: false,
        height: 52,
      ),
    );
  }

  void _sendQuickMessage(String message) {
    _messageController.text = message;
    _sendMessage();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            const AvoMascot(size: 36, expression: AvoExpression.happy),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Avo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                Text(
                  _isTyping ? 'typing...' : 'Your shopping buddy',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          LiquidGlassIconButton(
            icon: Icons.refresh_rounded,
            size: 40,
            onPressed: () {
              HapticFeedback.mediumImpact();
              AvoAssistantService.instance.resetChat();
              setState(() {
                _messages.clear();
                _messages.add(ChatMessage(
                  text: "Fresh start! 🥑 What would you like help with?",
                  isUser: false,
                  avoExpression: AvoExpressionType.waving,
                ));
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isTyping && index == _messages.length) {
                        return _buildTypingIndicator();
                      }
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
          ),

          // Input area
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: bottomPadding + 12,
            ),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.black.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.8),
              border: Border(
                top: BorderSide(
                  color: isDark 
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                ),
              ),
            ),
            child: Row(
              children: [
                // Quick actions button
                LiquidGlassIconButton(
                  icon: Icons.add_rounded,
                  size: 44,
                  onPressed: _showQuickActions,
                ),
                const SizedBox(width: 12),
                // Text input
                Expanded(
                  child: LiquidGlassTextField(
                    controller: _messageController,
                    focusNode: _focusNode,
                    hintText: context.tr('ask_avo_anything'),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                // Send button
                LiquidGlassIconButton(
                  icon: Icons.send_rounded,
                  size: 44,
                  iconColor: _messageController.text.isNotEmpty 
                      ? AppColors.accentColor(context)
                      : null,
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AvoMascot(
            size: 120,
            expression: AvoExpression.waving,
          ),
          const SizedBox(height: 24),
          Text(
            'Chat with Avo!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'I can help you manage lists, find recipes, and plan your shopping!',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.accentColor(context),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(
            message.text,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white,
              height: 1.4,
            ),
          ),
        ),
      );
    }

    // Avo's message
    final expression = _mapExpressionType(message.avoExpression ?? AvoExpressionType.happy);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AvoMascot(size: 36, expression: expression),
          const SizedBox(width: 8),
          Flexible(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: 0.06),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(18),
                    ),
                    border: Border.all(
                      color: isDark 
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textPrimary(context),
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const AvoMascot(size: 36, expression: AvoExpression.thinking),
          const SizedBox(width: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark 
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(milliseconds: 600 + (index * 200)),
                      builder: (context, value, child) {
                        return Container(
                          margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.textSecondary(context)
                                .withValues(alpha: 0.3 + (value * 0.4)),
                            shape: BoxShape.circle,
                          ),
                        );
                      },
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  AvoExpression _mapExpressionType(AvoExpressionType type) {
    switch (type) {
      case AvoExpressionType.happy:
        return AvoExpression.happy;
      case AvoExpressionType.excited:
        return AvoExpression.excited;
      case AvoExpressionType.thinking:
        return AvoExpression.thinking;
      case AvoExpressionType.confused:
        return AvoExpression.confused;
      case AvoExpressionType.celebrating:
        return AvoExpression.celebrating;
      case AvoExpressionType.waving:
        return AvoExpression.waving;
    }
  }
}

/// Recipe results sheet
class _RecipeResultsSheet extends StatelessWidget {
  final List<Recipe> recipes;

  const _RecipeResultsSheet({required this.recipes});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: isDark 
                ? Colors.black.withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.textTertiary(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const AvoMascot(size: 32, expression: AvoExpression.excited),
                    const SizedBox(width: 12),
                    Text(
                      'Found ${recipes.length} recipes!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: recipes.length,
                  itemBuilder: (context, index) {
                    final recipe = recipes[index];
                    return _buildRecipeCard(context, recipe);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeCard(BuildContext context, Recipe recipe) {
    return LiquidGlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () {
        Navigator.pop(context);
        context.push('/recipes/${recipe.id}');
      },
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: recipe.imageUrl != null
                ? Image.network(
                    recipe.imageUrl!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholder(),
                  )
                : _buildPlaceholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: AppColors.textSecondary(context),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${recipe.totalTimeMinutes} min',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                    if (recipe.averageRating > 0) ...[
                      const SizedBox(width: 12),
                      Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        recipe.averageRating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textTertiary(context),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.freshGreen.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.restaurant_rounded,
        color: AppColors.freshGreen,
        size: 28,
      ),
    );
  }
}
