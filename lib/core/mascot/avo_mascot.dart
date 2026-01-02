import 'package:flutter/material.dart';

/// Expression states for the Avo mascot.
/// Maps to the image files in assets/avo/
enum AvoExpression {
  /// Default/neutral state - uses happy image
  neutral,
  
  /// Happy state - smiling
  happy,
  
  /// Confused state - uses shocked image
  confused,
  
  /// Success state - uses excited/greeting image
  success,
  
  /// Waving/greeting state
  waving,
  
  /// Thinking state - uses happy image
  thinking,
  
  /// Excited state - waving with big smile
  excited,
  
  /// Shocked/surprised state
  shocked,
}

/// The name of our mascot
const String avoName = 'Avo';

/// Image-based avocado mascot widget.
/// Uses WebP images for fast loading and crisp rendering.
class AvoMascot extends StatefulWidget {
  final double size;
  final AvoExpression expression;
  final bool animate;
  final String? message;
  final VoidCallback? onTap;
  
  const AvoMascot({
    super.key,
    this.size = 80,
    this.expression = AvoExpression.neutral,
    this.animate = true,
    this.message,
    this.onTap,
  });

  @override
  State<AvoMascot> createState() => _AvoMascotState();
}

class _AvoMascotState extends State<AvoMascot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getImagePath() {
    switch (widget.expression) {
      case AvoExpression.neutral:
      case AvoExpression.thinking:
        return 'assets/avo/avo_happy.webp';
      case AvoExpression.happy:
        return 'assets/avo/avo_happy.webp';
      case AvoExpression.confused:
      case AvoExpression.shocked:
        return 'assets/avo/avo_shocked.webp';
      case AvoExpression.success:
      case AvoExpression.waving:
        return 'assets/avo/avo_greeting.webp';
      case AvoExpression.excited:
        return 'assets/avo/avo_excited.webp';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.message != null) ...[
            _buildSpeechBubble(context),
            const SizedBox(height: 8),
          ],
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: widget.animate ? _scaleAnimation.value : 1.0,
                child: Image.asset(
                  _getImagePath(),
                  width: widget.size,
                  height: widget.size,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSpeechBubble(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      constraints: BoxConstraints(maxWidth: widget.size * 2.5),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5E5),
          width: 1,
        ),
      ),
      child: Text(
        widget.message!,
        style: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.white : const Color(0xFF1C1C1E),
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Widget to show Avo with a speech bubble message.
class AvoWithMessage extends StatelessWidget {
  final String message;
  final AvoExpression expression;
  final double avoSize;
  
  const AvoWithMessage({
    super.key,
    required this.message,
    this.expression = AvoExpression.neutral,
    this.avoSize = 60,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AvoMascot(size: avoSize, expression: expression),
        const SizedBox(width: 10),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF5F5F5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
                height: 1.35,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
