// imports bereinigt (Duplikate entfernt)
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
// liquid_glass_renderer not needed when using AdaptiveAlertDialog.inputShow
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';

import 'package:shoply/core/constants/app_colors.dart';
import 'package:shoply/core/constants/app_dimensions.dart';
import 'package:shoply/core/constants/app_text_styles.dart';
import 'package:shoply/core/localization/app_localizations.dart';
import 'package:shoply/data/services/shopping_history_service.dart';
import 'package:shoply/data/services/supabase_service.dart';
import 'package:shoply/presentation/screens/history/shopping_history_screen.dart';
import 'package:shoply/presentation/state/last_list_provider.dart';
import 'package:shoply/presentation/state/lists_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _hasAutoOpened = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoOpenLastList();
    });
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

  @override
  Widget build(BuildContext context) {
    final listsAsync = ref.watch(listsNotifierProvider);
    final user = SupabaseService.instance.currentUser;
    final displayName = user?.userMetadata?['display_name'] ?? 'User';

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Collapsing Header (Hallo + Avatar)
            SliverPersistentHeader(
              delegate: _GreetingHeader(
                displayName: displayName,
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
                      'Deine Listen',
                      style: AppTextStyles.h2.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 26,
                      ),
                    ),
                    AdaptivePopupMenuButton.text<String>(
                      label: '+ Neue Liste',
                      buttonStyle: PopupButtonStyle.glass,
                      items: [
                        AdaptivePopupMenuItem(
                          label: 'Neue Liste',
                          icon: PlatformInfo.isIOS26OrHigher() ? 'plus.circle.fill' : Icons.add_circle,
                          value: 'new',
                        ),
                        AdaptivePopupMenuItem(
                          label: 'Liste beitreten',
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
                  if (lists.isEmpty) {
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
                      (b.itemCount ?? 0).compareTo(a.itemCount ?? 0));

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
                        return Dismissible(
                          key: Key(list.id),
                          direction: DismissDirection.up,
                          confirmDismiss: (direction) async {
                            return await _showDeleteConfirmation(context, list.name, ref);
                          },
                          onDismissed: (direction) {
                            ref.read(listsNotifierProvider.notifier).deleteList(list.id);
                          },
                          child: _buildListCard(
                            context,
                            list.id,
                            list.name,
                            list.itemCount ?? 0,
                            () => context.push('/lists/${list.id}?name=${Uri.encodeComponent(list.name)}'),
                          ),
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
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.lightShadow,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(AppDimensions.cardPadding),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Einkaufshistorie',
                              style: AppTextStyles.h2.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 26,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ShoppingHistoryScreen(),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                              ),
                              child: Text(
                                'See all',
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 17,
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
                                'Fehler beim Laden',
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
                                'Sie waren noch nicht einkaufen',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.lightTextSecondary,
                                ),
                              ),
                            );
                          }

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(AppDimensions.cardPadding),
                            itemCount: history.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final trip = history[index];
                              final date = DateFormat('dd.MM.yyyy').format(trip.completedAt);

                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            trip.listName,
                                            style: AppTextStyles.bodyMedium.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Text(
                                                '${trip.totalItems} Artikel',
                                                style: AppTextStyles.bodySmall.copyWith(
                                                  color: Colors.white70,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                date,
                                                style: AppTextStyles.bodySmall.copyWith(
                                                  color: Colors.white70,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.add,
                                        color: Colors.black,
                                        size: 20,
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
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: AppDimensions.spacingLarge),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 120),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateListDialog(BuildContext context, WidgetRef ref) async {
    final result = await AdaptiveAlertDialog.inputShow(
      context: context,
      title: 'Neue Liste',
      message: 'Gib deiner Liste einen Namen',
      icon: PlatformInfo.isIOS26OrHigher() ? 'list.bullet.circle.fill' : Icons.list_alt,
      input: const AdaptiveAlertDialogInput(
        placeholder: 'z.B. Wocheneinkauf',
        initialValue: '',
        keyboardType: TextInputType.text,
      ),
      actions: [
        AlertAction(
          title: 'Abbrechen',
          style: AlertActionStyle.cancel,
          onPressed: () {},
        ),
        AlertAction(
          title: 'Erstellen',
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
            const SnackBar(content: Text('Liste erstellt')),
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

  void _showJoinListDialog(BuildContext context, WidgetRef ref) async {
    final result = await AdaptiveAlertDialog.inputShow(
      context: context,
      title: 'Liste beitreten',
      message: 'Gib den Einladungscode ein',
      icon: PlatformInfo.isIOS26OrHigher() ? 'person.2.fill' : Icons.group,
      input: const AdaptiveAlertDialogInput(
        placeholder: 'Einladungscode',
        initialValue: '',
        keyboardType: TextInputType.text,
      ),
      actions: [
        AlertAction(
          title: 'Abbrechen',
          style: AlertActionStyle.cancel,
          onPressed: () {},
        ),
        AlertAction(
          title: 'Beitreten',
          style: AlertActionStyle.primary,
          onPressed: () {},
        ),
      ],
    );

    if (result != null && result.trim().isNotEmpty) {
      try {
        // Hier würde die Join-List-Logik implementiert werden
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Liste beigetreten: ${result.trim()}')),
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
    String listId,
    String name,
    int itemCount,
    VoidCallback onTap,
  ) {
    return Container(
      width: 140,
      height: 140 * 1.75,
      margin: const EdgeInsets.only(right: AppDimensions.spacingMedium),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
            borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  name,
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black
                        : Colors.white,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$itemCount Items',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black54
                        : Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GreetingHeader extends SliverPersistentHeaderDelegate {
  final String displayName;
  final VoidCallback onAvatarTap;

  _GreetingHeader({required this.displayName, required this.onAvatarTap});

  @override
  double get minExtent => 0;

  @override
  double get maxExtent => 120;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final t = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final opacity = 1.0 - t;
    final scale = 1.0 - (t * 0.1); // Skalierung: 1.0 → 0.9
    final translateY = t * -20.0; // Nach oben verschieben beim Scrollen

    return Container(
      color: Colors.transparent,
      child: Opacity(
        opacity: opacity,
        child: Transform.translate(
          offset: Offset(0, translateY),
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.only(
                top: AppDimensions.spacingXLarge,
                left: AppDimensions.screenHorizontalPadding,
                right: AppDimensions.screenHorizontalPadding,
                bottom: AppDimensions.spacingSmall,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Hallo $displayName',
                          style: AppTextStyles.h1.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 32,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Willkommen bei Shoply',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: onAvatarTap,
                    child: CircleAvatar(
                      radius: AppDimensions.avatarSizeMedium / 2,
                      child: Text(
                        (displayName.isNotEmpty ? displayName[0] : 'U').toUpperCase(),
                        style: AppTextStyles.h2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _GreetingHeader oldDelegate) {
    return oldDelegate.displayName != displayName;
  }
}
