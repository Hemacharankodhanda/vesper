import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/shared/widgets/play_button.dart';

void main() {
  group('PlayButton Widget Tests', () {
    testWidgets('shows play icon and semantics when paused', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PlayButton(
                playing: false,
                color: Colors.black,
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(find.byIcon(Icons.pause_rounded), findsNothing);
      expect(find.bySemanticsLabel('Play'), findsOneWidget);

      await tester.tap(find.byKey(const Key('play_button_tap')));
      expect(tapped, isTrue);
    });

    testWidgets('shows pause icon and semantics when playing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PlayButton(
                playing: true,
                color: Colors.black,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
      expect(find.bySemanticsLabel('Pause'), findsOneWidget);
    });
  });
}
