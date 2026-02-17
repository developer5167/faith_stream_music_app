import 'package:equatable/equatable.dart';

class Album extends Equatable {
  final String id;
  final String title;
  final String? description;
  final String? language;
  final String? releaseType;
  final String? coverImageUrl;
  final String? artistName;
  final String? artistDisplayName;
  final DateTime? createdAt;

  const Album({
    required this.id,
    required this.title,
    this.description,
    this.language,
    this.releaseType,
    this.coverImageUrl,
    this.artistName,
    this.artistDisplayName,
    this.createdAt,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    String? coverImage = (json['cover_image_url'] ?? json['image']) as String?;
    if (coverImage != null && coverImage.trim().isEmpty) coverImage = null;

    return Album(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? 'Unknown Album').toString(),
      description: json['description'] as String?,
      language: json['language'] as String?,
      releaseType: json['release_type'] as String?,
      coverImageUrl: coverImage,
      artistName: json['artist_name'] as String?,
      artistDisplayName: json['artist_display_name'] as String?,
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
      'language': language,
      'release_type': releaseType,
      'image': coverImageUrl,
      'artist_name': artistName,
      'artist_display_name': artistDisplayName,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  String get displayArtist =>
      artistDisplayName ?? artistName ?? 'Unknown Artist';

  String get displayDate {
    if (createdAt == null) return 'Unknown Date';
    return '${createdAt!.day}/${createdAt!.month}/${createdAt!.year}';
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    language,
    releaseType,
    coverImageUrl,
    artistName,
    artistDisplayName,
    createdAt,
  ];
}
