import 'package:equatable/equatable.dart';

class Artist extends Equatable {
  final String id;
  final String name;
  final String? bio;
  final String? profilePicUrl;
  final String? bannerImageUrl;
  final int? totalSongs;
  final int? totalAlbums;
  final int? totalStreams;
  final int? totalFollowers;
  final DateTime? createdAt;

  const Artist({
    required this.id,
    required this.name,
    this.bio,
    this.profilePicUrl,
    this.bannerImageUrl,
    this.totalSongs,
    this.totalAlbums,
    this.totalStreams,
    this.totalFollowers,
    this.createdAt,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['id'] as String,
      name: json['name'] as String,
      bio: json['bio'] as String?,
      profilePicUrl: json['profile_image_url'] as String?,
      bannerImageUrl: json['image'] as String?,
      totalSongs: json['total_songs'] as int?,
      totalAlbums: json['total_albums'] as int?,
      totalStreams: json['total_streams'] as int?,
      totalFollowers: json['total_followers'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'bio': bio,
      'profile_image_url': profilePicUrl,
      'image': bannerImageUrl,
      'total_songs': totalSongs,
      'total_albums': totalAlbums,
      'total_streams': totalStreams,
      'total_followers': totalFollowers,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    name,
    bio,
    profilePicUrl,
    bannerImageUrl,
    totalSongs,
    totalAlbums,
    totalStreams,
    totalFollowers,
    createdAt,
  ];

  Artist copyWith({
    String? id,
    String? name,
    String? bio,
    String? profilePicUrl,
    String? bannerImageUrl,
    int? totalSongs,
    int? totalAlbums,
    int? totalStreams,
    int? totalFollowers,
    DateTime? createdAt,
  }) {
    return Artist(
      id: id ?? this.id,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
      bannerImageUrl: bannerImageUrl ?? this.bannerImageUrl,
      totalSongs: totalSongs ?? this.totalSongs,
      totalAlbums: totalAlbums ?? this.totalAlbums,
      totalStreams: totalStreams ?? this.totalStreams,
      totalFollowers: totalFollowers ?? this.totalFollowers,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
