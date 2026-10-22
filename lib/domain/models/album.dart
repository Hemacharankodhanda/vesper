class Album {
  const Album({
    required this.id,
    required this.title,
    this.albumArtist,
    this.year,
    this.artHash,
    this.artPath,
  });

  final String id;
  final String title;
  final String? albumArtist;
  final int? year;
  final String? artHash;
  final String? artPath;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Album && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
