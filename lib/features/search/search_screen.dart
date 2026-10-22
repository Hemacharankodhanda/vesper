import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/empty_state.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: EmptyState(message: 'Search across songs, albums, and artists'),
      ),
    );
  }
}
