import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/ai')) return 1;
    if (location.startsWith('/recipes')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/ai');
        break;
      case 2:
        context.go('/recipes');
        break;
      case 3:
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
      extendBody: true, // Allow body to extend under navigation bar
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(35),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: theme.brightness == Brightness.light ? 15 : 20,
              sigmaY: theme.brightness == Brightness.light ? 15 : 20,
            ),
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: theme.brightness == Brightness.light
                      ? [
                          Colors.white.withOpacity(0.25),
                          Colors.white.withOpacity(0.15),
                        ]
                      : [
                          Colors.black.withOpacity(0.4),
                          Colors.black.withOpacity(0.3),
                        ],
                ),
                borderRadius: BorderRadius.circular(35),
                border: Border.all(
                  color: theme.brightness == Brightness.light
                      ? Colors.white.withOpacity(0.4)
                      : Colors.white.withOpacity(0.2),
                  width: 1.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                    spreadRadius: -5,
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(
                    context,
                    icon: Icons.home_rounded,
                    index: 0,
                    isSelected: selectedIndex == 0,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.auto_awesome_rounded,
                    index: 1,
                    isSelected: selectedIndex == 1,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.restaurant_rounded,
                    index: 2,
                    isSelected: selectedIndex == 2,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.person_rounded,
                    index: 3,
                    isSelected: selectedIndex == 3,
                  ),
                ],
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
    required int index,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(context, index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: AnimatedScale(
              scale: isSelected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOutCubic,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutCubic,
                padding: EdgeInsets.all(isSelected ? 14 : 10),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDarkMode
                              ? [
                                  Colors.white.withOpacity(0.25),
                                  Colors.white.withOpacity(0.15),
                                ]
                              : [
                                  Colors.black.withOpacity(0.12),
                                  Colors.black.withOpacity(0.08),
                                ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: (isDarkMode ? Colors.white : Colors.black)
                                .withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? (isDarkMode ? Colors.white : Colors.black)
                      : (isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600),
                  size: 28,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
