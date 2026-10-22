import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/empty_state.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: EmptyState(
          message: 'No songs found in local folders',
          actionLabel: 'Add Folder',
        ),
      ),
    );
  }
}
