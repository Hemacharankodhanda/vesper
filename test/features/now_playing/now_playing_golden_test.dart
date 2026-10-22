import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/audio/audio_providers.dart';
import 'package:vesper/audio/fake_audio_service.dart';
import 'package:vesper/core/theme/app_theme.dart';
import 'package:vesper/data/db/database.dart';
import 'package:vesper/data/repositories/library_repository.dart';
import 'package:vesper/features/now_playing/now_playing_screen.dart';

void main() {
  group('NowPlayingScreen Golden Tests', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('matches golden at phone viewport 390x844', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            audioServiceProvider.overrideWithValue(FakeAudioService()),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            home: const NowPlayingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NowPlayingScreen), findsOneWidget);
      expect(find.text('Low Tide Hours'), findsOneWidget);
      expect(find.text('Marlowe Reyes'), findsOneWidget);
      await expectLater(
        find.byType(NowPlayingScreen),
        matchesGoldenFile('goldens/now_playing_390x844.png'),
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('matches golden at desktop viewport 1280x800', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            audioServiceProvider.overrideWithValue(FakeAudioService()),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            home: const NowPlayingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NowPlayingScreen), findsOneWidget);
      expect(find.text('Low Tide Hours'), findsOneWidget);
      expect(find.text('Marlowe Reyes'), findsOneWidget);
      await expectLater(
        find.byType(NowPlayingScreen),
        matchesGoldenFile('goldens/now_playing_1280x800.png'),
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
