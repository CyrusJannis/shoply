import 'package:flutter/material.dart';
import 'package:shoply/core/utils/category_detector.dart';
import 'package:shoply/data/models/shopping_item_model.dart';

class ShoppingItemGridCard extends StatelessWidget {
  final ShoppingItemModel item;
  final VoidCallback? onTap;
  final ValueChanged<bool?>? onCheckedChanged;
  final VoidCallback? onDelete;

  const ShoppingItemGridCard({
    super.key,
    required this.item,
    this.onTap,
    this.onCheckedChanged,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: item.isChecked
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.green.withOpacity(0.3),
                    Colors.green.withOpacity(0.2),
                  ],
                )
              : null,
          color: item.isChecked
              ? null
              : (isDarkMode
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white),
          border: Border.all(
            color: item.isChecked
                ? Colors.green.withOpacity(0.5)
                : (isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.2)),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top row: Icon and Name
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  CategoryDetector.getCategoryIcon(item.category ?? ''),
                  size: 20,
                  color: item.isChecked
                      ? Colors.green.shade700
                      : CategoryDetector.getCategoryColor(item.category ?? ''),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      decoration: item.isChecked
                          ? TextDecoration.lineThrough
                          : null,
                      color: item.isChecked
                          ? Colors.grey.shade600
                          : (isDarkMode ? Colors.white : Colors.black),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            
            // Bottom row: Quantity and Checkbox
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (item.quantity > 0)
                  Text(
                    '${item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 1)} ${item.unit ?? ''}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  )
                else
                  const SizedBox.shrink(),
                Transform.scale(
                  scale: 0.9,
                  child: Checkbox(
                    value: item.isChecked,
                    onChanged: onCheckedChanged,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    activeColor: Colors.green.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
