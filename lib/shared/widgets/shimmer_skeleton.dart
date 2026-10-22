import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

/// Shimmer skeleton row for loading and scanning states. Replaces spinners.
class ShimmerSkeletonRow extends StatefulWidget {
  const ShimmerSkeletonRow({super.key});

  @override
  State<ShimmerSkeletonRow> createState() => _ShimmerSkeletonRowState();
}

class _ShimmerSkeletonRowState extends State<ShimmerSkeletonRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    final isTest = Platform.environment.containsKey('FLUTTER_TEST');
    if (!isTest) {
      _controller.repeat();
    } else {
      _controller.value = 0.5;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity =
            0.08 +
            0.12 *
                (0.5 + 0.5 * (1.0 - (2.0 * (_controller.value - 0.5)).abs()));
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16,
            vertical: AppSpacing.s8,
          ),
          child: Row(
            children: [
              Container(
                width: 56.0,
                height: 56.0,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: opacity),
                  borderRadius: AppRadii.brCard,
                ),
              ),
              const SizedBox(width: AppSpacing.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 160.0,
                      height: 14.0,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: opacity),
                        borderRadius: AppRadii.brSmall,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    Container(
                      width: 100.0,
                      height: 11.0,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: opacity * 0.7),
                        borderRadius: AppRadii.brSmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s16),
              Container(
                width: 36.0,
                height: 11.0,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: opacity * 0.5),
                  borderRadius: AppRadii.brSmall,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
