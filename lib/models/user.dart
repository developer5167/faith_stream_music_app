import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? bio;
  final String? profilePicUrl;
  final String? artistStatus;
  final bool isAdmin;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.bio,
    this.profilePicUrl,
    this.artistStatus,
    this.isAdmin = false,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    String? profilePic = json['profile_pic_url'] as String?;
    if (profilePic != null && profilePic.trim().isEmpty) profilePic = null;

    return User(
      id: json['id'].toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: json['phone'] as String?,
      bio: json['bio'] as String?,
      profilePicUrl: profilePic,
      artistStatus: json['artist_status'] as String?,
      isAdmin: json['is_admin'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'bio': bio,
      'profile_pic_url': profilePicUrl,
      'artist_status': artistStatus,
      'is_admin': isAdmin,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? bio,
    String? profilePicUrl,
    String? artistStatus,
    bool? isAdmin,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
      artistStatus: artistStatus ?? this.artistStatus,
      isAdmin: isAdmin ?? this.isAdmin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isArtist => artistStatus == 'APPROVED';
  bool get isArtistPending => artistStatus == 'REQUESTED';

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    phone,
    bio,
    profilePicUrl,
    artistStatus,
    isAdmin,
    createdAt,
    updatedAt,
  ];
}
