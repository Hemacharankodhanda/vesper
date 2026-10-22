import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/app.dart';
import 'package:vesper/features/now_playing/now_playing_screen.dart';

void main() {
  testWidgets('VesperApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: VesperApp()));
    await tester.pumpAndSettle();

    expect(find.byType(NowPlayingScreen), findsOneWidget);
    expect(find.text('Low Tide Hours'), findsOneWidget);
    expect(find.text('Marlowe Reyes'), findsOneWidget);
  });
}
