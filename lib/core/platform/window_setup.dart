import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class WindowSetup {
  static Future<void> initialize() async {
    if (!Platform.isWindows) return;
    try {
      await windowManager.ensureInitialized();
      const windowOptions = WindowOptions(
        size: Size(1000, 720),
        minimumSize: Size(420, 700),
        center: true,
        title: 'Vesper',
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.normal,
      );
      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    } catch (_) {}
  }
}
