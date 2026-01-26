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
    if (location.startsWith('/avo')) return 1; // AI/Avo chat tab
    if (location.startsWith('/recipes')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
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
        context.go('/avo'); // AI/Avo chat
        break;
      case 2:
        context.go('/recipes');
        if (fromTutorial) {
          tutorial.onRouteChanged('/recipes');
        }
        break;
      case 3:
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
                  icon: 'bubble.left.and.bubble.right.fill', // Avo chat
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
              // Recipes tab (now index 2, third from left)
              left: screenWidth * 0.625 - 24, // 5/8 of screen width
              width: 48, // Icon touch area
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
              left: screenWidth / 8 - 24, // Center of first quarter
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
          const BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy_rounded), // Avo chat
            activeIcon: Icon(Icons.smart_toy_rounded),
            label: 'Avo',
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

