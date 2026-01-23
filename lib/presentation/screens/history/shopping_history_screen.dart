import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shoply/core/constants/app_colors.dart';
import 'package:shoply/core/constants/app_text_styles.dart';
import 'package:shoply/data/models/shopping_history.dart';
import 'package:shoply/data/models/shopping_list_model.dart';
import 'package:shoply/core/localization/localization_helper.dart';
import 'package:shoply/presentation/state/lists_provider.dart';
import 'package:shoply/presentation/state/items_provider.dart';
import 'package:shoply/presentation/state/shopping_history_provider.dart';

class ShoppingHistoryScreen extends ConsumerStatefulWidget {
  const ShoppingHistoryScreen({super.key});

  @override
  ConsumerState<ShoppingHistoryScreen> createState() => _ShoppingHistoryScreenState();
}

class _ShoppingHistoryScreenState extends ConsumerState<ShoppingHistoryScreen> {
  final Set<String> _expandedEntries = {};

  @override
  void initState() {
    super.initState();
    // Refresh history when screen opens
    Future.microtask(() {
      ref.read(shoppingHistoryNotifierProvider.notifier).refresh();
    });
  }

  String _getDateGroupLabel(DateTime date, BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final entryDate = DateTime(date.year, date.month, date.day);

    if (entryDate == today) {
      return context.tr('today');
    } else if (entryDate == yesterday) {
      return context.tr('yesterday');
    } else if (now.difference(date).inDays < 7) {
      return context.tr('this_week');
    } else if (now.month == date.month && now.year == date.year) {
      return context.tr('this_month');
    } else {
      return DateFormat('MMMM yyyy', Localizations.localeOf(context).languageCode).format(date);
    }
  }

  Map<String, List<ShoppingHistory>> _groupHistoryByDate(List<ShoppingHistory> history) {
    final grouped = <String, List<ShoppingHistory>>{};
    for (final entry in history) {
      final label = _getDateGroupLabel(entry.completedAt, context);
      grouped.putIfAbsent(label, () => []).add(entry);
    }
    return grouped;
  }

