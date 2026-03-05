import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

/// A widget that renders real iOS 26 Liquid Glass via native UIGlassEffect,
/// or a BackdropFilter frosted-glass fallback on iOS < 26 and Android.
///
/// Usage:
/// ```dart
/// LiquidGlassContainer(
///   cornerRadius: 28,
///   child: Row(children: [...]),
/// )
/// ```
class LiquidGlassContainer extends StatelessWidget {
  final Widget child;
  final double cornerRadius;
  final bool isCircle;

  const LiquidGlassContainer({
    super.key,
    required this.child,
    this.cornerRadius = 0,
    this.isCircle = false,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return _buildNative(context);
    }
    return _buildFallback(context);
  }

  /// iOS: native UIGlassEffect via UiKitView
  Widget _buildNative(BuildContext context) {
    final borderRadius = isCircle
        ? BorderRadius.circular(999)
        : BorderRadius.circular(cornerRadius);

    return ClipRRect(
      borderRadius: borderRadius,
      child: Stack(
        children: [
          // Native glass view as background
          Positioned.fill(
            child: UiKitView(
              viewType: 'shoply/liquid_glass',
              creationParams: <String, dynamic>{
                'cornerRadius': cornerRadius,
                'isCircle': isCircle,
              },
              creationParamsCodec: const StandardMessageCodec(),
              hitTestBehavior: PlatformViewHitTestBehavior.transparent,
            ),
          ),
          // Flutter content on top
          child,
        ],
      ),
    );
  }

  /// Android / fallback: BackdropFilter frosted glass
  Widget _buildFallback(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderRadius = isCircle
        ? BorderRadius.circular(999)
        : BorderRadius.circular(cornerRadius);

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      Colors.white.withValues(alpha: 0.12),
                      Colors.white.withValues(alpha: 0.06),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.75),
                      Colors.white.withValues(alpha: 0.55),
                    ],
            ),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.8),
              width: 0.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
