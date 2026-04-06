import 'package:equatable/equatable.dart';
import 'user.dart';
import 'song.dart';
import 'album.dart';
import 'ad_model.dart';
import 'app_config.dart';

class BootstrapResponse extends Equatable {
  final User? user;
  final List<Song> recentlyPlayed;
  final List<Song> topPlayed;
  final List<Song> newReleases;
  final List<Song> discoverWeekly;
  final List<Album> newAlbums;
  final List<AdModel> ads;
  final AppConfig? appConfig;

  const BootstrapResponse({
    this.user,
    required this.recentlyPlayed,
    required this.topPlayed,
    required this.newReleases,
    required this.discoverWeekly,
    required this.newAlbums,
    required this.ads,
    this.appConfig,
  });

  factory BootstrapResponse.fromJson(Map<String, dynamic> json) {
    // Parse user if present
    final userJson = json['user'];
    final user = userJson != null ? User.fromJson(userJson) : null;

    // Parse home feed arrays
    final homeFeedJson = json['homeFeed'] ?? {};

    final recentlyPlayed =
        (homeFeedJson['recentlyPlayed'] as List<dynamic>?)
            ?.map((e) => Song.fromJson(e))
            .toList() ??
        [];

    final topPlayed =
        (homeFeedJson['topPlayed'] as List<dynamic>?)
            ?.map((e) => Song.fromJson(e))
            .toList() ??
        [];

    final newReleases =
        (homeFeedJson['newReleases'] as List<dynamic>?)
            ?.map((e) => Song.fromJson(e))
            .toList() ??
        [];

    final discoverWeekly =
        (homeFeedJson['discoverWeekly'] as List<dynamic>?)
            ?.map((e) => Song.fromJson(e))
            .toList() ??
        [];

    final newAlbums =
        (homeFeedJson['newAlbums'] as List<dynamic>?)
            ?.map((e) => Album.fromJson(e))
            .toList() ??
        [];

    // Parse Ads
    final ads =
        (json['ads'] as List<dynamic>?)
            ?.map((e) => AdModel.fromJson(e))
            .toList() ??
        [];

    return BootstrapResponse(
      user: user,
      recentlyPlayed: recentlyPlayed,
      topPlayed: topPlayed,
      newReleases: newReleases,
      discoverWeekly: discoverWeekly,
      newAlbums: newAlbums,
      ads: ads,
      appConfig: json['appConfig'] != null ? AppConfig.fromJson(json['appConfig']) : null,
    );
  }

  @override
  List<Object?> get props => [
    user,
    recentlyPlayed,
    topPlayed,
    newReleases,
    discoverWeekly,
    newAlbums,
    ads,
    appConfig,
  ];
}
