import 'package:flutter/material.dart';

class Track {
  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    this.style = 0,
    this.palette = const [
      Color(0xFF0E0F12),
      Color(0xFF16181D),
      Color(0xFFE8C26A),
    ],
    this.path,
    this.artPath,
    this.artHash,
  });

  final String id;
  final String title;
  final String artist;
  final String album;
  final Duration duration;
  final int style;
  final List<Color> palette;
  final String? path;
  final String? artPath;
  final String? artHash;

  int get seconds => duration.inSeconds;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Track && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Fake tracks for development, prototyping, and tests.
const fakeTracks = <Track>[
  Track(
    id: 'track_1',
    title: 'Low Tide Hours',
    artist: 'Marlowe Reyes',
    album: 'Salt & Static',
    duration: Duration(seconds: 214),
    style: 0,
    palette: [Color(0xFF0B2A3A), Color(0xFF1F6F8B), Color(0xFFF2C14E)],
  ),
  Track(
    id: 'track_2',
    title: 'Paper Lanterns',
    artist: 'Ione Vask',
    album: 'Small Weather',
    duration: Duration(seconds: 187),
    style: 1,
    palette: [Color(0xFF3A1230), Color(0xFFB8336A), Color(0xFFFFC8A2)],
  ),
  Track(
    id: 'track_3',
    title: 'Concrete Garden',
    artist: 'The Quiet Hours',
    album: 'Field Notes',
    duration: Duration(seconds: 241),
    style: 2,
    palette: [Color(0xFF14301F), Color(0xFF3E8E5A), Color(0xFFE9E4B0)],
  ),
  Track(
    id: 'track_4',
    title: 'Slow Horizon',
    artist: 'Aarav Menon',
    album: 'Dusk Frequencies',
    duration: Duration(seconds: 203),
    style: 3,
    palette: [Color(0xFF241B4B), Color(0xFF6C4CD1), Color(0xFFFF9A6B)],
  ),
  Track(
    id: 'track_5',
    title: 'Glasshouse',
    artist: 'Nell & Orrin',
    album: 'Pale Fire',
    duration: Duration(seconds: 176),
    style: 0,
    palette: [Color(0xFF2B2B2B), Color(0xFF8A8D91), Color(0xFFE8E2D4)],
  ),
];
