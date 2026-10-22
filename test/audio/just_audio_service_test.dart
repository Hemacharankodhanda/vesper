import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/audio/fake_audio_service.dart';
import 'package:vesper/domain/models/queue_state.dart';
import 'package:vesper/domain/models/track.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Audio Service Tests', () {
    test('FakeAudioService initial state matches fakeTracks', () async {
      final service = FakeAudioService();
      addTearDown(() => service.dispose());

      final current = await service.currentTrack.first;
      expect(current, isNotNull);
      expect(current!.title, fakeTracks.first.title);

      final queue = await service.queue.first;
      expect(queue.tracks.length, fakeTracks.length);
      expect(queue.currentIndex, 0);
    });

    test('FakeAudioService next and previous navigate queue', () async {
      final service = FakeAudioService();
      addTearDown(() => service.dispose());

      await service.next();
      final track1 = await service.currentTrack.first;
      expect(track1!.title, fakeTracks[1].title);

      await service.previous();
      final track0 = await service.currentTrack.first;
      expect(track0!.title, fakeTracks[0].title);
    });

    test('FakeAudioService jumpTo updates track and position', () async {
      final service = FakeAudioService();
      addTearDown(() => service.dispose());

      await service.jumpTo(2);
      final track = await service.currentTrack.first;
      expect(track!.title, fakeTracks[2].title);

      final pos = await service.position.first;
      expect(pos, Duration.zero);
    });

    test('FakeAudioService reordering and queue manipulation work', () async {
      final service = FakeAudioService();
      addTearDown(() => service.dispose());

      const newTrack = Track(
        id: 'bonus_1',
        title: 'Bonus Track',
        artist: 'Secret Artist',
        album: 'B-Sides',
        duration: Duration(seconds: 120),
      );

      await service.playNext(newTrack);
      var queue = await service.queue.first;
      expect(queue.tracks[1].id, 'bonus_1');

      await service.removeAt(1);
      queue = await service.queue.first;
      expect(queue.tracks.any((t) => t.id == 'bonus_1'), isFalse);
    });

    test(
      'FakeAudioService repeat and shuffle modes toggle correctly',
      () async {
        final service = FakeAudioService();
        addTearDown(() => service.dispose());

        await service.setShuffle(true);
        var queue = await service.queue.first;
        expect(queue.shuffle, isTrue);

        await service.setRepeat(AudioRepeatMode.one);
        queue = await service.queue.first;
        expect(queue.repeat, AudioRepeatMode.one);
      },
    );
  });
}
