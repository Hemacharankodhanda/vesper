import 'package:flutter/material.dart';
import 'tokens.dart';

abstract final class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.surface,
        primary: AppColors.accentFallback,
        error: AppColors.danger,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      fontFamily: AppTypography.bodyFont,
      textTheme: const TextTheme(
        displayLarge: AppTypography.display,
        displayMedium: AppTypography.display,
        titleLarge: AppTypography.title,
        titleMedium: AppTypography.title,
        bodyLarge: AppTypography.body,
        bodyMedium: AppTypography.body,
        bodySmall: AppTypography.caption,
        labelSmall: AppTypography.captionMuted,
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 24.0),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF6F5F2),
      colorScheme: const ColorScheme.light(
        surface: Color(0xFFFFFFFF),
        primary: AppColors.accentFallback,
        error: AppColors.danger,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      fontFamily: AppTypography.bodyFont,
      textTheme: TextTheme(
        displayLarge: AppTypography.display.copyWith(
          color: const Color(0xFF14151A),
        ),
        displayMedium: AppTypography.display.copyWith(
          color: const Color(0xFF14151A),
        ),
        titleLarge: AppTypography.title.copyWith(
          color: const Color(0xFF14151A),
        ),
        titleMedium: AppTypography.title.copyWith(
          color: const Color(0xFF14151A),
        ),
        bodyLarge: AppTypography.body.copyWith(color: const Color(0xFF14151A)),
        bodyMedium: AppTypography.body.copyWith(color: const Color(0xFF14151A)),
        bodySmall: AppTypography.caption.copyWith(
          color: const Color(0x9914151A),
        ),
        labelSmall: AppTypography.captionMuted.copyWith(
          color: const Color(0x6614151A),
        ),
      ),
      iconTheme: const IconThemeData(color: Color(0xFF14151A), size: 24.0),
    );
  }
}
