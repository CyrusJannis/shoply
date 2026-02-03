import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:shoply/core/constants/app_colors.dart';
import 'package:shoply/data/services/dynamic_tutorial_service.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/recipes')) return 1;
    if (location.startsWith('/profile')) return 2;
    return 0;
  }

  bool _isAvoSelected(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    return location.startsWith('/avo');
  }

  void _onItemTapped(BuildContext context, int index, {bool fromTutorial = false}) {
    HapticFeedback.lightImpact();
    
    final tutorial = DynamicTutorialService.instance;
    
    switch (index) {
      case 0:
        context.go('/home');
        if (fromTutorial) {
          tutorial.onRouteChanged('/home');
        }
        break;
      case 1:
        context.go('/recipes');
        if (fromTutorial) {
          tutorial.onRouteChanged('/recipes');
        }
        break;
      case 2:
        context.go('/profile');
        break;
    }
  }

  void _onAvoTapped(BuildContext context) {
    HapticFeedback.mediumImpact();
    context.go('/avo');
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final isIOS26Plus = PlatformInfo.isIOS26OrHigher();
    final tutorial = DynamicTutorialService.instance;

    // For iOS 26+, use native UITabBar with SF Symbols + floating Avo button
    if (isIOS26Plus) {
      final screenWidth = MediaQuery.of(context).size.width;
      final safeBottom = MediaQuery.of(context).padding.bottom;
      final isAvoActive = _isAvoSelected(context);
      final isDark = Theme.of(context).brightness == Brightness.dark;
      
      return Stack(
        children: [
          AdaptiveScaffold(
            body: child,
            minimizeBehavior: TabBarMinimizeBehavior.never,
            bottomNavigationBar: isKeyboardVisible ? null : AdaptiveBottomNavigationBar(
              useNativeBottomBar: true,
              selectedIndex: selectedIndex,
              onTap: (index) {
                HapticFeedback.lightImpact();
                _onItemTapped(context, index, fromTutorial: true);
              },
              items: const [
                AdaptiveNavigationDestination(
                  icon: 'house.fill',
                  label: '',
                ),
                AdaptiveNavigationDestination(
                  icon: 'fork.knife',
                  label: '',
                ),
                AdaptiveNavigationDestination(
                  icon: 'person.fill',
                  label: '',
                ),
              ],
            ),
          ),
          // Floating Avo button on far right
          if (!isKeyboardVisible)
            Positioned(
              right: 16,
              bottom: safeBottom + 8,
              child: GestureDetector(
                onTap: () => _onAvoTapped(context),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isAvoActive 
                        ? AppColors.freshGreen
                        : (isDark ? const Color(0xFF2C2C2E) : Colors.white),
                    boxShadow: [
                      BoxShadow(
                        color: isAvoActive 
                            ? AppColors.freshGreen.withValues(alpha: 0.4)
                            : Colors.black.withValues(alpha: 0.15),
                        blurRadius: isAvoActive ? 12 : 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      color: isAvoActive 
                          ? AppColors.freshGreen
                          : (isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5E5)),
                      width: isAvoActive ? 2 : 1,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/avo/avo_waving.gif',
                      width: 36,
                      height: 36,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          // Invisible overlay for tutorial targeting
          if (!isKeyboardVisible)
            Positioned(
              // Recipes tab (now index 1, second from left in 3-item bar)
              left: screenWidth * 0.5 - 24 - 35, // Adjusted for 3 items + offset for Avo space
              width: 48,
              bottom: safeBottom + 12,
              height: 48,
              child: IgnorePointer(
                child: Container(
                  key: tutorial.recipesTabKey,
                  color: Colors.transparent,
                ),
              ),
            ),
          // Home tab overlay
          if (!isKeyboardVisible)
            Positioned(
              left: (screenWidth - 70) / 6 - 24, // Center of first third of nav area
              width: 48,
              bottom: safeBottom + 12,
              height: 48,
              child: IgnorePointer(
                child: Container(
                  key: tutorial.homeTabKey,
                  color: Colors.transparent,
                ),
              ),
            ),
        ],
      );
    }

    // For older iOS and other platforms, use floating pill navbar with Avo button
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAvoActive = _isAvoSelected(context);
    final safeBottom = MediaQuery.of(context).padding.bottom;
    
    return Scaffold(
      body: Stack(
        children: [
          child,
          // Floating pill navbar at bottom
          if (!isKeyboardVisible)
            Positioned(
              left: 0,
              right: 0,
              bottom: safeBottom + 8,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    // Main pill navbar
                    Expanded(
                      child: Container(
                        height: 64,
                        decoration: BoxDecoration(
                          color: isDark 
                              ? const Color(0xFF1C1C1E)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: isDark 
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.06),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildNavItem(
                              context,
                              icon: Icons.home_rounded,
                              isSelected: selectedIndex == 0,
                              onTap: () => _onItemTapped(context, 0, fromTutorial: true),
                              key: tutorial.homeTabKey,
                            ),
                            _buildNavItem(
                              context,
                              icon: Icons.restaurant_menu_rounded,
                              isSelected: selectedIndex == 1,
                              onTap: () => _onItemTapped(context, 1, fromTutorial: true),
                              key: tutorial.recipesTabKey,
                            ),
                            _buildNavItem(
                              context,
                              icon: Icons.settings_rounded,
                              isSelected: selectedIndex == 2,
                              onTap: () => _onItemTapped(context, 2, fromTutorial: true),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Floating Avo button
                    GestureDetector(
                      onTap: () => _onAvoTapped(context),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isAvoActive 
                              ? AppColors.freshGreen
                              : (isDark ? const Color(0xFFF5F5F5) : const Color(0xFFF5F5F5)),
                          boxShadow: [
                            BoxShadow(
                              color: isAvoActive 
                                  ? AppColors.freshGreen.withValues(alpha: 0.4)
                                  : Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                              blurRadius: isAvoActive ? 16 : 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/avo/avo_waving.gif',
                            width: 44,
                            height: 44,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    Key? key,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Icon(
          icon,
          key: key,
          size: 24,
          color: isSelected 
              ? (isDark ? Colors.white : const Color(0xFF1A1A1A))
              : (isDark ? Colors.white.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.35)),
        ),
      ),
    );
  }
}

