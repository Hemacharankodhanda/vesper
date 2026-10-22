import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/audio/audio_providers.dart';
import 'package:vesper/audio/fake_audio_service.dart';
import 'package:vesper/core/platform/keyboard_shortcuts.dart';
import 'package:vesper/domain/models/track.dart';

void main() {
  testWidgets('VesperKeyboardShortcuts responds to Space and Arrow keys', (tester) async {
    final fakeAudio = FakeAudioService();
    await fakeAudio.setQueue(fakeTracks, index: 0, play: false);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioServiceProvider.overrideWithValue(fakeAudio),
        ],
        child: MaterialApp(
          home: VesperKeyboardShortcuts(
            child: Scaffold(
              body: Container(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial playback state
    expect(await fakeAudio.playing.first, isFalse);

    // Press Space key -> toggle play
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(await fakeAudio.playing.first, isTrue);

    // Press Right arrow -> next track
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    final queue1 = await fakeAudio.queue.first;
    expect(queue1.currentIndex, 1);

    // Press Left arrow -> previous track
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    final queue2 = await fakeAudio.queue.first;
    expect(queue2.currentIndex, 0);

    // Clean up
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
    await fakeAudio.dispose();
  });
}
