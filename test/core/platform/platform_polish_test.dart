import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/core/platform/haptics.dart';

void main() {
  test('AppHaptics calls execute cleanly without exception', () {
    expect(() => AppHaptics.light(), returnsNormally);
    expect(() => AppHaptics.selection(), returnsNormally);
    expect(() => AppHaptics.medium(), returnsNormally);
  });
}
