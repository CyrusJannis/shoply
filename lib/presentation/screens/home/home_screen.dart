import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:intl/intl.dart';

import 'package:shoply/core/constants/app_colors.dart';
import 'package:shoply/core/constants/app_dimensions.dart';
import 'package:shoply/core/constants/app_text_styles.dart';
import 'package:shoply/core/localization/app_localizations.dart';
import 'package:shoply/core/localization/localization_helper.dart';
import 'package:shoply/data/models/shopping_history.dart';
import 'package:shoply/presentation/state/shopping_history_provider.dart';
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

            // Einkaufshistorie - Matching full page design
            SliverToBoxAdapter(
              child: const _ShoppingHistorySection(),
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

/// Shopping history section matching the full page design - limited to 3 entries
class _ShoppingHistorySection extends ConsumerStatefulWidget {
  const _ShoppingHistorySection();

  @override
  ConsumerState<_ShoppingHistorySection> createState() => _ShoppingHistorySectionState();
}

class _ShoppingHistorySectionState extends ConsumerState<_ShoppingHistorySection> {
  final Set<String> _expandedEntries = {};

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

  Future<void> _addAllItemsToList(List<ShoppingHistoryItem> items, String listId, String listName) async {
    try {
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
    final historyAsync = ref.watch(recentHistoryProvider);
    final listsAsync = ref.watch(listsNotifierProvider);
    final lists = listsAsync.hasValue ? listsAsync.value! : [];

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.screenHorizontalPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          historyAsync.when(
            loading: () => const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.textTertiary(context),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    context.tr('loading_error'),
                    style: TextStyle(color: AppColors.textSecondary(context)),
                  ),
                ],
              ),
            ),
            data: (history) {
              if (history.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.accentColor(context).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.receipt_long_rounded,
                          color: AppColors.accentColor(context),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('no_shopping_history'),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary(context),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              context.tr('completed_trips_appear_here'),
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Vertical list matching full page design - limited to 3 entries
              final limitedHistory = history.take(3).toList();
              return Column(
                children: limitedHistory.map((entry) => 
                  _buildHistoryCard(entry, lists)
                ).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(ShoppingHistory entry, List<dynamic> lists) {
    final isExpanded = _expandedEntries.contains(entry.id);

    return AnimatedContainer(
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
            secondChild: _HomeExpandedItemsContent(
              entry: entry,
              lists: lists,
              onAddAllItems: _addAllItemsToList,
            ),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

/// Expanded items content for homepage history cards
class _HomeExpandedItemsContent extends ConsumerStatefulWidget {
  final ShoppingHistory entry;
  final List<dynamic> lists;
  final Future<void> Function(List<ShoppingHistoryItem> items, String listId, String listName) onAddAllItems;

  const _HomeExpandedItemsContent({
    required this.entry,
    required this.lists,
    required this.onAddAllItems,
  });

  @override
  ConsumerState<_HomeExpandedItemsContent> createState() => _HomeExpandedItemsContentState();
}

class _HomeExpandedItemsContentState extends ConsumerState<_HomeExpandedItemsContent> {
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
              children: widget.entry.items.take(10).map((item) {
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
        if (widget.entry.items.length > 10)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              '+${widget.entry.items.length - 10} ${context.tr('more_items')}',
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
