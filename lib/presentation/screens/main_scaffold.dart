import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shoply/core/constants/app_colors.dart';
import 'package:shoply/data/services/dynamic_tutorial_service.dart';
import 'package:shoply/presentation/widgets/common/liquid_glass_container.dart';

/// Main scaffold with native Liquid Glass navbar and fluid animations.
///
/// Layout: floating [ glass pill (Home, Recipes, Profile) ] — gap — [ glass circle (Avo) ]
///
/// Animations:
/// - Sliding translucent highlight bubble behind the active icon
/// - Spring physics for natural, liquid-glass-like movement
/// - Horizontal pan gestures to slide between tabs
/// - Icon scale + opacity transitions
class MainScaffold extends StatefulWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  // Layout constants — Apple HIG-aligned for iOS 26 Liquid Glass
  static const double _pillHeight = 64.0;
  static const double _avoSize = 64.0;
  static const double _avoImgSize = 38.0;
  static const double _bottomMargin = 0.0;
  static const double _horizontalPad = 24.0;
  static const double _gap = 14.0;
  static const double _iconSize = 28.0;
  static const int _tabCount = 3;

  /// Bottom padding child screens need to clear the floating navbar.
  static double getNavbarClearance(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    return safeBottom + _pillHeight + _bottomMargin + 12.0;
  }

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold>
    with TickerProviderStateMixin {
  // ── Animation controllers ──
  late final AnimationController _slideController;
  late final AnimationController _glowController;
  late Animation<double> _slideAnimation;

  // ── State ──
  int _currentIndex = 0;
  double _dragOffset = 0.0; // normalised 0..2 during pan
  bool _isDragging = false;

  // Highlight bubble dimensions
  static const double _bubbleHeight = 44.0;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(vsync: this);
    _slideAnimation =
        AlwaysStoppedAnimation<double>(_currentIndex.toDouble());

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  // ── Route → index helpers ──

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

  // ── Navigation ──

  void _onTab(BuildContext context, int index) {
    if (index == _currentIndex) return;
    HapticFeedback.lightImpact();
    _animateToIndex(index);
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

  // ── Spring animation to a tab index ──

  void _animateToIndex(int index) {
    final from = _slideAnimation.value;
    final to = index.toDouble();

    _slideController.stop();

    // Use a spring simulation for liquid-glass-like feel
    final spring = SpringDescription(
      mass: 1.0,
      stiffness: 350,
      damping: 28,
    );
    final sim = SpringSimulation(spring, from, to, 0);

    _slideAnimation = _slideController.drive(
      Tween<double>(begin: from, end: to),
    );

    // Map spring simulation duration (estimate ~600ms for these params)
    _slideController.duration = const Duration(milliseconds: 600);
    _slideController.reset();
    _slideController.animateWith(sim);

    // Trigger glow pulse on tab change
    _glowController.forward(from: 0);

    setState(() => _currentIndex = index);
  }

  // ── Horizontal pan handling ──

  void _onPanStart(DragStartDetails _) {
    _slideController.stop();
    _isDragging = true;
    _dragOffset = _slideAnimation.value;
  }

  void _onPanUpdate(DragUpdateDetails details, double pillWidth) {
    if (!_isDragging) return;
    final tabWidth = pillWidth / MainScaffold._tabCount;
    final delta = details.delta.dx / tabWidth;
    _dragOffset = (_dragOffset - delta).clamp(0.0, 2.0);

    _slideAnimation = AlwaysStoppedAnimation<double>(_dragOffset);
    setState(() {});
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDragging) return;
    _isDragging = false;

    // Snap to nearest tab
    final target = _dragOffset.round().clamp(0, 2);
    if (target != _currentIndex) {
      HapticFeedback.lightImpact();
    }
    _animateToIndex(target);

    // Navigate
    final t = DynamicTutorialService.instance;
    switch (target) {
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

  @override
  Widget build(BuildContext context) {
    final kbd = MediaQuery.of(context).viewInsets.bottom > 0;
    final routeIndex = _selectedIndex(context);
    final avo = _isAvoActive(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final safeBot = MediaQuery.of(context).padding.bottom;
    final tut = DynamicTutorialService.instance;

    // Sync with route changes triggered externally (e.g. back navigation)
    if (routeIndex != _currentIndex && !_isDragging) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && routeIndex != _currentIndex) {
          _animateToIndex(routeIndex);
        }
      });
    }

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: Stack(
        children: [
          widget.child,
          if (!kbd)
            Positioned(
              left: MainScaffold._horizontalPad,
              right: MainScaffold._horizontalPad,
              bottom: safeBot + MainScaffold._bottomMargin,
              child: Row(
                children: [
                  // ── Glass Pill (3 tabs) ──
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                            MainScaffold._pillHeight / 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                                alpha: isDark ? 0.4 : 0.12),
                            blurRadius: 20,
                            spreadRadius: 0,
                            offset: const Offset(0, 4),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(
                                alpha: isDark ? 0.2 : 0.06),
                            blurRadius: 6,
                            spreadRadius: 0,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: LiquidGlassContainer(
                        cornerRadius: MainScaffold._pillHeight / 2,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final pillWidth = constraints.maxWidth;
                            return GestureDetector(
                              onHorizontalDragStart: _onPanStart,
                              onHorizontalDragUpdate: (d) =>
                                  _onPanUpdate(d, pillWidth),
                              onHorizontalDragEnd: _onPanEnd,
                              behavior: HitTestBehavior.translucent,
                              child: SizedBox(
                                  height: MainScaffold._pillHeight,
                                  child: AnimatedBuilder(
                                    animation: Listenable.merge(
                                        [_slideController, _glowController]),
                                    builder: (context, _) {
                                      final pos = _isDragging
                                          ? _dragOffset
                                          : _slideAnimation.value;
                                      return Stack(
                                        children: [
                                          // ── Sliding highlight bubble ──
                                          _SlidingBubble(
                                            position: pos,
                                            tabCount:
                                                MainScaffold._tabCount,
                                            pillWidth: pillWidth,
                                            pillHeight:
                                                MainScaffold._pillHeight,
                                            bubbleHeight: _bubbleHeight,
                                            isDark: isDark,
                                            glowValue:
                                                _glowController.value,
                                          ),
                                          // ── Icons row ──
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment
                                                    .spaceEvenly,
                                            children: [
                                              _AnimatedNavIcon(
                                                icon: Icons.home_rounded,
                                                index: 0,
                                                currentPosition: pos,
                                                isDark: isDark,
                                                onTap: () =>
                                                    _onTab(context, 0),
                                                itemKey: tut.homeTabKey,
                                              ),
                                              _AnimatedNavIcon(
                                                icon: Icons
                                                    .restaurant_menu_rounded,
                                                index: 1,
                                                currentPosition: pos,
                                                isDark: isDark,
                                                onTap: () =>
                                                    _onTab(context, 1),
                                                itemKey: tut.recipesTabKey,
                                              ),
                                              _AnimatedNavIcon(
                                                icon: Icons.person_rounded,
                                                index: 2,
                                                currentPosition: pos,
                                                isDark: isDark,
                                                onTap: () =>
                                                    _onTab(context, 2),
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: MainScaffold._gap),
                  // ── Glass Circle (Avo) ──
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                              alpha: isDark ? 0.4 : 0.12),
                          blurRadius: 20,
                          spreadRadius: 0,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(
                              alpha: isDark ? 0.2 : 0.06),
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
                        size: MainScaffold._avoSize,
                        imgSize: MainScaffold._avoImgSize,
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
// Sliding highlight bubble — liquid-glass-like translucent glow
// ──────────────────────────────────────────────────────────────

class _SlidingBubble extends StatelessWidget {
  final double position; // 0.0 = first tab, 1.0 = second, 2.0 = third
  final int tabCount;
  final double pillWidth;
  final double pillHeight;
  final double bubbleHeight;
  final bool isDark;
  final double glowValue; // 0..1 pulse from glow controller

  const _SlidingBubble({
    required this.position,
    required this.tabCount,
    required this.pillWidth,
    required this.pillHeight,
    required this.bubbleHeight,
    required this.isDark,
    required this.glowValue,
  });

  @override
  Widget build(BuildContext context) {
    final tabWidth = pillWidth / tabCount;
    final bubbleWidth = tabWidth * 0.72;
    // Center the bubble on the current tab position
    final centerX = tabWidth * (position + 0.5);
    final left = centerX - bubbleWidth / 2;
    final top = (pillHeight - bubbleHeight) / 2;

    // Glow pulse: fade in fast, fade out slow (ease-out)
    final glowCurve = Curves.easeOut.transform(1.0 - glowValue);
    final extraGlow = (1.0 - glowCurve) * 0.12;

    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: bubbleWidth,
        height: bubbleHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(bubbleHeight / 2),
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.85,
            colors: isDark
                ? [
                    Colors.white.withValues(alpha: 0.14 + extraGlow),
                    Colors.white.withValues(alpha: 0.06),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.85 + extraGlow),
                    Colors.white.withValues(alpha: 0.45),
                  ],
          ),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.20 + extraGlow * 0.5)
                : Colors.white.withValues(alpha: 0.90),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06 + extraGlow)
                  : Colors.white.withValues(alpha: 0.50 + extraGlow),
              blurRadius: 12 + extraGlow * 40,
              spreadRadius: 0,
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Animated nav icon with scale + opacity driven by slide position
// ──────────────────────────────────────────────────────────────

class _AnimatedNavIcon extends StatelessWidget {
  final IconData icon;
  final int index;
  final double currentPosition; // continuous 0..2
  final bool isDark;
  final VoidCallback onTap;
  final Key? itemKey;

  const _AnimatedNavIcon({
    required this.icon,
    required this.index,
    required this.currentPosition,
    required this.isDark,
    required this.onTap,
    this.itemKey,
  });

  @override
  Widget build(BuildContext context) {
    // How close are we to this tab? 0 = exactly on it, 1+ = far away
    final distance = (currentPosition - index).abs().clamp(0.0, 1.0);

    // Scale: active = 1.15, inactive = 1.0
    final scale = lerpDouble(1.15, 1.0, distance)!;

    // Opacity: active = 1.0, inactive = lower
    final activeAlpha = isDark ? 1.0 : 0.95;
    final inactiveAlpha = isDark ? 0.35 : 0.30;
    final alpha = lerpDouble(activeAlpha, inactiveAlpha, distance)!;

    final activeColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final inactiveColor = isDark
        ? Colors.white.withValues(alpha: 0.35)
        : Colors.black.withValues(alpha: 0.30);
    final color = Color.lerp(activeColor, inactiveColor, distance)!;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        // 44×44pt minimum touch target (Apple HIG)
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        child: Transform.scale(
          scale: scale,
          child: Icon(
            icon,
            key: itemKey,
            size: MainScaffold._iconSize,
            color: color.withValues(alpha: alpha),
          ),
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

