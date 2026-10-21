import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/app.dart';

void main() {
  testWidgets('VesperApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: VesperApp()));

    expect(find.text('Vesper'), findsOneWidget);
    expect(find.text('Offline Music Player'), findsOneWidget);
  });
}
