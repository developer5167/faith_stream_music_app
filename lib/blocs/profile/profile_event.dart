import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class ProfileLoad extends ProfileEvent {}

class ProfileUpdate extends ProfileEvent {
  final String? name;
  final String? phone;
  final String? bio;
  final String? profilePicUrl;

  const ProfileUpdate({this.name, this.phone, this.bio, this.profilePicUrl});

  @override
  List<Object?> get props => [name, phone, bio, profilePicUrl];
}

class ProfileRequestArtist extends ProfileEvent {
  final String artistName;
  final String? bio;
  final String? govtIdUrl;
  final String? addressProofUrl;
  final String? selfieVideoUrl;
  final List<String>? supportingLinks;

  const ProfileRequestArtist({
    required this.artistName,
    this.bio,
    this.govtIdUrl,
    this.addressProofUrl,
    this.selfieVideoUrl,
    this.supportingLinks,
  });

  @override
  List<Object?> get props => [
    artistName,
    bio,
    govtIdUrl,
    addressProofUrl,
    selfieVideoUrl,
    supportingLinks,
  ];
}

class ProfileCheckArtistStatus extends ProfileEvent {}

class ProfileLoadSubscription extends ProfileEvent {}

class ProfileCreateSubscription extends ProfileEvent {}

class ProfileReset extends ProfileEvent {}
