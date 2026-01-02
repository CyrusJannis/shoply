import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoply/core/constants/app_text_styles.dart';
import 'package:shoply/core/constants/list_background_gradients.dart';
import 'package:shoply/core/localization/localization_helper.dart';
import 'package:shoply/presentation/state/lists_provider.dart';

/// Bottom sheet for selecting gradient backgrounds for shopping lists.
///
/// Displays a 3-column grid of predefined gradient options from
/// [ListBackgroundGradients]. User selection is saved immediately to
/// the database and the sheet auto-closes on success.
///
/// **Key Features**:
/// - 3-column grid layout with gradient previews
/// - Live selection preview with checkmark overlay
/// - Haptic feedback on tap
/// - Immediate database persistence
/// - Auto-close after successful save
/// - Error handling with user feedback
///
/// **Visual Design**:
/// - Each gradient shows full preview
/// - Selected gradient has white border + checkmark
/// - Gradient name shown at bottom of each tile
/// - Dark mode support with theme-aware container
///
/// **Usage Example**:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   isScrollControlled: true,
///   backgroundColor: Colors.transparent,
///   builder: (context) => BackgroundSelectionSheet(listId: listId),
/// );
/// ```
///
/// **Dependencies**:
/// - `listsNotifierProvider`: Saves background to database
/// - `ListBackgroundGradients`: Provides gradient definitions
///
/// **Important Notes**:
/// - Only handles gradient backgrounds (not solid colors or images)
/// - Requires valid listId that exists in database
/// - Network connection required for database save
///
/// See also:
/// - [ListBackgroundGradients] for gradient definitions
/// - [listsNotifierProvider.saveBackground] for persistence logic
class BackgroundSelectionSheet extends ConsumerStatefulWidget {
  /// The ID of the shopping list to update the background for.
  ///
  /// Must be a valid list ID that exists in the database.
  final String listId;

  const BackgroundSelectionSheet({super.key, required this.listId});

  @override
  ConsumerState<BackgroundSelectionSheet> createState() =>
      _BackgroundSelectionSheetState();
}

class _BackgroundSelectionSheetState
    extends ConsumerState<BackgroundSelectionSheet> {
  /// Currently selected background ID (used for UI preview before save).
  String? selectedBackground;

  /// Generates list of background options from predefined gradients.
  ///
  /// Converts [ListBackgroundGradients.gradients] map into a list of
  /// [_BackgroundOption] objects for easier UI rendering.
  List<_BackgroundOption> get backgrounds {
    return ListBackgroundGradients.gradients.entries.map((entry) {
      return _BackgroundOption(
        id: entry.key,
        name: ListBackgroundGradients.getGradientName(entry.key) ?? entry.key,
        gradient: entry.value,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1C1C1E)
            : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr('select_background'),
                  style: AppTextStyles.h2.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Grid of backgrounds
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.75,
              ),
              itemCount: backgrounds.length,
              itemBuilder: (context, index) {
                final bg = backgrounds[index];
                final isSelected = selectedBackground == bg.id;

                return GestureDetector(
                  onTap: () async {
                    setState(() => selectedBackground = bg.id);
                    
                    // Save background
                    try {
                      await ref
                          .read(listsNotifierProvider.notifier)
                          .saveBackground(widget.listId, 'gradient', bg.id, null);
                      
                      if (context.mounted) {
                        HapticFeedback.mediumImpact();
                        
                        // Refresh the list to show new background
                        ref.invalidate(listsNotifierProvider);
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(context.tr('background_saved', params: {'name': bg.name})),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${context.tr('error')}: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: bg.gradient,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.3),
                        width: isSelected ? 3 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.5),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Stack(
                      children: [
                        // Checkmark if selected
                        if (isSelected)
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.green,
                                size: 20,
                              ),
                            ),
                          ),
                        // Name at bottom
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                            ),
                            child: Text(
                              bg.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _BackgroundOption {
  final String id;
  final String name;
  final Gradient gradient;

  const _BackgroundOption({
    required this.id,
    required this.name,
    required this.gradient,
  });
}
