import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';

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
    HapticFeedback.lightImpact();
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
    final selectedIndex = _calculateSelectedIndex(context);
    final isIOS26 = PlatformInfo.isIOS26OrHigher();

    return AdaptiveScaffold(
      body: child,
      minimizeBehavior: TabBarMinimizeBehavior.never, // Navbar bleibt immer gleich groß
      bottomNavigationBar: AdaptiveBottomNavigationBar(
        useNativeBottomBar: isIOS26, // Native iOS 26 UITabBar with Liquid Glass nur auf iOS26+
        selectedIndex: selectedIndex,
        onTap: (index) {
          HapticFeedback.lightImpact();
          _onItemTapped(context, index);
        },
        items: [
          AdaptiveNavigationDestination(
            icon: isIOS26 ? 'house.fill' : Icons.home,
            label: 'Home',
          ),
          AdaptiveNavigationDestination(
            icon: isIOS26 ? 'sparkles' : Icons.auto_awesome,
            label: 'AI',
          ),
          AdaptiveNavigationDestination(
            icon: isIOS26 ? 'fork.knife' : Icons.restaurant,
            label: 'Rezepte',
          ),
          AdaptiveNavigationDestination(
            icon: isIOS26 ? 'person.fill' : Icons.person,
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

