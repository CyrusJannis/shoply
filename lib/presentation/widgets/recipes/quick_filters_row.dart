import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoply/data/models/recipe_filter.dart';
import 'package:shoply/presentation/state/recipe_filter_provider.dart';
import 'package:shoply/presentation/widgets/recipes/quick_filter_card.dart';

class QuickFiltersRow extends ConsumerWidget {
  const QuickFiltersRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(recipeFilterProvider);

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: QuickFilters.all.length,
        itemBuilder: (context, index) {
          final filter = QuickFilters.all[index];
          final isActive = filterState.activeQuickFilters.contains(filter.id);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: QuickFilterCard(
              filter: filter,
              isActive: isActive,
              onTap: () {
                ref.read(recipeFilterProvider.notifier).toggleQuickFilter(filter.id);
              },
            ),
          );
        },
      ),
    );
  }
}
