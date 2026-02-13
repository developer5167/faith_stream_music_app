import 'song.dart';

class Playlist {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final String userId;
  final List<Song> songs;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPublic;

  Playlist({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.userId,
    required this.songs,
    required this.createdAt,
    required this.updatedAt,
    this.isPublic = false,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Unnamed Playlist',
      description: json['description'],
      imageUrl: json['image_url'],
      userId: json['user_id']?.toString() ?? '',
      songs:
          (json['songs'] as List<dynamic>?)
              ?.map((song) => Song.fromJson(song))
              .toList() ??
          [],
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
      isPublic: json['is_public'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'user_id': userId,
      'songs': songs.map((song) => song.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_public': isPublic,
    };
  }

  int get songCount => songs.length;

  String get displaySongCount {
    if (songCount == 0) return 'No songs';
    if (songCount == 1) return '1 song';
    return '$songCount songs';
  }

  Playlist copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    String? userId,
    List<Song>? songs,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPublic,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      userId: userId ?? this.userId,
      songs: songs ?? this.songs,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPublic: isPublic ?? this.isPublic,
    );
  }
}
