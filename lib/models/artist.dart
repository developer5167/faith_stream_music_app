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
  final bool? isFollowing;
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
    this.isFollowing,
    this.createdAt,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    String? profilePic =
        (json['profile_pic_url'] ?? json['profile_image_url'] ?? json['image'])
            as String?;
    String? bannerImage =
        (json['banner_image_url'] ??
                json['banner_url'] ??
                json['cover_image_url'])
            as String?;

    if (profilePic != null && profilePic.trim().isEmpty) profilePic = null;
    if (bannerImage != null && bannerImage.trim().isEmpty) bannerImage = null;

    return Artist(
      id: (json['id'] ?? json['artist_user_id'] ?? '').toString(),
      name: (json['name'] ?? json['artist_name'] ?? 'Unknown Artist')
          .toString(),
      bio: json['bio'] as String?,
      profilePicUrl: profilePic ?? bannerImage,
      bannerImageUrl: bannerImage ?? profilePic,
      totalSongs: parseInt(json['song_count'] ?? json['total_songs']),
      totalAlbums: parseInt(json['album_count'] ?? json['total_albums']),
      totalStreams: parseInt(json['total_streams']),
      totalFollowers: parseInt(
        json['total_followers'] ?? json['follower_count'],
      ),
      isFollowing: json['is_following'] as bool?,
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
      'profile_pic_url': profilePicUrl,
      'profile_image_url': profilePicUrl,
      'image': profilePicUrl,
      'banner_image_url': bannerImageUrl,
      'banner_url': bannerImageUrl,
      'total_songs': totalSongs,
      'total_albums': totalAlbums,
      'total_streams': totalStreams,
      'total_followers': totalFollowers,
      'is_following': isFollowing,
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
    isFollowing,
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
    bool? isFollowing,
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
      isFollowing: isFollowing ?? this.isFollowing,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
