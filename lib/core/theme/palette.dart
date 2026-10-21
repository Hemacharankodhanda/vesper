import 'package:flutter/material.dart';
import 'tokens.dart';

/// Represents a 3-color palette [deep, mid, light] derived from album art or fallback.
class VesperPalette {
  const VesperPalette({
    required this.deep,
    required this.mid,
    required this.light,
  });

  final Color deep;
  final Color mid;
  final Color light;

  static const VesperPalette fallback = VesperPalette(
    deep: AppColors.bg,
    mid: AppColors.surface,
    light: AppColors.accentFallback,
  );

  /// Vertical gradient top color: lerp(mid, deep, 0.35)
  Color get gradientTop => Color.lerp(mid, deep, 0.35) ?? mid;

  /// Vertical gradient bottom color: deep
  Color get gradientBottom => deep;

  /// Hero art shadow: color = palette.deep @ 55%, blur 40, y 20
  BoxShadow get heroShadow => BoxShadow(
    color: deep.withValues(alpha: 0.55),
    blurRadius: 40,
    offset: const Offset(0, 20),
  );

  LinearGradient get backgroundGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [gradientTop, gradientBottom],
  );

  /// Derives a [VesperPalette] from an [ImageProvider] using Flutter's built-in [ColorScheme.fromImageProvider].
  static Future<VesperPalette> fromImageProvider(ImageProvider provider) async {
    try {
      final scheme = await ColorScheme.fromImageProvider(
        provider: provider,
        brightness: Brightness.dark,
      );

      // Deep: darkest base
      final deep = scheme.surfaceContainerLowest;
      // Mid: secondary or primary container
      final mid = scheme.surfaceContainerHigh;
      // Light: accent with ensured minimum luminance/contrast for dark theme
      final light = scheme.primary;

      return VesperPalette(deep: deep, mid: mid, light: light);
    } catch (_) {
      return fallback;
    }
  }

  VesperPalette lerpTo(VesperPalette other, double t) {
    return VesperPalette(
      deep: Color.lerp(deep, other.deep, t) ?? other.deep,
      mid: Color.lerp(mid, other.mid, t) ?? other.mid,
      light: Color.lerp(light, other.light, t) ?? other.light,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VesperPalette &&
          runtimeType == other.runtimeType &&
          deep == other.deep &&
          mid == other.mid &&
          light == other.light;

  @override
  int get hashCode => Object.hash(deep, mid, light);
}
