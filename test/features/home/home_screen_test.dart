import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/core/theme/app_theme.dart';
import 'package:vesper/data/repositories/library_repository.dart';
import 'package:vesper/domain/models/track.dart';
import 'package:vesper/features/home/home_screen.dart';

void main() {
  testWidgets('HomeScreen renders continue listening, recently added and played', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          libraryTracksProvider.overrideWith((ref) => Stream.value(fakeTracks)),
          recentlyAddedProvider.overrideWith((ref) => Stream.value(fakeTracks)),
          recentlyPlayedProvider.overrideWith((ref) => Stream.value(fakeTracks)),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Listen Now'), findsOneWidget);
    expect(find.text('CONTINUE LISTENING'), findsOneWidget);
    expect(find.text('Recently added'), findsOneWidget);
    expect(find.text('Recently played'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
