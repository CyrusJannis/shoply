import 'package:flutter/material.dart';
import 'package:shoply/data/models/recipe_filter.dart';

class QuickFilterCard extends StatelessWidget {
  final QuickFilter filter;
  final bool isActive;
  final VoidCallback onTap;

  const QuickFilterCard({
    super.key,
    required this.filter,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDarkMode
                      ? [
                          Theme.of(context).primaryColor.withOpacity(0.9),
                          Theme.of(context).primaryColor.withOpacity(0.7),
                        ]
                      : [
                          Theme.of(context).primaryColor.withOpacity(0.9),
                          Theme.of(context).primaryColor.withOpacity(0.7),
                        ],
                )
              : null,
          color: isActive ? null : (isDarkMode ? Colors.grey.withOpacity(0.15) : Colors.grey.withOpacity(0.15)),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isActive
                ? Colors.white.withOpacity(0.3)
                : Colors.grey.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              filter.icon,
              color: isActive ? Colors.white : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              filter.label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? Colors.white : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