  Future<void> _deleteEntry(String id) async {
    HapticFeedback.mediumImpact();
    await ref.read(shoppingHistoryNotifierProvider.notifier).deleteHistory(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('entry_deleted')),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _addAllItemsToList(List<ShoppingHistoryItem> items, String listId, String listName) async {
    try {
      // Batch add all items in parallel for better performance
      await Future.wait(
        items.map((item) => ref.read(itemsNotifierProvider(listId).notifier).addItem(
          name: item.name,
          quantity: item.quantity,
          unit: item.unit,
          category: item.category,
        )),
      );
      HapticFeedback.mediumImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${items.length} ${context.tr('items_added_to')} $listName'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('error')}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(shoppingHistoryNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 100,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.background(context),
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary(context),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
              title: Text(
                context.tr('shopping_history'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(context),
                ),
              ),
            ),
            actions: [
              if (historyAsync.hasValue && historyAsync.value!.isNotEmpty)
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    color: AppColors.textPrimary(context),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: AppColors.surface(context),
                  onSelected: (value) async {
                    if (value == 'clear_all') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: AppColors.surface(context),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: Text(
                            context.tr('clear_history'),
                            style: TextStyle(color: AppColors.textPrimary(context)),
                          ),
                          content: Text(
                            context.tr('clear_history_confirm'),
                            style: TextStyle(color: AppColors.textSecondary(context)),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(context.tr('cancel')),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.error,
                              ),
                              child: Text(context.tr('clear')),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await ref.read(shoppingHistoryNotifierProvider.notifier).clearAllHistory();
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'clear_all',
                      child: Row(
                        children: [
                          Icon(Icons.delete_sweep_rounded, color: AppColors.error, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            context.tr('clear_history'),
                            style: TextStyle(color: AppColors.error),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              const SizedBox(width: 8),
            ],
          ),

          // Content
          historyAsync.when(
            loading: () => SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.accentColor(context),
                ),
              ),
            ),
            error: (error, _) => SliverFillRemaining(
              child: _buildErrorState(error.toString(), isDark),
            ),
            data: (history) {
              if (history.isEmpty) {
                return SliverFillRemaining(
                  child: _buildEmptyState(isDark),
                );
              }

              final grouped = _groupHistoryByDate(history);
              final groupKeys = grouped.keys.toList();

              return SliverPadding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).padding.bottom + 100,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final groupKey = groupKeys[index];
                      final entries = grouped[groupKey]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date group header
                          Padding(
                            padding: const EdgeInsets.only(top: 16, bottom: 12),
                            child: Text(
                              groupKey,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary(context),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          // Entries in this group
                          ...entries.map((entry) => _buildHistoryCard(entry, isDark)),
                        ],
                      );
                    },
                    childCount: groupKeys.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.accentColor(context).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                size: 56,
                color: AppColors.accentColor(context),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              context.tr('no_shopping_trips'),
              style: AppTextStyles.h2.copyWith(
                color: AppColors.textPrimary(context),
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              context.tr('completed_trips_appear_here'),
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary(context),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.tr('loading_error'),
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(shoppingHistoryNotifierProvider.notifier).refresh();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.tr('retry')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentColor(context),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime date, BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final entryDate = DateTime(date.year, date.month, date.day);
    
    final timeStr = DateFormat('HH:mm').format(date);
    
    if (entryDate == today) {
      return '${context.tr('today')}, $timeStr';
    } else if (entryDate == yesterday) {
      return '${context.tr('yesterday')}, $timeStr';
    } else if (now.difference(date).inDays < 7) {
      final dayName = DateFormat('EEEE', locale).format(date);
      return '$dayName, $timeStr';
    } else {
      return DateFormat('EEE, d. MMM', locale).format(date);
    }
  }

  Widget _buildHistoryCard(ShoppingHistory entry, bool isDark) {
    final isExpanded = _expandedEntries.contains(entry.id);
    final listsAsync = ref.watch(listsNotifierProvider);
    final lists = listsAsync.hasValue ? listsAsync.value! : <ShoppingListModel>[];

    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surface(context),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              context.tr('delete_entry'),
              style: TextStyle(color: AppColors.textPrimary(context)),
            ),
            content: Text(
              context.tr('delete_entry_confirm'),
              style: TextStyle(color: AppColors.textSecondary(context)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(context.tr('cancel')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: Text(context.tr('delete')),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) => _deleteEntry(entry.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isExpanded
                ? AppColors.accentColor(context).withValues(alpha: 0.3)
                : AppColors.border(context),
            width: isExpanded ? 1.5 : 1,
          ),
          boxShadow: isExpanded
              ? [
                  BoxShadow(
                    color: AppColors.accentColor(context).withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            // Main card content
            InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  if (isExpanded) {
                    _expandedEntries.remove(entry.id);
                  } else {
                    _expandedEntries.add(entry.id);
                  }
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Icon with gradient background
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.accentColor(context),
                            AppColors.accentColor(context).withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.shopping_bag_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.listName,
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
                                Icons.schedule_rounded,
                                size: 14,
                                color: AppColors.textTertiary(context),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  _formatDateTime(entry.completedAt, context),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary(context),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (entry.completedByName != null) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.person_outline_rounded,
                                  size: 14,
                                  color: AppColors.textTertiary(context),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    entry.completedByName!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary(context),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Item count badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accentColor(context).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${entry.totalItems}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentColor(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textTertiary(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Expanded items section
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: _buildExpandedContent(entry, lists),
              crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent(ShoppingHistory entry, List<ShoppingListModel> lists) {
    return _ExpandedItemsContent(
      entry: entry,
      lists: lists,
      onAddAllItems: _addAllItemsToList,
    );
  }
}

/// Stateful widget for expanded items with individual add functionality
class _ExpandedItemsContent extends ConsumerStatefulWidget {
  final ShoppingHistory entry;
  final List<ShoppingListModel> lists;
  final Future<void> Function(List<ShoppingHistoryItem> items, String listId, String listName) onAddAllItems;

  const _ExpandedItemsContent({
    required this.entry,
    required this.lists,
    required this.onAddAllItems,
  });

  @override
  ConsumerState<_ExpandedItemsContent> createState() => _ExpandedItemsContentState();
}

class _ExpandedItemsContentState extends ConsumerState<_ExpandedItemsContent> {
  String? _selectedListId;
  final Set<String> _addedItemIds = {};
  bool _isAddingAll = false;

  @override
  void initState() {
    super.initState();
    if (widget.lists.isNotEmpty) {
      _selectedListId = widget.lists.first.id;
    }
  }

  Future<void> _addSingleItem(ShoppingHistoryItem item) async {
    if (_selectedListId == null) return;
    
    try {
      await ref.read(itemsNotifierProvider(_selectedListId!).notifier).addItem(
        name: item.name,
        quantity: item.quantity,
        unit: item.unit,
        category: item.category,
      );
      HapticFeedback.lightImpact();
      setState(() {
        _addedItemIds.add(item.id);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('error')}: $e')),
        );
      }
    }
  }

  Future<void> _addAllItems() async {
    if (_selectedListId == null) return;
    
    setState(() => _isAddingAll = true);
    
    final selectedList = widget.lists.firstWhere((l) => l.id == _selectedListId);
    await widget.onAddAllItems(widget.entry.items, _selectedListId!, selectedList.name);
    
    setState(() {
      _isAddingAll = false;
      for (final item in widget.entry.items) {
        _addedItemIds.add(item.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Divider(
          color: AppColors.divider(context),
          height: 1,
        ),
        
        // List selector and add all button
        if (widget.lists.isNotEmpty && widget.entry.items.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                // List selector dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedListId,
                      isExpanded: true,
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary(context),
                      ),
                      dropdownColor: AppColors.surface(context),
                      borderRadius: BorderRadius.circular(12),
                      items: widget.lists.map((list) {
                        return DropdownMenuItem<String>(
                          value: list.id,
                          child: Row(
                            children: [
                              Icon(
                                Icons.list_rounded,
                                size: 18,
                                color: AppColors.accentColor(context),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  list.name,
                                  style: TextStyle(
                                    color: AppColors.textPrimary(context),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedListId = value;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Add all button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _selectedListId == null || _isAddingAll
                        ? null
                        : _addAllItems,
                    icon: _isAddingAll
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add_shopping_cart_rounded, size: 18),
                    label: Text(
                      '${context.tr('add_all')} (${widget.entry.items.length})',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentColor(context),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        
        // Items list with individual add buttons
        if (widget.entry.items.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: widget.entry.items.take(15).map((item) {
                final isAdded = _addedItemIds.contains(item.id);
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isAdded 
                          ? AppColors.success.withValues(alpha: 0.08)
                          : AppColors.background(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isAdded 
                            ? AppColors.success.withValues(alpha: 0.3)
                            : AppColors.border(context),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Item icon
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isAdded
                                ? AppColors.success.withValues(alpha: 0.15)
                                : AppColors.accentColor(context).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isAdded ? Icons.check_rounded : Icons.shopping_basket_outlined,
                            size: 16,
                            color: isAdded ? AppColors.success : AppColors.accentColor(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Item name and quantity
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary(context),
                                ),
                              ),
                              if (item.quantity > 1 || item.unit != null)
                                Text(
                                  '${item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 1)}${item.unit != null ? ' ${item.unit}' : ''}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary(context),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Add button
                        if (widget.lists.isNotEmpty && _selectedListId != null)
                          GestureDetector(
                            onTap: isAdded ? null : () => _addSingleItem(item),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isAdded
                                    ? AppColors.success
                                    : AppColors.accentColor(context),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isAdded ? Icons.check_rounded : Icons.add_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        
        // Show more items indicator
        if (widget.entry.items.length > 15)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              '+${widget.entry.items.length - 15} ${context.tr('more_items')}',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textTertiary(context),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        
        // Empty state
        if (widget.entry.items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              context.tr('no_items'),
              style: TextStyle(
                color: AppColors.textSecondary(context),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}
