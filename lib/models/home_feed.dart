import 'package:equatable/equatable.dart';
import 'song.dart';
import 'album.dart';
import 'artist.dart';

class HomeFeed extends Equatable {
  final List<Song> trendingSongs;
  final List<Song> topPlayedSongs;
  final List<Album> albums;
  final List<Artist> followedArtists;
  final List<Song> recentlyPlayed;
  final List<Artist> topArtists;
  final List<Artist> topPlayedArtists;

  const HomeFeed({
    required this.trendingSongs,
    required this.topPlayedSongs,
    required this.albums,
    required this.followedArtists,
    required this.recentlyPlayed,
    required this.topArtists,
    required this.topPlayedArtists,
  });

  factory HomeFeed.fromJson(Map<String, dynamic> json) {
    return HomeFeed(
      trendingSongs:
          (json['trending_songs'] as List<dynamic>?)
              ?.map((e) => Song.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      topPlayedSongs:
          (json['top_played_songs'] as List<dynamic>?)
              ?.map((e) => Song.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      albums:
          (json['albums'] as List<dynamic>?)
              ?.map((e) => Album.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      followedArtists:
          (json['followed_artists'] as List<dynamic>?)
              ?.map((e) => Artist.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      recentlyPlayed:
          (json['recentlyPlayed'] as List<dynamic>?)
              ?.map((e) => Song.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      topArtists:
          (json['top_artists'] as List<dynamic>?)
              ?.map((e) => Artist.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      topPlayedArtists:
          (json['top_played_artists'] as List<dynamic>?)
              ?.map((e) => Artist.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trending_songs': trendingSongs.map((e) => e.toJson()).toList(),
      'top_played_songs': topPlayedSongs.map((e) => e.toJson()).toList(),
      'albums': albums.map((e) => e.toJson()).toList(),
      'followed_artists': followedArtists.map((e) => e.toJson()).toList(),
      'recentlyPlayed': recentlyPlayed.map((e) => e.toJson()).toList(),
      'top_artists': topArtists.map((e) => e.toJson()).toList(),
      'top_played_artists': topPlayedArtists.map((e) => e.toJson()).toList(),
    };
  }

  HomeFeed copyWith({
    List<Song>? trendingSongs,
    List<Song>? topPlayedSongs,
    List<Album>? albums,
    List<Artist>? followedArtists,
    List<Song>? recentlyPlayed,
    List<Artist>? topArtists,
    List<Artist>? topPlayedArtists,
  }) {
    return HomeFeed(
      trendingSongs: trendingSongs ?? this.trendingSongs,
      topPlayedSongs: topPlayedSongs ?? this.topPlayedSongs,
      albums: albums ?? this.albums,
      followedArtists: followedArtists ?? this.followedArtists,
      recentlyPlayed: recentlyPlayed ?? this.recentlyPlayed,
      topArtists: topArtists ?? this.topArtists,
      topPlayedArtists: topPlayedArtists ?? this.topPlayedArtists,
    );
  }

  @override
  List<Object?> get props => [
    trendingSongs,
    topPlayedSongs,
    albums,
    followedArtists,
    recentlyPlayed,
    topArtists,
    topPlayedArtists,
  ];
}
