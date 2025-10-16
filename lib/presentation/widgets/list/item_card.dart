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
                // Checkbox
                Checkbox(
                  value: item.isChecked,
                  onChanged: onCheckedChanged,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                
                const SizedBox(width: AppDimensions.spacingSmall),
                
                // Category Icon
                if (item.category != null) ...[
                  Text(
                    CategoryDetector.getCategoryIcon(item.category!),
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: AppDimensions.spacingSmall),
                ],
                
                // Item Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      
                      Row(
                        children: [
                          // Quantity
                          Text(
                            '${item.quantity}${item.unit != null ? ' ${item.unit}' : ''}',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          
                          // Category tag
                          if (item.category != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item.category!,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                          
                          // Diet warning
                          if (item.isDietWarning) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.warning_amber,
                              size: 16,
                              color: AppColors.warning,
                            ),
                          ],
                        ],
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
