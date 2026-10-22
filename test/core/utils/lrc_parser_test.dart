import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/core/utils/lrc_parser.dart';

void main() {
  group('LrcParser Tests', () {
    test('parses timestamps and lines with milliseconds precision', () {
      const lrcContent = '''
[00:12.30]First line of the song
[01:05.80]Second line with chorus
[00:45.00]Pre-chorus line out of order
''';

      final lines = LrcParser.parse(lrcContent);

      expect(lines.length, 3);
      // Verify sorted order
      expect(lines[0].text, 'First line of the song');
      expect(
        lines[0].timestamp,
        const Duration(seconds: 12, milliseconds: 300),
      );

      expect(lines[1].text, 'Pre-chorus line out of order');
      expect(lines[1].timestamp, const Duration(seconds: 45));

      expect(lines[2].text, 'Second line with chorus');
      expect(
        lines[2].timestamp,
        const Duration(minutes: 1, seconds: 5, milliseconds: 800),
      );
    });

    test('ignores non-timestamp tags and empty lines', () {
      const lrcContent = '''
[ti:Low Tide Hours]
[ar:Marlowe Reyes]

[00:05.00]Instrumental intro
''';

      final lines = LrcParser.parse(lrcContent);
      expect(lines.length, 1);
      expect(lines.first.text, 'Instrumental intro');
      expect(lines.first.timestamp, const Duration(seconds: 5));
    });
  });
}
