import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shoply/core/constants/app_colors.dart';
import 'package:shoply/core/constants/app_dimensions.dart';
import 'package:shoply/core/constants/app_text_styles.dart';
import 'package:shoply/data/services/supabase_service.dart';
import 'package:shoply/data/services/shopping_history_service.dart';
import 'package:shoply/presentation/screens/history/shopping_history_screen.dart';
import 'package:shoply/presentation/state/lists_provider.dart';
import 'package:intl/intl.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = SupabaseService.instance.currentUser;
    final displayName = user?.userMetadata?['display_name'] ?? 'User';
    final listsAsync = ref.watch(listsNotifierProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Fixed Header
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Column(
              children: [
                // Spacer für Dynamic Island (1.5x größe)
                const SizedBox(height: 100), // ~44px Dynamic Island + 1.5x Abstand
                
                // Header with greeting and profile
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.screenHorizontalPadding,
                    0,
                    AppDimensions.screenHorizontalPadding,
                    0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Greeting
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, $displayName',
                              style: AppTextStyles.h2.copyWith(
                                fontWeight: FontWeight.w800, // Noch fetter
                                fontSize: 28,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Willkommen zu ShoplyAI',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Profile Icon
                      GestureDetector(
                        onTap: () => context.go('/profile'),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                          child: Icon(
                            Icons.person,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.black
                                : Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppDimensions.spacingLarge),
                  
                  // Lists Section Header
                  Padding(
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
                  TextButton(
                    onPressed: () => context.go('/lists?create=true'),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
                    child: Text(
                      '+ Neue Liste',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppDimensions.spacingMedium),
            
            // Horizontal Lists
            listsAsync.when(
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
                
                return SizedBox(
                  height: 140 * 1.75, // Angepasste Höhe für größere Karten
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.screenHorizontalPadding,
                    ),
                    itemCount: lists.length,
                    itemBuilder: (context, index) {
                      final list = lists[index];
                      return _buildListCard(
                        context,
                        list.id,
                        list.name,
                        list.itemCount ?? 0,
                        () => context.push('/lists/${list.id}?name=${Uri.encodeComponent(list.name)}'),
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
                  child: const Center(
                    child: Text('Fehler beim Laden'),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: AppDimensions.spacingLarge),
            
            // Shopping History Section
            Padding(
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
                    // Shopping History List
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
            
            const SizedBox(height: AppDimensions.spacingLarge),
            
            // Extra Padding für Navigation Bar - weiter nach unten
            const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
      height: 140 * 1.75, // 1.75x höher
      margin: const EdgeInsets.only(right: AppDimensions.spacingMedium),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white // Dark Mode: Weiß
                : Colors.black, // Light Mode: Schwarz
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
                // Name oben links
                Text(
                  name,
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black // Dark Mode: Schwarz
                        : Colors.white, // Light Mode: Weiß
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                // Item-Anzahl unten links
                Text(
                  '$itemCount Items',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black54 // Dark Mode: Schwarz (transparent)
                        : Colors.white70, // Light Mode: Weiß (transparent)
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
