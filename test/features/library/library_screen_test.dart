import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/core/theme/app_theme.dart';
import 'package:vesper/data/repositories/library_repository.dart';
import 'package:vesper/domain/models/album.dart';
import 'package:vesper/domain/models/artist.dart';
import 'package:vesper/domain/models/track.dart';
import 'package:vesper/features/library/library_screen.dart';

void main() {
  testWidgets(
    'LibraryScreen renders segmented tabs and switches between them',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final testAlbums = [
        const Album(
          id: 'album_1',
          title: 'Salt & Static',
          albumArtist: 'Marlowe Reyes',
        ),
      ];
      final testArtists = [const Artist(id: 'artist_1', name: 'Marlowe Reyes')];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            libraryTracksProvider.overrideWith(
              (ref) => Stream.value(fakeTracks),
            ),
            libraryAlbumsProvider.overrideWith(
              (ref) => Stream.value(testAlbums),
            ),
            libraryArtistsProvider.overrideWith(
              (ref) => Stream.value(testArtists),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const LibraryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Library'), findsOneWidget);
      expect(find.text('Songs'), findsOneWidget);
      expect(find.text('Albums'), findsOneWidget);
      expect(find.text('Artists'), findsOneWidget);
      expect(find.text('Playlists'), findsOneWidget);

      // Initial tab is Songs, fakeTracks should be present
      expect(find.text('Low Tide Hours'), findsOneWidget);

      // Switch to Albums tab
      await tester.tap(find.text('Albums'));
      await tester.pumpAndSettle();
      expect(find.text('Salt & Static'), findsOneWidget);

      // Switch to Artists tab
      await tester.tap(find.text('Artists'));
      await tester.pumpAndSettle();
      expect(find.text('Marlowe Reyes'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    },
  );
}
