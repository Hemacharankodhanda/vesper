import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/platform/keyboard_shortcuts.dart';
import 'core/theme/app_theme.dart';
import 'shared/widgets/adaptive_shell.dart';

class VesperApp extends ConsumerWidget {
  const VesperApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vesper',
      theme: AppTheme.darkTheme,
      home: const VesperKeyboardShortcuts(
        child: AdaptiveShell(initialIndex: 3),
      ),
    );
  }
}
