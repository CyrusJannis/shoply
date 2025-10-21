import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shoply/core/constants/app_colors.dart';
import 'package:shoply/core/constants/app_text_styles.dart';
import 'package:shoply/data/models/shopping_history.dart';
import 'package:shoply/data/services/shopping_history_service.dart';
import 'package:shoply/core/localization/localization_helper.dart';
import 'package:shoply/presentation/state/lists_provider.dart';
import 'package:shoply/presentation/state/items_provider.dart';

class ShoppingHistoryScreen extends ConsumerStatefulWidget {
  const ShoppingHistoryScreen({super.key});

  @override
  ConsumerState<ShoppingHistoryScreen> createState() => _ShoppingHistoryScreenState();
}

class _ShoppingHistoryScreenState extends ConsumerState<ShoppingHistoryScreen> {
  final _historyService = ShoppingHistoryService();
  List<ShoppingHistory> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final history = await _historyService.getShoppingHistory();
      setState(() {
        _history = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden: $e')),
        );
      }
    }
  }

  Future<void> _deleteHistory(String id) async {
    try {
      await _historyService.deleteHistory(id);
      _loadHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('entry_deleted'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('error') + ': $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('shopping_history')),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      final entry = _history[index];
                      return _buildHistoryCard(entry);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            context.tr('no_shopping_trips'),
            style: AppTextStyles.h2.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('completed_trips_appear_here'),
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(ShoppingHistory entry) {
    final dateFormat = DateFormat('dd.MM.yyyy, HH:mm');
    
    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _deleteHistory(entry.id),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ExpansionTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.info.withOpacity(0.2),
            child: const Icon(Icons.shopping_cart, color: AppColors.info),
          ),
          title: Text(
            entry.listName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${entry.totalItems} ${context.tr('items')} • ${dateFormat.format(entry.completedAt)}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.add_shopping_cart),
            onPressed: () => _addEntireShoppingTripToList(context, entry),
            tooltip: 'Gesamten Einkauf zur Liste hinzufügen',
          ),
          children: [
            if (entry.items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('purchased_items'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...entry.items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, size: 16, color: AppColors.success),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${item.quantity} ${item.unit ?? ''} ${item.name}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _addEntireShoppingTripToList(BuildContext context, ShoppingHistory entry) async {
    // Get all lists
    final listsAsync = ref.read(listsNotifierProvider);
    
    if (!listsAsync.hasValue || listsAsync.value!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keine Listen verfügbar. Erstelle zuerst eine Liste.')),
      );
      return;
    }
    
    final lists = listsAsync.value!;
    
    // Show list selection dialog
    final selectedList = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Liste auswählen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: lists.map((list) => ListTile(
            title: Text(list.name),
            subtitle: Text('${entry.totalItems} Artikel hinzufügen'),
            onTap: () => Navigator.pop(context, list.id),
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
        ],
      ),
    );
    
    if (selectedList == null) return;
    
    try {
      // Add all items from the shopping trip to the selected list
      for (final item in entry.items) {
        await ref.read(itemsNotifierProvider(selectedList).notifier).addItem(
          name: item.name,
          quantity: item.quantity ?? 1.0,
          unit: item.unit,
          category: item.category,
        );
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${entry.totalItems} Artikel zur Liste hinzugefügt'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    }
  }
}
