class Playlist {
  const Playlist({
    required this.id,
    required this.name,
    required this.createdAt,
    this.trackCount = 0,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final int trackCount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Playlist && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
