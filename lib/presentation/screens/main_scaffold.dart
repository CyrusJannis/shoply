import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:shoply/data/services/dynamic_tutorial_service.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home')) return 0;
    // AI tab removed - index 1 skipped
    if (location.startsWith('/recipes')) return 1;
    if (location.startsWith('/profile')) return 2;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index, {bool fromTutorial = false}) {
    HapticFeedback.lightImpact();
    
    final tutorial = DynamicTutorialService.instance;
    
    switch (index) {
      case 0:
        context.go('/home');
        // Notify tutorial of route change
        if (fromTutorial) {
          tutorial.onRouteChanged('/home');
        }
        break;
      // AI tab removed - case 1 skipped
      case 1:
        context.go('/recipes');
        // Notify tutorial of route change
        if (fromTutorial) {
          tutorial.onRouteChanged('/recipes');
        }
        break;
      case 2:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final isIOS26Plus = PlatformInfo.isIOS26OrHigher();
    final tutorial = DynamicTutorialService.instance;

    // For iOS 26+, use native UITabBar with SF Symbols
    // Use a Stack to overlay an invisible tutorial target over the recipes tab
    if (isIOS26Plus) {
      final screenWidth = MediaQuery.of(context).size.width;
      final safeBottom = MediaQuery.of(context).padding.bottom;
      
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
          // Invisible overlay for tutorial targeting - positioned exactly over the tab icons
          // Native UITabBar icons are approximately 28x28pt, centered in their tab area
          if (!isKeyboardVisible)
            Positioned(
              // Center tab (recipes) - position exactly at center icon
              left: screenWidth / 2 - 24, // Center minus half icon width
              width: 48, // Icon touch area
              // Position at the center of the tab bar
              bottom: safeBottom + 12, // Center of 49pt tab bar
              height: 48, // Icon touch area
              child: IgnorePointer(
                child: Container(
                  key: tutorial.recipesTabKey,
                  color: Colors.transparent,
                ),
              ),
            ),
          // Home tab overlay (left tab icon)
          if (!isKeyboardVisible)
            Positioned(
              left: screenWidth / 6 - 24, // Center of left third minus half icon width
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

    // For older iOS and other platforms, use Material BottomNavigationBar with tutorial keys
    return Scaffold(
      body: child,
      bottomNavigationBar: isKeyboardVisible ? null : BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) {
          HapticFeedback.lightImpact();
          _onItemTapped(context, index, fromTutorial: true);
        },
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home_rounded,
              key: tutorial.homeTabKey,
            ),
            activeIcon: const Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.restaurant_menu_rounded,
              key: tutorial.recipesTabKey,
            ),
            activeIcon: const Icon(Icons.restaurant_menu_rounded),
            label: 'Recipes',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

