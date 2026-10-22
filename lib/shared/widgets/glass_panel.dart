import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

/// Frosted glass container for sheets and mini players.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.borderRadius,
    this.backgroundColor,
    this.blur = 24.0,
  });

  final Widget child;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final double blur;

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? AppRadii.brSheet;
    final bg = backgroundColor ?? AppColors.surfaceHigh.withValues(alpha: 0.85);

    return ClipRRect(
      borderRadius: br,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: ColoredBox(color: bg, child: child),
      ),
    );
  }
}
