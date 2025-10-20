import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shoply/core/constants/app_config.dart';
import 'package:shoply/core/constants/app_dimensions.dart';
import 'package:shoply/core/constants/app_text_styles.dart';
import 'package:shoply/core/localization/localization_helper.dart';
import 'package:shoply/presentation/state/lists_provider.dart';
import 'package:shoply/presentation/widgets/common/empty_state.dart';
import 'package:shoply/presentation/widgets/common/loading_indicator.dart';
import 'package:shoply/presentation/widgets/list/list_card.dart';

class ListsScreen extends ConsumerStatefulWidget {
  const ListsScreen({super.key});

  @override
  ConsumerState<ListsScreen> createState() => _ListsScreenState();
}

enum SortOption {
  itemsDesc('Most Items'),
  itemsAsc('Least Items'),
  nameAsc('A-Z'),
  nameDesc('Z-A');

  final String label;
  const SortOption(this.label);
}

class _ListsScreenState extends ConsumerState<ListsScreen> {
  SortOption _currentSort = SortOption.itemsDesc;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Reload lists when this screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(listsNotifierProvider.notifier).loadLists();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listsAsync = ref.watch(listsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('my_lists'), style: AppTextStyles.h2),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context),
            tooltip: context.tr('search'),
          ),
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort',
            onSelected: (SortOption option) {
              setState(() {
                _currentSort = option;
              });
            },
            itemBuilder: (context) => [
              for (final option in SortOption.values)
                PopupMenuItem(
                  value: option,
                  child: Row(
                    children: [
                      if (_currentSort == option)
                        const Icon(Icons.check, size: 20)
                      else
                        const SizedBox(width: 20),
                      const SizedBox(width: 8),
                      Text(option.label),
                    ],
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.group_add),
            onPressed: () => _showJoinListDialog(context, ref),
            tooltip: context.tr('join_list'),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateListDialog(context, ref),
            tooltip: context.tr('create_list'),
          ),
        ],
      ),
      body: listsAsync.when(
        data: (lists) {
          if (lists.isEmpty) {
            return EmptyState(
              icon: Icons.list_alt,
              title: 'No lists yet',
              subtitle: 'Create your first shopping list',
              actionText: 'Create List',
              onActionPressed: () => _showCreateListDialog(context, ref),
            );
          }

          // Filter lists based on search query
          var filteredLists = lists;
          if (_searchQuery.isNotEmpty) {
            filteredLists = lists.where((list) {
              return list.name.toLowerCase().contains(_searchQuery.toLowerCase());
            }).toList();
          }

          // Show "no results" if search returned nothing
          if (filteredLists.isEmpty && _searchQuery.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No lists found',
                    style: AppTextStyles.h2,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No lists match "$_searchQuery"',
                    style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                    child: Text(context.tr('clear_search')),
                  ),
                ],
              ),
            );
          }

          // Sort lists based on selected option
          final sortedLists = [...filteredLists];
          switch (_currentSort) {
            case SortOption.itemsDesc:
              sortedLists.sort((a, b) => (b.itemCount ?? 0).compareTo(a.itemCount ?? 0));
              break;
            case SortOption.itemsAsc:
              sortedLists.sort((a, b) => (a.itemCount ?? 0).compareTo(b.itemCount ?? 0));
              break;
            case SortOption.nameAsc:
              sortedLists.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
              break;
            case SortOption.nameDesc:
              sortedLists.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
              break;
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(listsNotifierProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(AppDimensions.screenHorizontalPadding),
              itemCount: sortedLists.length,
              itemBuilder: (context, index) {
                final list = sortedLists[index];
                return ListCard(
                  list: list,
                  onTap: () {
                    context.go('/lists/${list.id}?name=${Uri.encodeComponent(list.name)}');
                  },
                  onDelete: () async {
                    final confirm = await _showDeleteConfirmation(context, list.name);
                    if (confirm == true) {
                      await ref
                          .read(listsNotifierProvider.notifier)
                          .deleteList(list.id);
                    }
                  },
                  onShare: () {
                    _showShareOptions(context, ref, list.id);
                  },
                );
              },
            ),
          );
        },
        loading: () => const LoadingIndicator(message: 'Loading lists...'),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(listsNotifierProvider),
                child: Text(context.tr('retry')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('search')),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            labelText: 'Search',
            hintText: 'Enter list name...',
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
          onSubmitted: (value) {
            setState(() {
              _searchQuery = value.trim();
            });
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _searchController.clear();
              });
              Navigator.pop(context);
            },
            child: Text(context.tr('clear')),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _searchQuery = _searchController.text.trim();
              });
              Navigator.pop(context);
            },
            child: Text(context.tr('search')),
          ),
        ],
      ),
    );
  }

  void _showCreateListDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('create_list')),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: context.tr('list_name_label'),
            hintText: context.tr('list_name_hint'),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;

              try {
                await ref
                    .read(listsNotifierProvider.notifier)
                    .createList(controller.text.trim());

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.tr('list_created'))),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: Text(context.tr('create')),
          ),
        ],
      ),
    );
  }

  void _showJoinListDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('join_list')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('enter_share_code_desc')),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'ABC123 or https://...',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              final input = controller.text.trim();
              if (input.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.tr('enter_code_or_link'))),
                );
                return;
              }

              try {
                // Check if input is a link or a code
                final list = input.startsWith('http')
                    ? await ref.read(listsNotifierProvider.notifier).joinListWithLink(input)
                    : await ref.read(listsNotifierProvider.notifier).joinListWithCode(input.toUpperCase());

                if (context.mounted) {
                  Navigator.pop(context);
                  if (list != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${context.tr('joined_list')}: ${list.name}')),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: Text(context.tr('join')),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context, String listName) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('delete')),
        content: Text('${context.tr('delete_list_confirm')} "$listName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );
  }

  void _showShareOptions(BuildContext context, WidgetRef ref, String listId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('share_list')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('generate_share_code_desc')),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  final code = await ref
                      .read(listsNotifierProvider.notifier)
                      .generateShareCode(listId);
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    // Get the share link
                    final shareLink = AppConfig.generateShareLink(code);
                    
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(context.tr('share_list')),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr('share_code_label'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    SelectableText(
                                      code,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.copy, size: 20),
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(text: code));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(context.tr('code_copied'))),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                context.tr('share_link'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: SelectableText(
                                        shareLink,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.copy, size: 20),
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(text: shareLink));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(context.tr('link_copied'))),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                context.tr('code_expires'),
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              const SizedBox(height: 20),
                              Center(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Share.share(
                                      'Join my shopping list!\n\nCode: $code\nLink: $shareLink\n\nOpen the Shoply app and use the code or link to join.',
                                      subject: 'Join my Shoply list',
                                    );
                                  },
                                  icon: const Icon(Icons.share),
                                  label: Text(context.tr('share_via')),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(context.tr('close')),
                          ),
                        ],
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.qr_code),
              label: Text(context.tr('generate_share_code_btn')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel')),
          ),
        ],
      ),
    );
  }
}
