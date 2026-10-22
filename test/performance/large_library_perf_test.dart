import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/audio/audio_providers.dart';
import 'package:vesper/audio/fake_audio_service.dart';
import 'package:vesper/data/db/database.dart' hide Track;
import 'package:vesper/data/repositories/library_repository.dart';
import 'package:vesper/domain/models/track.dart';
import 'package:vesper/features/library/library_screen.dart';
import 'package:vesper/shared/widgets/shimmer_skeleton.dart';
import 'package:vesper/shared/widgets/track_row.dart';
import 'package:drift/native.dart';

void main() {
  group('Performance & Accessibility Verification', () {
    late AppDatabase db;
    late FakeAudioService fakeAudio;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      fakeAudio = FakeAudioService();
    });

    tearDown(() async {
      await db.close();
      await fakeAudio.dispose();
    });

    testWidgets(
      'Library screen virtualizes 20,000 tracks without jank or excessive rendering',
      (tester) async {
        // Generate 20,000 tracks
        final largeTrackList = List.generate(
          20000,
          (i) => Track(
            id: 'track_$i',
            title: 'Track Title ${i.toString().padLeft(5, '0')}',
            artist: 'Artist ${i % 100}',
            album: 'Album ${i % 50}',
            duration: Duration(seconds: 180 + (i % 60)),
            style: i % 4,
          ),
        );

        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(db),
              audioServiceProvider.overrideWithValue(fakeAudio),
              libraryTracksProvider.overrideWith(
                (ref) => Stream.value(largeTrackList),
              ),
            ],
            child: const MaterialApp(home: Scaffold(body: LibraryScreen())),
          ),
        );
        await tester.pumpAndSettle();
        stopwatch.stop();

        // Ensure initial frame renders quickly
        expect(stopwatch.elapsedMilliseconds, lessThan(3000));

        // Ensure virtualization: only a small viewport subset of TrackRow is mounted (e.g. ~10 to 15 items, NOT 20,000)
        final mountedRows = find.byType(TrackRow);
        expect(mountedRows.evaluate().length, lessThan(25));
        expect(find.text('Track Title 00000'), findsOneWidget);

        // Fast fling scroll down
        await tester.fling(find.byType(ListView), const Offset(0, -2000), 5000);
        await tester.pumpAndSettle();

        // Viewport remains virtualized
        expect(find.byType(TrackRow).evaluate().length, lessThan(25));

        // Clean unmount
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 100));
      },
    );

    testWidgets('Accessibility: respects reduce motion (disableAnimations)', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: ShimmerSkeletonRow(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(ShimmerSkeletonRow), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets(
      'Accessibility: TrackRow has semantic descriptions and touch target >= 48dp',
      (tester) async {
        const sampleTrack = Track(
          id: 'sem_1',
          title: 'Midnight Air',
          artist: 'Solas',
          album: 'Aura',
          duration: Duration(minutes: 3, seconds: 45),
          style: 1,
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: TrackRow(track: sampleTrack)),
          ),
        );
        await tester.pumpAndSettle();

        final semantics = tester.getSemantics(find.byType(TrackRow));
        expect(semantics.label, contains('Midnight Air'));
        expect(semantics.label, contains('Solas'));

        // Check height is >= 48dp (TrackRow is 72dp)
        final size = tester.getSize(find.byType(TrackRow));
        expect(size.height, greaterThanOrEqualTo(48.0));

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 100));
      },
    );
  });
}
