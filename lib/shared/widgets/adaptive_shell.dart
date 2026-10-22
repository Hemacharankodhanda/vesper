import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../audio/audio_providers.dart';
import '../../core/theme/tokens.dart';
import '../../features/home/home_screen.dart';
import '../../features/library/library_screen.dart';
import '../../features/now_playing/now_playing_screen.dart';
import '../../features/search/search_screen.dart';
import 'mini_player.dart';

class AdaptiveShell extends ConsumerStatefulWidget {
  const AdaptiveShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  ConsumerState<AdaptiveShell> createState() => _AdaptiveShellState();
}

class _AdaptiveShellState extends ConsumerState<AdaptiveShell>
    with WidgetsBindingObserver {
  late int _currentIndex;

  final List<Widget> _pages = const [
    HomeScreen(),
    LibraryScreen(),
    SearchScreen(),
    NowPlayingScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(queuePersistenceManagerProvider).restoreState();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      ref.read(queuePersistenceManagerProvider).saveCurrentState();
    }
  }

  void _onSelect(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= AppBreakpoints.compact;
        final showMiniPlayer = _currentIndex != 3;

        if (isDesktop) {
          return Scaffold(
            backgroundColor: AppColors.bg,
            body: Row(
              children: [
                _buildLeftRail(),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: IndexedStack(
                          index: _currentIndex,
                          children: _pages,
                        ),
                      ),
                      if (showMiniPlayer)
                        const MiniPlayer(isDesktop: true),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.bg,
          body: Column(
            children: [
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: _pages,
                ),
              ),
              if (showMiniPlayer)
                const MiniPlayer(isDesktop: false),
            ],
          ),
          bottomNavigationBar: _buildBottomNav(),
        );
      },
    );
  }

  Widget _buildLeftRail() {
    return Container(
      width: 72.0,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: Color(0x1AFFFFFF), width: 1.0)),
      ),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.s24),
          _railItem(0, Icons.home_rounded, 'Home'),
          const SizedBox(height: AppSpacing.s16),
          _railItem(1, Icons.library_music_rounded, 'Library'),
          const SizedBox(height: AppSpacing.s16),
          _railItem(2, Icons.search_rounded, 'Search'),
          const SizedBox(height: AppSpacing.s16),
          _railItem(3, Icons.play_circle_filled_rounded, 'Now Playing'),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _railItem(int index, IconData icon, String tooltip) {
    final isSelected = _currentIndex == index;
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      child: IconButton(
        iconSize: 26.0,
        onPressed: () => _onSelect(index),
        icon: Icon(
          icon,
          color: isSelected ? AppColors.textPrimary : AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.caption.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            );
          }
          return AppTypography.captionMuted;
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: AppColors.textPrimary,
              size: 26.0,
            );
          }
          return const IconThemeData(color: AppColors.textMuted, size: 26.0);
        }),
      ),
      child: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onSelect,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_music_outlined),
            selectedIcon: Icon(Icons.library_music_rounded),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search_rounded),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.play_circle_outline_rounded),
            selectedIcon: Icon(Icons.play_circle_filled_rounded),
            label: 'Now Playing',
          ),
        ],
      ),
    );
  }
}
