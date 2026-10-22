class LrcLine {
  const LrcLine({required this.timestamp, required this.text});
  final Duration timestamp;
  final String text;
}

class LrcParser {
  static final RegExp _tagRegex = RegExp(
    r'\[(\d{1,2}):(\d{2})(?:\.(\d{1,3}))?\]',
  );

  static List<LrcLine> parse(String content) {
    final lines = <LrcLine>[];
    for (final rawLine in content.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      final match = _tagRegex.firstMatch(line);
      if (match != null) {
        final min = int.tryParse(match.group(1) ?? '0') ?? 0;
        final sec = int.tryParse(match.group(2) ?? '0') ?? 0;
        final msStr = match.group(3) ?? '0';
        final ms = int.tryParse(msStr.padRight(3, '0').substring(0, 3)) ?? 0;

        final duration = Duration(minutes: min, seconds: sec, milliseconds: ms);
        final text = line.replaceFirst(_tagRegex, '').trim();
        lines.add(LrcLine(timestamp: duration, text: text));
      }
    }
    lines.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return lines;
  }
}
