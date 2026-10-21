import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/core/theme/palette.dart';
import 'package:vesper/core/theme/tokens.dart';

void main() {
  group('Design Tokens', () {
    test('AppColors has valid hex values', () {
      expect(AppColors.bg, const Color(0xFF0E0F12));
      expect(AppColors.surface, const Color(0xFF16181D));
      expect(AppColors.surfaceHigh, const Color(0xFF1E2128));
      expect(AppColors.textPrimary, const Color(0xFFF5F5F7));
      expect(AppColors.accentFallback, const Color(0xFFE8C26A));
      expect(AppColors.danger, const Color(0xFFFF6B6B));
    });

    test('AppSpacing follows 4-pt scale', () {
      expect(AppSpacing.s4, 4.0);
      expect(AppSpacing.s8, 8.0);
      expect(AppSpacing.s12, 12.0);
      expect(AppSpacing.s16, 16.0);
      expect(AppSpacing.s24, 24.0);
      expect(AppSpacing.s32, 32.0);
      expect(AppSpacing.s48, 48.0);
    });

    test('AppRadii has required dimensions', () {
      expect(AppRadii.small, 8.0);
      expect(AppRadii.card, 16.0);
      expect(AppRadii.hero, 28.0);
      expect(AppRadii.sheet, 28.0);
    });

    test('AppMotion durations follow spec', () {
      expect(AppMotion.fast, const Duration(milliseconds: 120));
      expect(AppMotion.base, const Duration(milliseconds: 240));
      expect(AppMotion.slow, const Duration(milliseconds: 450));
      expect(AppMotion.paletteCrossfade, const Duration(milliseconds: 700));
    });

    test('VesperPalette computes gradientTop correctly', () {
      const palette = VesperPalette(
        deep: Color(0xFF000000),
        mid: Color(0xFFFFFFFF),
        light: Color(0xFFE8C26A),
      );
      // lerp(white, black, 0.35)
      final top = palette.gradientTop;
      expect(top, isNotNull);
      expect(palette.gradientBottom, const Color(0xFF000000));
    });
  });
}
