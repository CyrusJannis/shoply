import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shoply/core/constants/app_dimensions.dart';
import 'package:shoply/core/localization/localization_helper.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/lists')) return 1;
    if (location.startsWith('/recipes')) return 2;
    if (location.startsWith('/offers')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/lists');
        break;
      case 2:
        context.go('/recipes');
        break;
      case 3:
        context.go('/offers');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedIndex = _calculateSelectedIndex(context);
    
    return Scaffold(
      body: child,
      extendBody: true, // Ermöglicht Body unter der Navigation Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: theme.brightness == Brightness.light
                  ? Colors.black.withOpacity(0.05)
                  : Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: theme.bottomNavigationBarTheme.backgroundColor?.withOpacity(0.85),
                border: Border(
                  top: BorderSide(
                    color: theme.dividerColor.withOpacity(0.2),
                    width: 0.5,
                  ),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: AppDimensions.paddingSmall,
                    right: AppDimensions.paddingSmall,
                    top: 12, // Gleicher Abstand oben und unten
                    bottom: 12, // Gleicher Abstand oben und unten
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(
                        context,
                        icon: Icons.house_outlined,
                        activeIcon: Icons.house,
                        label: context.tr('home'),
                        index: 0,
                        isSelected: selectedIndex == 0,
                      ),
                      _buildNavItem(
                        context,
                        icon: Icons.checklist_outlined,
                        activeIcon: Icons.checklist,
                        label: context.tr('lists'),
                        index: 1,
                        isSelected: selectedIndex == 1,
                      ),
                      _buildNavItem(
                        context,
                        icon: Icons.menu_book_outlined,
                        activeIcon: Icons.menu_book,
                        label: context.tr('recipes'),
                        index: 2,
                        isSelected: selectedIndex == 2,
                      ),
                      _buildNavItem(
                        context,
                        icon: Icons.shopping_bag_outlined,
                        activeIcon: Icons.shopping_bag,
                        label: context.tr('stores'),
                        index: 3,
                        isSelected: selectedIndex == 3,
                      ),
                      _buildNavItem(
                        context,
                        icon: Icons.person_outline,
                        activeIcon: Icons.person,
                        label: context.tr('profile'),
                        index: 4,
                        isSelected: selectedIndex == 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    // Schwarz für aktive Items, Grau für inaktive
    final color = isSelected
        ? (isDarkMode ? Colors.white : Colors.black)
        : theme.bottomNavigationBarTheme.unselectedItemColor;

    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(context, index),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: color,
                size: isSelected ? 30 : 28, // Noch größer
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12, // Noch größer
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
