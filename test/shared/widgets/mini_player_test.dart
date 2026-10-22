import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/audio/audio_providers.dart';
import 'package:vesper/audio/fake_audio_service.dart';
import 'package:vesper/core/theme/app_theme.dart';
import 'package:vesper/domain/models/track.dart';
import 'package:vesper/shared/widgets/mini_player.dart';

void main() {
  testWidgets('MiniPlayer displays track info and responds to play toggle', (
    tester,
  ) async {
    final fakeAudio = FakeAudioService();
    await fakeAudio.setQueue(fakeTracks, index: 0, play: false);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [audioServiceProvider.overrideWithValue(fakeAudio)],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(body: MiniPlayer(isDesktop: false)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Low Tide Hours'), findsOneWidget);
    expect(find.text('Marlowe Reyes'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

    // Tap play
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

    // Clean up
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
    await fakeAudio.dispose();
  });
}
