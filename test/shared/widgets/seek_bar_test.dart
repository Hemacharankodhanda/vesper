import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/shared/widgets/seek_bar.dart';

void main() {
  group('SeekBar Widget Tests', () {
    testWidgets('renders elapsed and remaining times accurately', (
      tester,
    ) async {
      double? seekedFraction;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: SeekBar(
                  position: const Duration(seconds: 45),
                  length: const Duration(seconds: 180),
                  onSeek: (f) => seekedFraction = f,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('0:45'), findsOneWidget);
      expect(find.text('-2:15'), findsOneWidget);
      expect(seekedFraction, isNull);
    });

    testWidgets('tapping seek bar triggers onSeek with computed fraction', (
      tester,
    ) async {
      double? seekedFraction;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                child: SeekBar(
                  position: Duration.zero,
                  length: const Duration(seconds: 200),
                  onSeek: (f) => seekedFraction = f,
                ),
              ),
            ),
          ),
        ),
      );

      final gestureFinder = find.byKey(const Key('seek_bar_gesture_detector'));
      expect(gestureFinder, findsOneWidget);

      // Tap in the middle (50%)
      await tester.tap(gestureFinder);
      await tester.pumpAndSettle();

      expect(seekedFraction, isNotNull);
      expect(seekedFraction!, closeTo(0.5, 0.05));
    });

    testWidgets('horizontal drag updates seek bar and commits on end', (
      tester,
    ) async {
      double? seekedFraction;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                child: SeekBar(
                  position: Duration.zero,
                  length: const Duration(seconds: 100),
                  onSeek: (f) => seekedFraction = f,
                ),
              ),
            ),
          ),
        ),
      );

      final gestureFinder = find.byKey(const Key('seek_bar_gesture_detector'));

      // Drag across gesture detector
      await tester.drag(gestureFinder, const Offset(60, 0));
      await tester.pumpAndSettle();

      expect(seekedFraction, isNotNull);
    });
  });
}
