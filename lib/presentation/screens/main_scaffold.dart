import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shoply/core/constants/app_colors.dart';
import 'package:shoply/data/services/dynamic_tutorial_service.dart';
import 'package:shoply/presentation/widgets/common/liquid_glass_container.dart';

/// Main scaffold with native Liquid Glass navbar.
///
/// Layout: floating [ glass pill (Home, Recipes, Profile) ] — gap — [ glass circle (Avo) ]
///
/// - iOS 26: real UIGlassEffect via native UiKitView
/// - iOS < 26: BackdropFilter frosted glass fallback
/// - Pill and circle are separate containers — no overlap
class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  // Layout constants — Apple HIG-aligned for iOS 26 Liquid Glass
  // Capsule shape (cornerRadius = height/2) matches Apple's default glass shape
  static const double _pillHeight = 64.0;
  static const double _avoSize = 64.0;
  static const double _avoImgSize = 38.0;
  static const double _bottomMargin = 0.0;   // sit right at safe area edge
  static const double _horizontalPad = 24.0;  // generous inset from screen curves
  static const double _gap = 14.0;            // visual separation pill ↔ circle
  static const double _iconSize = 28.0;       // SF Symbol standard

  /// Bottom padding child screens need to clear the floating navbar.
  static double getNavbarClearance(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    // pill height + bottom margin + extra clearance so content doesn't touch
    return safeBottom + _pillHeight + _bottomMargin + 12.0;
  }

  int _selectedIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    if (loc.startsWith('/home')) return 0;
    if (loc.startsWith('/recipes')) return 1;
    if (loc.startsWith('/profile')) return 2;
    return 0;
  }

  bool _isAvoActive(BuildContext context) {
    return GoRouterState.of(context).matchedLocation.startsWith('/avo');
  }

  void _onTab(BuildContext context, int index) {
    HapticFeedback.lightImpact();
    final t = DynamicTutorialService.instance;
    switch (index) {
      case 0:
        context.go('/home');
        t.onRouteChanged('/home');
      case 1:
        context.go('/recipes');
        t.onRouteChanged('/recipes');
      case 2:
        context.go('/profile');
    }
  }

  void _onAvo(BuildContext context) {
    HapticFeedback.mediumImpact();
    context.go('/avo');
  }

  @override
  Widget build(BuildContext context) {
    final kbd = MediaQuery.of(context).viewInsets.bottom > 0;
    final sel = _selectedIndex(context);
    final avo = _isAvoActive(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final safeBot = MediaQuery.of(context).padding.bottom;
    final tut = DynamicTutorialService.instance;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: Stack(
        children: [
          child,
          if (!kbd)
            Positioned(
              left: _horizontalPad,
              right: _horizontalPad,
              bottom: safeBot + _bottomMargin,
              child: Row(
                children: [
                  // ── Glass Pill (3 tabs) ──
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(_pillHeight / 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                            blurRadius: 20,
                            spreadRadius: 0,
                            offset: const Offset(0, 4),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                            blurRadius: 6,
                            spreadRadius: 0,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: LiquidGlassContainer(
                        cornerRadius: _pillHeight / 2,
                        child: SizedBox(
                          height: _pillHeight,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _NavIcon(
                                icon: Icons.home_rounded,
                                active: sel == 0,
                                isDark: isDark,
                                onTap: () => _onTab(context, 0),
                                itemKey: tut.homeTabKey,
                              ),
                              _NavIcon(
                                icon: Icons.restaurant_menu_rounded,
                                active: sel == 1,
                                isDark: isDark,
                                onTap: () => _onTab(context, 1),
                                itemKey: tut.recipesTabKey,
                              ),
                              _NavIcon(
                                icon: Icons.person_rounded,
                                active: sel == 2,
                                isDark: isDark,
                                onTap: () => _onTab(context, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: _gap),
                  // ── Glass Circle (Avo) ──
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                          blurRadius: 20,
                          spreadRadius: 0,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                          blurRadius: 6,
                          spreadRadius: 0,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: GestureDetector(
                      onTap: () => _onAvo(context),
                      behavior: HitTestBehavior.opaque,
                      child: _AvoCircle(
                        active: avo,
                        isDark: isDark,
                        size: _avoSize,
                        imgSize: _avoImgSize,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Nav icon inside the pill
// ──────────────────────────────────────────────────────────────

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final bool active;
  final bool isDark;
  final VoidCallback onTap;
  final Key? itemKey;

  const _NavIcon({
    required this.icon,
    required this.active,
    required this.isDark,
    required this.onTap,
    this.itemKey,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        // 44×44pt minimum touch target (Apple HIG)
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        child: Icon(
          icon,
          key: itemKey,
          size: MainScaffold._iconSize,
          color: active
              ? (isDark ? Colors.white : const Color(0xFF1A1A1A))
              : (isDark
                  ? Colors.white.withValues(alpha: 0.35)
                  : Colors.black.withValues(alpha: 0.30)),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Avo circle — liquid glass circle with avo_excited.png
// ──────────────────────────────────────────────────────────────

class _AvoCircle extends StatelessWidget {
  final bool active;
  final bool isDark;
  final double size;
  final double imgSize;

  const _AvoCircle({
    required this.active,
    required this.isDark,
    required this.size,
    required this.imgSize,
  });

  @override
  Widget build(BuildContext context) {
    // When active, wrap in a green-tinted container instead of glass
    if (active) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.freshGreen.withValues(alpha: 0.88),
              AppColors.freshGreen,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.freshGreen.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Image.asset(
            'assets/avo/avo_excited.png',
            width: imgSize,
            height: imgSize,
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    // Inactive: liquid glass circle
    return SizedBox(
      width: size,
      height: size,
      child: LiquidGlassContainer(
        isCircle: true,
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Image.asset(
              'assets/avo/avo_excited.png',
              width: imgSize,
              height: imgSize,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

