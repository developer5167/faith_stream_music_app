import 'package:equatable/equatable.dart';
import 'song.dart';
import 'album.dart';
import 'artist.dart';

class HomeFeed extends Equatable {
  final List<Song> songs;
  final List<Album> albums;
  final List<Artist> artists;
  final List<Song> recentlyPlayed;

  const HomeFeed({
    required this.songs,
    required this.albums,
    required this.artists,
    required this.recentlyPlayed,
  });

  factory HomeFeed.fromJson(Map<String, dynamic> json) {
    return HomeFeed(
      songs:
          (json['songs'] as List<dynamic>?)
              ?.map((e) => Song.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      albums:
          (json['albums'] as List<dynamic>?)
              ?.map((e) => Album.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      artists:
          (json['artists'] as List<dynamic>?)
              ?.map((e) => Artist.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      recentlyPlayed:
          (json['recentlyPlayed'] as List<dynamic>?)
              ?.map((e) => Song.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'songs': songs.map((e) => e.toJson()).toList(),
      'albums': albums.map((e) => e.toJson()).toList(),
      'artists': artists.map((e) => e.toJson()).toList(),
      'recentlyPlayed': recentlyPlayed.map((e) => e.toJson()).toList(),
    };
  }

  HomeFeed copyWith({
    List<Song>? songs,
    List<Album>? albums,
    List<Artist>? artists,
    List<Song>? recentlyPlayed,
  }) {
    return HomeFeed(
      songs: songs ?? this.songs,
      albums: albums ?? this.albums,
      artists: artists ?? this.artists,
      recentlyPlayed: recentlyPlayed ?? this.recentlyPlayed,
    );
  }

  @override
  List<Object?> get props => [songs, albums, artists, recentlyPlayed];
}
