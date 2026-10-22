import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/platform/keyboard_shortcuts.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/settings_repository.dart';
import 'shared/widgets/adaptive_shell.dart';

class VesperApp extends ConsumerWidget {
  const VesperApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vesper',
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const VesperKeyboardShortcuts(
        child: AdaptiveShell(initialIndex: 3),
      ),
    );
  }
}
