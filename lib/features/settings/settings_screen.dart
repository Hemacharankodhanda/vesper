import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../audio/audio_providers.dart';
import '../../core/platform/folder_picker.dart';
import '../../core/theme/tokens.dart';
import '../../data/repositories/library_repository.dart';
import '../../data/repositories/settings_repository.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _pickFolder(WidgetRef ref) async {
    final path = await FolderPickerService.pickFolder();
    if (path != null) {
      final repo = ref.read(libraryRepositoryProvider);
      await repo.addFolder(path);
      repo.scanAllFolders().listen((_) {});
    }
  }

  void _showSleepTimerPicker(BuildContext context, WidgetRef ref) {
    final sleepTimerNotifier = ref.read(sleepTimerProvider.notifier);
    final activeTimer = ref.read(sleepTimerProvider);

    final options = <String, Duration?>{
      'Turn off': null,
      '15 minutes': const Duration(minutes: 15),
      '30 minutes': const Duration(minutes: 30),
      '45 minutes': const Duration(minutes: 45),
      '60 minutes': const Duration(minutes: 60),
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.sheet),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Sleep Timer', style: AppTypography.title),
            const SizedBox(height: AppSpacing.s12),
            ...options.entries.map((entry) {
              final isSelected =
                  (entry.value == null && activeTimer == null) ||
                  (entry.value != null &&
                      activeTimer != null &&
                      (activeTimer.inMinutes - entry.value!.inMinutes).abs() <=
                          1);

              return ListTile(
                title: Text(entry.key, style: AppTypography.body),
                trailing: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        color: AppColors.accentFallback,
                      )
                    : null,
                onTap: () {
                  sleepTimerNotifier.setTimer(entry.value);
                  Navigator.of(ctx).pop();
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(libraryFoldersProvider);
    final themeMode = ref.watch(themeModeProvider);
    final accentMode = ref.watch(accentModeProvider);
    final sleepTimer = ref.watch(sleepTimerProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPaddingMobile,
            vertical: AppSpacing.s16,
          ),
          children: [
            Text('Settings', style: AppTypography.display),
            const SizedBox(height: AppSpacing.s24),

            // 1. Music Folders
            _sectionHeader('MUSIC FOLDERS'),
            foldersAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const Text('Could not load folders'),
              data: (folders) {
                return Column(
                  children: [
                    ...folders.map(
                      (path) => Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.s8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppRadii.brCard,
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.folder_outlined,
                            color: AppColors.accentFallback,
                          ),
                          title: Text(
                            path,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption,
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: AppColors.danger,
                            ),
                            onPressed: () => ref
                                .read(libraryRepositoryProvider)
                                .removeFolder(path),
                          ),
                        ),
                      ),
                    ),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadii.brCard,
                      ),
                      tileColor: AppColors.surface,
                      leading: const Icon(
                        Icons.add_rounded,
                        color: AppColors.textPrimary,
                      ),
                      title: Text(
                        'Add Music Folder',
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () => _pickFolder(ref),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: AppSpacing.s32),

            // 2. Appearance
            _sectionHeader('APPEARANCE'),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadii.brCard,
              ),
              child: Column(
                children: [
                  ListTile(
                    title: Text('Theme', style: AppTypography.body),
                    trailing: DropdownButton<ThemeMode>(
                      value: themeMode,
                      dropdownColor: AppColors.surfaceHigh,
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Text('Dark'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Text('Light'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Text('System'),
                        ),
                      ],
                      onChanged: (mode) {
                        if (mode != null) {
                          ref
                              .read(themeModeProvider.notifier)
                              .setThemeMode(mode);
                        }
                      },
                    ),
                  ),
                  const Divider(height: 1.0, color: Color(0x1AFFFFFF)),
                  ListTile(
                    title: Text('Accent Color', style: AppTypography.body),
                    trailing: DropdownButton<String>(
                      value: accentMode,
                      dropdownColor: AppColors.surfaceHigh,
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(
                          value: 'art',
                          child: Text('Dynamic (Album Art)'),
                        ),
                        DropdownMenuItem(
                          value: 'fixed',
                          child: Text('Fixed (Gold)'),
                        ),
                      ],
                      onChanged: (mode) {
                        if (mode != null) {
                          ref
                              .read(accentModeProvider.notifier)
                              .setAccentMode(mode);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.s32),

            // 3. Playback
            _sectionHeader('PLAYBACK'),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadii.brCard,
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.timer_outlined,
                  color: AppColors.textSecondary,
                ),
                title: Text('Sleep Timer', style: AppTypography.body),
                subtitle: Text(
                  sleepTimer != null
                      ? '${sleepTimer.inMinutes} minutes remaining'
                      : 'Off',
                  style: AppTypography.captionMuted,
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                ),
                onTap: () => _showSleepTimerPicker(context, ref),
              ),
            ),

            const SizedBox(height: AppSpacing.s32),

            // 4. About
            _sectionHeader('ABOUT'),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadii.brCard,
              ),
              padding: const EdgeInsets.all(AppSpacing.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vesper',
                    style: AppTypography.title.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    'Version 1.0.0 (v1 Release)',
                    style: AppTypography.captionMuted,
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    'Offline music player for Android and Windows. Tactile, minimal, dark-first audio experience with zero tracking and zero network calls.',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 96.0),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppSpacing.s8,
        left: AppSpacing.s4,
      ),
      child: Text(
        title,
        style: AppTypography.captionMuted.copyWith(
          letterSpacing: 0.8,
          fontWeight: FontWeight.w600,
          fontSize: 11.0,
        ),
      ),
    );
  }
}
