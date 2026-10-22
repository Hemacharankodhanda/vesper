import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

/// Standard minimal icon button adhering to Vesper tokens.
/// White at 100% when active, 38% when inactive. Requires semantic tooltip.
class IconBtn extends StatelessWidget {
  const IconBtn({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.size = 26.0,
    this.active = true,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final double size;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      iconSize: size,
      splashRadius: size,
      constraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
      icon: Icon(
        icon,
        color: active
            ? AppColors.textPrimary
            : AppColors.textPrimary.withValues(alpha: 0.38),
      ),
    );
  }
}
