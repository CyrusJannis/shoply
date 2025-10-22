import 'package:flutter/material.dart';
import 'package:shoply/core/constants/app_colors.dart';
import 'package:shoply/core/constants/app_dimensions.dart';
import 'package:shoply/core/constants/app_text_styles.dart';
import 'package:shoply/core/utils/category_detector.dart';
import 'package:shoply/data/models/shopping_item_model.dart';

class ItemCard extends StatelessWidget {
  final ShoppingItemModel item;
  final VoidCallback? onTap;
  final ValueChanged<bool?>? onCheckedChanged;
  final VoidCallback? onDelete;
  final bool showAddedBy;

  const ItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.onCheckedChanged,
    this.onDelete,
    this.showAddedBy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppDimensions.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Item'),
            content: Text('Remove "${item.name}" from the list?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) => onDelete?.call(),
      child: Card(
        margin: const EdgeInsets.only(bottom: AppDimensions.spacingSmall),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
          side: item.isDietWarning
              ? const BorderSide(color: AppColors.warning, width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.cardPadding),
            child: Row(
              children: [
                // Category Icon - 1.75x höher
                Container(
                  width: 56,
                  height: 56 * 1.75, // 1.75x höher
                  decoration: BoxDecoration(
                    color: item.category != null
                        ? CategoryDetector.getCategoryColor(item.category!).withOpacity(0.1)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.category != null ? CategoryDetector.getCategoryIcon(item.category!) : '📦',
                    style: const TextStyle(fontSize: 32),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(width: AppDimensions.spacingMedium),

                // Item Details - vertikales Layout
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Name oben links
                      Text(
                        item.name,
                        style: AppTextStyles.bodyLarge.copyWith(
                          decoration: item.isChecked
                              ? TextDecoration.lineThrough
                              : null,
                          color: item.isChecked ? Colors.grey : null,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Items-Anzahl unten links
                      Text(
                        '${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity}${item.unit != null ? ' ${item.unit}' : ''}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),

                      // Notes
                      if (item.notes != null && item.notes!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.notes!,
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.grey.shade500,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Checkbox - rechts
                Checkbox(
                  value: item.isChecked,
                  onChanged: onCheckedChanged,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
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
