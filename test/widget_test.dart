import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/app.dart';
import 'package:vesper/data/repositories/library_repository.dart';
import 'package:vesper/domain/models/track.dart';
import 'package:vesper/features/now_playing/now_playing_screen.dart';

void main() {
  testWidgets('VesperApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          libraryTracksProvider.overrideWith((ref) => Stream.value(fakeTracks)),
          recentlyAddedProvider.overrideWith((ref) => Stream.value(fakeTracks)),
          recentlyPlayedProvider.overrideWith(
            (ref) => Stream.value(fakeTracks),
          ),
        ],
        child: const VesperApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NowPlayingScreen), findsOneWidget);
    expect(find.text('Low Tide Hours'), findsOneWidget);
    expect(find.text('Marlowe Reyes'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
