import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/tokens.dart';

class VesperApp extends ConsumerWidget {
  const VesperApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vesper',
      theme: AppTheme.darkTheme,
      home: const VesperHomeScreen(),
    );
  }
}

class VesperHomeScreen extends StatelessWidget {
  const VesperHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Vesper', style: AppTypography.display),
              const SizedBox(height: AppSpacing.s8),
              Text('Offline Music Player', style: AppTypography.bodySecondary),
            ],
          ),
        ),
      ),
    );
  }
}
