import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/empty_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: EmptyState(
          message: 'Your music will appear here',
          actionLabel: 'Scan Library',
        ),
      ),
    );
  }
}
