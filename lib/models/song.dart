import 'package:equatable/equatable.dart';
import 'package:faith_stream_music_app/models/artist.dart'; // Import Artist model

class Song extends Equatable {
  final String id;
  final String title;
  final String? description;
  final String? genre;
  final String? language;
  final String? audioUrl;
  final String? coverImageUrl;
  final String? albumTitle;
  final String? artistUserId; // Add artistUserId
  final String? artistName;
  final String? artistDisplayName;
  final Artist? artist; // Add Artist object
  final String? streamCount;
  final DateTime? createdAt;

  const Song({
    required this.id,
    required this.title,
    this.description,
    this.genre,
    this.language,
    this.audioUrl,
    this.coverImageUrl,
    this.albumTitle,
    this.artistUserId,
    this.artistName,
    this.artistDisplayName,
    this.artist,
    this.streamCount,
    this.createdAt,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      genre: json['genre'] as String?,
      language: json['language'] as String?,
      audioUrl: json['audio_original_url'] as String?,
      // Some APIs return cover image as `cover_image_url`, others as `image`.
      // Prefer `cover_image_url` but gracefully fall back to `image`.
      coverImageUrl: (json['cover_image_url'] ?? json['image']) as String?,
      albumTitle: json['album_title'] as String?,
      artistUserId: json['artist_user_id'] as String?, // Parse artist_user_id
      // Prefer explicit artist fields when present (e.g. home/popular/recently-played APIs),
      // while still working for album tracks where they may be absent.
      artistName: json['artist_name'] as String?,
      artistDisplayName: json['artist_display_name'] as String?,
      artist: json['artist'] != null ? Artist.fromJson(json['artist']) : null, // Parse nested artist
      streamCount: json['stream_count']?.toString() ?? "0",
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'genre': genre,
      'language': language,
      'audio_original_url': audioUrl,
      'cover_image_url': coverImageUrl,
      'album_title': albumTitle,
      'artist_user_id': artistUserId,
      'artist_name': artistName, // Keep for other APIs that might use it
      'artist_display_name': artistDisplayName, // Keep for other APIs that might use it
      'artist': artist?.toJson(),
      'stream_count': streamCount,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  // Helper for consistent artist display name
  String get displayArtist =>
      artist?.name ?? artistDisplayName ?? artistName ?? artistUserId ?? 'Unknown Artist';

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    genre,
    language,
    audioUrl,
    coverImageUrl,
    albumTitle,
    artistUserId,
    artistName,
    artistDisplayName,
    artist,
    streamCount,
    createdAt,
  ];

  Song copyWith({
    String? id,
    String? title,
    String? description,
    String? genre,
    String? language,
    String? audioUrl,
    String? coverImageUrl,
    String? albumTitle,
    String? artistUserId,
    String? artistName,
    String? artistDisplayName,
    Artist? artist,
    String? streamCount,
    DateTime? createdAt,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      genre: genre ?? this.genre,
      language: language ?? this.language,
      audioUrl: audioUrl ?? this.audioUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      albumTitle: albumTitle ?? this.albumTitle,
      artistUserId: artistUserId ?? this.artistUserId,
      artistName: artistName ?? this.artistName,
      artistDisplayName: artistDisplayName ?? this.artistDisplayName,
      artist: artist ?? this.artist,
      streamCount: streamCount ?? this.streamCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
