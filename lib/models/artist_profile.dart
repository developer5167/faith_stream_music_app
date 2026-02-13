import 'package:equatable/equatable.dart';

class ArtistProfile extends Equatable {
  final String userId;
  final String artistName;
  final String? bio;
  final String? profilePicUrl;
  final String? govtIdUrl;
  final String? addressProofUrl;
  final int totalStreams;
  final double totalEarnings;

  const ArtistProfile({
    required this.userId,
    required this.artistName,
    this.bio,
    this.profilePicUrl,
    this.govtIdUrl,
    this.addressProofUrl,
    this.totalStreams = 0,
    this.totalEarnings = 0.0,
  });

  factory ArtistProfile.fromJson(Map<String, dynamic> json) {
    return ArtistProfile(
      userId: json['user_id'].toString(),
      artistName: json['artist_name'] ?? '',
      bio: json['bio'],
      profilePicUrl: json['profile_pic_url'],
      govtIdUrl: json['govt_id_url'],
      addressProofUrl: json['address_proof_url'],
      totalStreams: json['total_streams'] ?? 0,
      totalEarnings: (json['total_earnings'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'artist_name': artistName,
      'bio': bio,
      'profile_pic_url': profilePicUrl,
      'govt_id_url': govtIdUrl,
      'address_proof_url': addressProofUrl,
      'total_streams': totalStreams,
      'total_earnings': totalEarnings,
    };
  }

  @override
  List<Object?> get props => [
    userId,
    artistName,
    bio,
    profilePicUrl,
    govtIdUrl,
    addressProofUrl,
    totalStreams,
    totalEarnings,
  ];
}
