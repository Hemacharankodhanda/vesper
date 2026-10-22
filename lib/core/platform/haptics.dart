import 'dart:io';
import 'package:flutter/services.dart';

class AppHaptics {
  static void light() {
    try {
      if (Platform.isAndroid) {
        HapticFeedback.lightImpact();
      }
    } catch (_) {}
  }

  static void selection() {
    try {
      if (Platform.isAndroid) {
        HapticFeedback.selectionClick();
      }
    } catch (_) {}
  }

  static void medium() {
    try {
      if (Platform.isAndroid) {
        HapticFeedback.mediumImpact();
      }
    } catch (_) {}
  }
}
