import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/audio/audio_providers.dart';
import 'package:vesper/audio/fake_audio_service.dart';
import 'package:vesper/core/theme/tokens.dart';
import 'package:vesper/data/db/database.dart';
import 'package:vesper/data/repositories/settings_repository.dart';

void main() {
  test('SettingsRepository persists and loads themeMode and accentMode', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final repo = SettingsRepository(database: db);

    await repo.saveSetting(SettingsRepository.keyThemeMode, 'light');
    final loadedTheme = await repo.getSetting(SettingsRepository.keyThemeMode);
    expect(loadedTheme, 'light');

    await repo.saveSetting(SettingsRepository.keyAccentMode, 'fixed');
    final loadedAccent = await repo.getSetting(SettingsRepository.keyAccentMode);
    expect(loadedAccent, 'fixed');

    await db.close();
  });

  test('currentPaletteProvider uses fallback gold when accentMode is fixed', () {
    final container = ProviderContainer(
      overrides: [
        accentModeProvider.overrideWith(() => _FixedAccentNotifier()),
      ],
    );
    addTearDown(container.dispose);

    final palette = container.read(currentPaletteProvider);
    expect(palette.light, AppColors.accentFallback);
  });

  test('sleepTimerProvider sets and cancels timer properly', () {
    final container = ProviderContainer(
      overrides: [
        audioServiceProvider.overrideWithValue(FakeAudioService()),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(sleepTimerProvider), isNull);

    container.read(sleepTimerProvider.notifier).setTimer(const Duration(minutes: 30));
    expect(container.read(sleepTimerProvider), const Duration(minutes: 30));

    container.read(sleepTimerProvider.notifier).cancel();
    expect(container.read(sleepTimerProvider), isNull);
  });
}

class _FixedAccentNotifier extends AccentModeNotifier {
  @override
  String build() => 'fixed';
}
