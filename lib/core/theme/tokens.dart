import 'package:flutter/material.dart';

/// Design tokens for Vesper design system (02-DESIGN-SYSTEM.md).
/// Widgets must only use these tokens — no hardcoded colors, sizes, or durations.

abstract final class AppColors {
  // Dark theme core tokens
  static const Color bg = Color(0xFF0E0F12);
  static const Color surface = Color(0xFF16181D);
  static const Color surfaceHigh = Color(0xFF1E2128);

  static const Color textPrimary = Color(0xFFF5F5F7);
  static const Color textSecondary = Color(0xA3FFFFFF); // white @ 64%
  static const Color textMuted = Color(0x66FFFFFF); // white @ 40%

  static const Color accentFallback = Color(0xFFE8C26A);
  static const Color danger = Color(0xFFFF6B6B);

  // Light theme tokens (v1)
  static const Color lightBg = Color(0xFFF6F5F2);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF14151A);
  static const Color lightTextSecondary = Color(0x9E14151A);
  static const Color lightTextMuted = Color(0x6114151A);
}

abstract final class AppSpacing {
  static const double s4 = 4.0;
  static const double s8 = 8.0;
  static const double s12 = 12.0;
  static const double s16 = 16.0;
  static const double s24 = 24.0;
  static const double s32 = 32.0;
  static const double s48 = 48.0;

  static const double screenPaddingMobile = 28.0;
  static const double screenPaddingDesktop = 32.0;
}

abstract final class AppRadii {
  static const double small = 8.0;
  static const double card = 16.0;
  static const double hero = 28.0;
  static const double sheet = 28.0;
  static const double full = 999.0;

  static const Radius rSmall = Radius.circular(small);
  static const Radius rCard = Radius.circular(card);
  static const Radius rHero = Radius.circular(hero);
  static const Radius rSheet = Radius.circular(sheet);

  static const BorderRadius brSmall = BorderRadius.all(rSmall);
  static const BorderRadius brCard = BorderRadius.all(rCard);
  static const BorderRadius brHero = BorderRadius.all(rHero);
  static const BorderRadius brSheet = BorderRadius.only(
    topLeft: rSheet,
    topRight: rSheet,
  );
  static const BorderRadius brFull = BorderRadius.all(Radius.circular(full));
}

abstract final class AppTypography {
  static const String displayFont = 'Sora';
  static const String bodyFont = 'Inter';

  static const TextStyle display = TextStyle(
    fontFamily: displayFont,
    fontSize: 32.0,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
    height: 1.1,
    color: AppColors.textPrimary,
  );

  static const TextStyle title = TextStyle(
    fontFamily: displayFont,
    fontSize: 20.0,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontFamily: bodyFont,
    fontSize: 15.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontFamily: bodyFont,
    fontSize: 15.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: bodyFont,
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    color: AppColors.textSecondary,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle captionMuted = TextStyle(
    fontFamily: bodyFont,
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    color: AppColors.textMuted,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}

abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration base = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 450);
  static const Duration paletteCrossfade = Duration(milliseconds: 700);

  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve popCurve = Curves.easeOutBack;

  static Duration duration(BuildContext context, Duration standard) {
    if (MediaQuery.of(context).disableAnimations) {
      return standard > const Duration(milliseconds: 80)
          ? const Duration(milliseconds: 80)
          : standard;
    }
    return standard;
  }
}

abstract final class AppBreakpoints {
  static const double compact = 700.0;
  static const double expanded = 1100.0;
}
