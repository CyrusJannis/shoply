import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';

import 'package:shoply/core/constants/app_colors.dart';
import 'package:shoply/core/constants/app_dimensions.dart';
import 'package:shoply/core/constants/app_text_styles.dart';
import 'package:shoply/core/localization/app_localizations.dart';
import 'package:shoply/core/localization/localization_helper.dart';
import 'package:shoply/data/services/shopping_history_service.dart';
import 'package:shoply/data/services/supabase_service.dart';
import 'package:shoply/data/services/dynamic_tutorial_service.dart';
import 'package:shoply/presentation/screens/history/shopping_history_screen.dart';
import 'package:shoply/presentation/state/last_list_provider.dart';
import 'package:shoply/presentation/state/lists_provider.dart';
import 'package:shoply/presentation/state/items_provider.dart';
import 'package:shoply/core/services/siri_service.dart';
import 'package:shoply/core/utils/category_detector.dart';
import 'package:shoply/presentation/screens/home/widgets/list_card_with_animation.dart';
import 'package:shoply/presentation/screens/home/widgets/greeting_header.dart';
import 'package:shoply/presentation/state/auth_provider.dart';
import 'package:shoply/core/utils/display_name_helper.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _hasAutoOpened = false;
  String? _lastUserId;

  @override
  void initState() {
    super.initState();
    _lastUserId = SupabaseService.instance.currentUser?.id;
    
    // Lade Listen sofort beim Start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(listsNotifierProvider.notifier).loadLists();
      _autoOpenLastList();
      _checkSiriPendingItems();
    });
    
    // Auth-Listener für User-Wechsel
    SupabaseService.instance.client.auth.onAuthStateChange.listen((data) {
      final newUserId = data.session?.user.id;
      if (_lastUserId != newUserId && mounted) {
        setState(() {
          _lastUserId = newUserId;
        });
        
        // Lade Listen neu
        ref.read(listsNotifierProvider.notifier).loadLists();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Prüfe bei jeder Navigation ob sich der User geändert hat
    final currentUserId = SupabaseService.instance.currentUser?.id;
    if (_lastUserId != currentUserId) {
      _lastUserId = currentUserId;
      
      // Lade Listen IMMER neu (auch bei null)
      Future.microtask(() {
        ref.read(listsNotifierProvider.notifier).loadLists();
      });
    }
  }

  @override
  void activate() {
    super.activate();
    // Wird aufgerufen wenn der Screen wieder aktiv wird (z.B. nach Tab-Wechsel)
    // Nur neu laden wenn bereits initialisiert
    if (_lastUserId != null) {
      Future.microtask(() {
        ref.read(listsNotifierProvider.notifier).loadLists();
      });
    }
  }

  Future<void> _checkSiriPendingItems() async {
    try {
      final siriService = SiriService();
      final pendingItems = await siriService.getPendingItems();
      
      if (pendingItems.isEmpty) return;
      
      String? targetListId;
      String? targetListName;
      
      for (final item in pendingItems) {
        final itemName = item['itemName'] as String;
        final listName = item['listName'] as String;
        final quantity = item['quantity'] as double? ?? 1.0;
        
        // Find or create the list
        final listsAsync = ref.read(listsNotifierProvider);
        await listsAsync.whenData((lists) async {
          var targetList = lists.cast<dynamic>().firstWhere(
            (l) => l.name.toLowerCase() == listName.toLowerCase(),
            orElse: () => null,
          );
          
          // Create list if it doesn't exist
          if (targetList == null) {
            await ref.read(listsNotifierProvider.notifier).createList(listName);
            
            // Wait a moment for the list to be created
            await Future.delayed(const Duration(milliseconds: 500));
            
            // Refresh and get the new list
            ref.invalidate(listsNotifierProvider);
            await Future.delayed(const Duration(milliseconds: 300));
            
            final newLists = ref.read(listsNotifierProvider).value;
            if (newLists != null) {
              targetList = newLists.cast<dynamic>().firstWhere(
                (l) => l.name.toLowerCase() == listName.toLowerCase(),
                orElse: () => null,
              );
            }
          }
          
          if (targetList != null) {
            targetListId = targetList.id;
            targetListName = targetList.name;
            
            // Detect category
            final category = await CategoryDetector.detectCategory(itemName);
            
            // Add item to list
            await ref.read(itemsNotifierProvider(targetList.id).notifier).addItem(
              name: itemName,
              quantity: quantity,
              category: category,
            );
          }
        });
      }
      
      // Refresh the lists view
      if (mounted) {
        ref.invalidate(listsNotifierProvider);
        
        // Navigate to the list after a short delay
        if (targetListId != null && targetListName != null) {
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            final listId = targetListId!;
            final listName = targetListName!;
            context.push('/lists/$listId?name=${Uri.encodeComponent(listName)}');
          }
        }
      }
    } catch (e) {
      // Silently handle Siri errors
    }
  }

  Future<void> _autoOpenLastList() async {
    if (_hasAutoOpened) return;
    _hasAutoOpened = true;

    final lastListAsync = ref.read(lastAccessedListProvider);
    final listsAsync = ref.read(listsNotifierProvider);

    lastListAsync.whenData((lastListId) {
      if (lastListId != null && mounted) {
        listsAsync.whenData((lists) {
          final list = lists.cast<dynamic>().firstWhere(
            (l) => l.id == lastListId,
            orElse: () => null,
          );
          if (list != null && mounted) {
            context.push('/lists/$lastListId?name=${Uri.encodeComponent(list.name)}');
          }
        });
      }
    });
  }

  // Add shopping history items to a list
  Future<void> _addHistoryToList(BuildContext context, dynamic historyEntry) async {
    if (historyEntry.items.isEmpty) {
      
      // Show error to user
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Keine Artikel in dieser Historie gefunden. Bitte erstelle einen neuen Einkauf.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
      return;
    }
    
    final listsAsync = ref.read(listsNotifierProvider);
    
    if (!listsAsync.hasValue || listsAsync.value!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).noListsAvailable)),
        );
      }
      return;
    }
    
    final lists = listsAsync.value!;
    
    // Show iOS-style centered dialog
    final selectedListId = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.modalBorderRadius),
        ),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 500),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(AppDimensions.modalBorderRadius),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      AppLocalizations.of(context).selectList,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context).addItemsCount(historyEntry.totalItems),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Lists
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: lists.length,
                  itemBuilder: (context, index) {
                    final list = lists[index];
                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accentColor(context).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
                        ),
                        child: Icon(Icons.shopping_cart, color: AppColors.accentColor(context)),
                      ),
                      title: Text(
                        list.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: () => Navigator.pop(context, list.id),
                    );
                  },
                ),
              ),
              // Cancel button
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.grey.shade200,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Abbrechen',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    
    if (selectedListId == null) return;
    
    // Add items to the selected list
    try {
      int successCount = 0;
      int failCount = 0;
      
      for (final item in historyEntry.items) {
        try {
          await ref.read(itemsNotifierProvider(selectedListId).notifier).addItem(
            name: item.name,
            quantity: item.quantity,
            unit: item.unit,
            category: item.category,
          );
          successCount++;
        } catch (itemError) {
          failCount++;
        }
      }
      
      // Refresh the items provider to update the UI
      ref.invalidate(itemsNotifierProvider(selectedListId));
      
      // Also refresh the lists provider to update item counts
      ref.invalidate(listsNotifierProvider);
      
      if (mounted) {
        final message = failCount > 0
            ? '✅ $successCount Artikel hinzugefügt, $failCount fehlgeschlagen'
            : '✅ $successCount Artikel zur Liste hinzugefügt';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: failCount > 0 ? Colors.orange : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Native iOS-style refresh indicator with smooth animation
  Widget _buildRefreshIndicator(
    BuildContext context,
    RefreshIndicatorMode refreshState,
    double percentageComplete,
    double pulledExtent,
  ) {
    const Curve opacityCurve = Interval(0.4, 1.0, curve: Curves.easeInOut);
    
    return Opacity(
      opacity: opacityCurve.transform(percentageComplete),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: () {
          switch (refreshState) {
            case RefreshIndicatorMode.drag:
              // Beim Ziehen: Zeige Fortschritt
              return CupertinoActivityIndicator.partiallyRevealed(
                progress: percentageComplete,
              );
            case RefreshIndicatorMode.armed:
            case RefreshIndicatorMode.refresh:
              // Beim Laden: Voller Spinner
              return const CupertinoActivityIndicator();
            case RefreshIndicatorMode.done:
              // Fertig: Spinner mit Fade-out
              return const CupertinoActivityIndicator();
            default:
              return const SizedBox.shrink();
          }
        }(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listsAsync = ref.watch(listsNotifierProvider);
    final userData = ref.watch(currentUserProvider).value;
    final displayName = DisplayNameHelper.getDisplayName(userData?.displayName);
    final avatarUrl = userData?.avatarUrl;

    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollStartNotification) {
            FocusScope.of(context).unfocus();
          }
          return false;
        },
        child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // Native iOS Pull-to-Refresh - MUSS erstes Sliver sein!
          CupertinoSliverRefreshControl(
            refreshTriggerPullDistance: 100.0,
            refreshIndicatorExtent: 60.0,
            builder: (
              BuildContext context,
              RefreshIndicatorMode refreshState,
              double pulledExtent,
              double refreshTriggerPullDistance,
              double refreshIndicatorExtent,
            ) {
              final double percentageComplete = (pulledExtent / refreshTriggerPullDistance).clamp(0.0, 1.0);
              
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: pulledExtent > 0 ? pulledExtent - 40 : 0,
                    child: Center(
                      child: _buildRefreshIndicator(
                        context,
                        refreshState,
                        percentageComplete,
                        pulledExtent,
                      ),
                    ),
                  ),
                ],
              );
            },
            onRefresh: () async {
              ref.invalidate(listsNotifierProvider);
              await Future.delayed(const Duration(milliseconds: 800));
            },
          ),
          // Safe Area nach dem Refresh Control
          SliverSafeArea(
            top: true,
            bottom: false,
            sliver: const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),
          // Collapsing Header (Hallo + Avatar)
          SliverPersistentHeader(
              delegate: GreetingHeader(
                displayName: displayName,
                avatarUrl: avatarUrl,
                onAvatarTap: () => context.go('/profile'),
              ),
              pinned: false,
              floating: false,
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: AppDimensions.spacingMedium),
            ),

            // Listen-Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.screenHorizontalPadding,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.tr('your_lists'),
                      style: AppTextStyles.h2.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 26,
                      ),
                    ),
                    AdaptivePopupMenuButton.text<String>(
                      label: '+ ${context.tr('new')}',
                      buttonStyle: PopupButtonStyle.glass,
                      items: [
                        AdaptivePopupMenuItem(
                          label: context.tr('create_new_list'),
                          icon: PlatformInfo.isIOS26OrHigher() ? 'plus.circle.fill' : Icons.add_circle,
                          value: 'new',
                        ),
                        AdaptivePopupMenuItem(
                          label: context.tr('join_list'),
                          icon: PlatformInfo.isIOS26OrHigher() ? 'person.2.fill' : Icons.group_add,
                          value: 'join',
                        ),
                      ],
                      onSelected: (index, item) {
                        if (item.value == 'new') {
                          _showCreateListDialog(context, ref);
                        } else if (item.value == 'join') {
                          _showJoinListDialog(context, ref);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: AppDimensions.spacingMedium),
            ),

            // Horizontale Listen
            SliverToBoxAdapter(
              child: listsAsync.when(
                data: (lists) {
                  final tutorial = DynamicTutorialService.instance;
                  
                  if (lists.isEmpty) {
                    // If tutorial is active and no lists, auto-create one
                    if (tutorial.isActive && tutorial.currentStepId == TutorialStepId.openShoppingList) {
                      WidgetsBinding.instance.addPostFrameCallback((_) async {
                        try {
                          await ref.read(listsNotifierProvider.notifier).createList('Meine erste Liste');
                        } catch (e) {
                          debugPrint('Error creating tutorial list: $e');
                        }
                      });
                    }
                    
                    // Update tutorial that there are no lists
                    tutorial.updateListsData(hasLists: false, firstListId: null);
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.screenHorizontalPadding,
                      ),
                      child: Container(
                        height: 140,
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
                        ),
                        child: Center(
                          child: Text(
                            'Noch keine Listen erstellt',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.lightTextSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  final sortedLists = [...lists]..sort((a, b) =>
                      b.updatedAt.compareTo(a.updatedAt));

                  return SizedBox(
                    height: 140 * 1.75,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.screenHorizontalPadding,
                      ),
                      itemCount: sortedLists.length,
                      itemBuilder: (context, index) {
                        final list = sortedLists[index];
                        final tutorial = DynamicTutorialService.instance;
                        final isFirstList = index == 0;
                        
                        // Update tutorial with user data
                        if (isFirstList) {
                          tutorial.updateListsData(hasLists: true, firstListId: list.id);
                        }
                        
                        return _buildListCard(
                          context,
                          ref,
                          list.id,
                          list.name,
                          list.itemCount ?? 0,
                          list.getBackgroundType(),
                          list.getBackgroundValue(),
                          list.backgroundImageUrl,
                          list.updatedAt,
                          () {
                            context.push('/lists/${list.id}?name=${Uri.encodeComponent(list.name)}');
                            // Complete tutorial step if this is the first list
                            if (isFirstList && tutorial.isActive && 
                                tutorial.currentStepId == TutorialStepId.openShoppingList) {
                              tutorial.completeCurrentStep();
                            }
                          },
                          tutorialKey: isFirstList ? tutorial.firstListCardKey : null,
                        );
                      },
                    ),
                  );
                },
                loading: () => const SizedBox(
                  height: 140,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.screenHorizontalPadding,
                  ),
                  child: Container(
                    height: 140,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
                    ),
                    child: const Center(child: Text('Fehler beim Laden')),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: AppDimensions.spacingLarge),
            ),

            // Einkaufshistorie
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.screenHorizontalPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              context.tr('shopping_history'),
                              style: AppTextStyles.h2.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 26,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ShoppingHistoryScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                context.tr('see_all'),
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: const Color(0xFF8E8E93),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      FutureBuilder(
                        future: ShoppingHistoryService().getRecentHistory(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.all(AppDimensions.cardPadding),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          if (snapshot.hasError) {
                            return Padding(
                              padding: const EdgeInsets.all(AppDimensions.cardPadding),
                              child: Text(
                                context.tr('loading_error'),
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.lightTextSecondary,
                                ),
                              ),
                            );
                          }

                          final history = snapshot.data ?? [];

                          if (history.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(AppDimensions.cardPadding),
                              child: Text(
                                context.tr('no_shopping_history'),
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.lightTextSecondary,
                                ),
                              ),
                            );
                          }

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(
                              AppDimensions.cardPadding,
                              AppDimensions.cardPadding,
                              AppDimensions.cardPadding,
                              AppDimensions.cardPadding + 20, // Extra bottom padding
                            ),
                            itemCount: history.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final trip = history[index];
                              final cardColor = AppColors.surface(context);
                              final textPrimary = AppColors.textPrimary(context);
                              final textSecondary = AppColors.textSecondary(context);
                              final borderColor = AppColors.border(context);

                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(50), // Perfect pill shape
                                  border: Border.all(
                                    color: borderColor,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Content
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              trip.listName,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                color: textPrimary,
                                                fontSize: 15,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${trip.totalItems} ${context.tr('items')}',
                                            style: TextStyle(
                                              color: textSecondary,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Add button - pill style
                                    GestureDetector(
                                      onTap: () => _addHistoryToList(context, trip),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: AppColors.accentColor(context),
                                          borderRadius: BorderRadius.circular(50), // Perfect pill
                                        ),
                                        child: Text(
                                          context.tr('add_button'),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: AppDimensions.spacingXLarge),
            ),

            // Extra Bottom Padding für Navigation Bar + Safe Area
            // Safe Area am Ende
            SliverSafeArea(
              top: false,
              bottom: true,
              sliver: SliverPadding(
                padding: const EdgeInsets.only(bottom: 200),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateListDialog(BuildContext context, WidgetRef ref) async {
    final result = await AdaptiveAlertDialog.inputShow(
      context: context,
      title: context.tr('create_new_list'),
      message: context.tr('enter_list_name_prompt'),
      icon: PlatformInfo.isIOS26OrHigher() ? 'list.bullet.circle.fill' : Icons.list_alt,
      input: AdaptiveAlertDialogInput(
        placeholder: context.tr('enter_list_name'),
        initialValue: '',
        keyboardType: TextInputType.text,
      ),
      actions: [
        AlertAction(
          title: context.tr('cancel'),
          style: AlertActionStyle.cancel,
          onPressed: () {},
        ),
        AlertAction(
          title: context.tr('create'),
          style: AlertActionStyle.primary,
          onPressed: () {},
        ),
      ],
    );

    if (result != null && result.trim().isNotEmpty) {
      try {
        await ref
            .read(listsNotifierProvider.notifier)
            .createList(result.trim());

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('list_created'))),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${context.tr('error')}: $e')),
          );
        }
      }
    }
  }

  void _showJoinListDialog(BuildContext context, WidgetRef ref) async {
    final result = await AdaptiveAlertDialog.inputShow(
      context: context,
      title: context.tr('join_list'),
      message: context.tr('enter_share_code'),
      icon: PlatformInfo.isIOS26OrHigher() ? 'person.2.fill' : Icons.group,
      input: AdaptiveAlertDialogInput(
        placeholder: context.tr('share_code'),
        initialValue: '',
        keyboardType: TextInputType.text,
      ),
      actions: [
        AlertAction(
          title: context.tr('cancel'),
          style: AlertActionStyle.cancel,
          onPressed: () {},
        ),
        AlertAction(
          title: context.tr('join'),
          style: AlertActionStyle.primary,
          onPressed: () {},
        ),
      ],
    );

    if (result != null && result.trim().isNotEmpty) {
      final shareCode = result.trim().toUpperCase();
      
      try {
        final list = await ref
            .read(listsNotifierProvider.notifier)
            .joinListWithCode(shareCode);
        
        if (!context.mounted) return;
        
        if (list != null) {
          AdaptiveAlertDialog.show(
            context: context,
            title: context.tr('joined_successfully'),
            message: context.tr('joined_list_message', params: {'listName': list.name}),
            icon: PlatformInfo.isIOS26OrHigher() ? 'checkmark.circle.fill' : Icons.check_circle,
            iconColor: Colors.green,
            actions: [
              AlertAction(
                title: context.tr('ok'),
                style: AlertActionStyle.primary,
                onPressed: () {},
              ),
            ],
          );
        } else {
          AdaptiveAlertDialog.show(
            context: context,
            title: context.tr('error'),
            message: context.tr('invalid_share_code'),
            icon: PlatformInfo.isIOS26OrHigher() ? 'xmark.circle.fill' : Icons.error,
            iconColor: Colors.red,
            actions: [
              AlertAction(
                title: context.tr('ok'),
                style: AlertActionStyle.cancel,
                onPressed: () {},
              ),
            ],
          );
        }
      } catch (e) {
        if (!context.mounted) return;
        
        AdaptiveAlertDialog.show(
          context: context,
          title: context.tr('error'),
          message: '${context.tr('join_error')}: $e',
          icon: PlatformInfo.isIOS26OrHigher() ? 'exclamationmark.triangle.fill' : Icons.warning,
          iconColor: Colors.orange,
          actions: [
            AlertAction(
              title: context.tr('ok'),
              style: AlertActionStyle.cancel,
              onPressed: () {},
            ),
          ],
        );
      }
    }
  }

  // removed custom glass dialog helper in favor of AdaptiveAlertDialog.inputShow

  Future<bool?> _showDeleteConfirmation(BuildContext context, String listName, WidgetRef ref) async {
    final localizations = AppLocalizations.of(context);
    final completer = Completer<bool?>();
    
    AdaptiveAlertDialog.show(
      context: context,
      title: localizations.deleteListTitle,
      message: localizations.deleteListMessage(listName),
      icon: PlatformInfo.isIOS26OrHigher() ? 'trash.fill' : Icons.delete,
      iconSize: 48,
      iconColor: Colors.red,
      actions: [
        AlertAction(
          title: localizations.cancel,
          onPressed: () {
            if (!completer.isCompleted) {
              completer.complete(false);
            }
          },
          style: AlertActionStyle.cancel,
        ),
        AlertAction(
          title: localizations.deleteConfirm,
          onPressed: () {
            if (!completer.isCompleted) {
              completer.complete(true);
            }
          },
          style: AlertActionStyle.destructive,
        ),
      ],
    );
    
    return completer.future;
  }

  Widget _buildListCard(
    BuildContext context,
    WidgetRef ref,
    String listId,
    String name,
    int itemCount,
    String backgroundType,
    String? backgroundValue,
    String? backgroundImageUrl,
    DateTime? updatedAt,
    VoidCallback onTap, {
    GlobalKey? tutorialKey,
  }) {
    return ListCardWithAnimation(
      tutorialKey: tutorialKey,
      listId: listId,
      name: name,
      itemCount: itemCount,
      backgroundType: backgroundType,
      backgroundValue: backgroundValue,
      backgroundImageUrl: backgroundImageUrl,
      updatedAt: updatedAt,
      onTap: onTap,
      onLongPress: () async {
        // 🎯 Haptisches Feedback
        HapticFeedback.mediumImpact();
        
        // Zeige AdaptiveAlertDialog
        final shouldDelete = await _showDeleteConfirmation(context, name, ref);
        
        if (shouldDelete == true) {
          ref.read(listsNotifierProvider.notifier).deleteList(listId);
        }
      },
    );
  }
}
