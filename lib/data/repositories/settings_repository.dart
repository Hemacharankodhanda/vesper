import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/queue_state.dart';
import '../../domain/models/track.dart';
import '../db/database.dart' as app_db;
import 'library_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SettingsRepository(database: db);
});

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _load();
    return ThemeMode.dark;
  }

  Future<void> _load() async {
    final repo = ref.read(settingsRepositoryProvider);
    final value = await repo.getSetting(SettingsRepository.keyThemeMode);
    if (value != null) {
      state = switch (value) {
        'light' => ThemeMode.light,
        'system' => ThemeMode.system,
        _ => ThemeMode.dark,
      };
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final repo = ref.read(settingsRepositoryProvider);
    final str = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
      ThemeMode.dark => 'dark',
    };
    await repo.saveSetting(SettingsRepository.keyThemeMode, str);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class AccentModeNotifier extends Notifier<String> {
  @override
  String build() {
    _load();
    return 'art';
  }

  Future<void> _load() async {
    final repo = ref.read(settingsRepositoryProvider);
    final value = await repo.getSetting(SettingsRepository.keyAccentMode);
    if (value != null) {
      state = value;
    }
  }

  Future<void> setAccentMode(String mode) async {
    state = mode;
    final repo = ref.read(settingsRepositoryProvider);
    await repo.saveSetting(SettingsRepository.keyAccentMode, mode);
  }
}

final accentModeProvider = NotifierProvider<AccentModeNotifier, String>(
  AccentModeNotifier.new,
);

class PersistedQueueState {
  const PersistedQueueState({
    required this.trackIds,
    required this.currentIndex,
    required this.positionMs,
    this.shuffle = false,
    this.repeat = AudioRepeatMode.off,
  });

  final List<String> trackIds;
  final int currentIndex;
  final int positionMs;
  final bool shuffle;
  final AudioRepeatMode repeat;

  Map<String, dynamic> toJson() => {
        'trackIds': trackIds,
        'currentIndex': currentIndex,
        'positionMs': positionMs,
        'shuffle': shuffle,
        'repeat': repeat.name,
      };

  factory PersistedQueueState.fromJson(Map<String, dynamic> json) {
    return PersistedQueueState(
      trackIds: (json['trackIds'] as List<dynamic>?)?.cast<String>() ?? [],
      currentIndex: json['currentIndex'] as int? ?? 0,
      positionMs: json['positionMs'] as int? ?? 0,
      shuffle: json['shuffle'] as bool? ?? false,
      repeat: AudioRepeatMode.values.firstWhere(
        (e) => e.name == json['repeat'],
        orElse: () => AudioRepeatMode.off,
      ),
    );
  }
}

class SettingsRepository {
  SettingsRepository({required this.database});

  final app_db.AppDatabase database;

  static const String keyQueueState = 'queue_state';
  static const String keyThemeMode = 'theme_mode';
  static const String keyAccentMode = 'accent_mode';

  Future<void> saveSetting(String key, String value) async {
    await database.into(database.settingsTable).insertOnConflictUpdate(
          app_db.SettingsTableCompanion.insert(key: key, value: value),
        );
  }

  Future<String?> getSetting(String key) async {
    final row = await (database.select(database.settingsTable)
          ..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> saveQueueState(PersistedQueueState state) async {
    final jsonStr = jsonEncode(state.toJson());
    await saveSetting(keyQueueState, jsonStr);
  }

  Future<PersistedQueueState?> loadQueueState() async {
    final raw = await getSetting(keyQueueState);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return PersistedQueueState.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<List<Track>> resolveTracks(List<String> ids, List<Track> fallbackPool) async {
    if (ids.isEmpty) return [];

    // Query DB for known tracks
    final rows = await (database.select(database.tracks)
          ..where((t) => t.id.isIn(ids)))
        .get();

    final dbTracksMap = <String, Track>{
      for (final r in rows)
        r.id: Track(
          id: r.id,
          title: r.title,
          artist: r.albumArtist ?? 'Unknown Artist',
          album: r.albumId ?? 'Unknown Album',
          duration: Duration(milliseconds: r.durationMs),
          path: r.path,
          artHash: r.artHash,
        ),
    };

    final fallbackMap = <String, Track>{
      for (final t in fallbackPool) t.id: t,
    };

    final result = <Track>[];
    for (final id in ids) {
      final t = dbTracksMap[id] ?? fallbackMap[id];
      if (t != null) {
        result.add(t);
      }
    }
    return result;
  }
}
