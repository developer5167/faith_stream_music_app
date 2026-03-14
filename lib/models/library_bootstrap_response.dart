import 'song.dart';
import 'artist.dart';
import 'album.dart';
import 'playlist.dart';

class LibraryBootstrapResponse {
  final List<Song> favorites;
  final List<Artist> favoriteArtists;
  final List<Album> favoriteAlbums;
  final List<Playlist> playlists;

  LibraryBootstrapResponse({
    required this.favorites,
    required this.favoriteArtists,
    required this.favoriteAlbums,
    required this.playlists,
  });

  factory LibraryBootstrapResponse.fromJson(Map<String, dynamic> json) {
    return LibraryBootstrapResponse(
      favorites: (json['favorites'] as List<dynamic>?)
              ?.map((e) => Song.fromJson(e))
              .toList() ??
          [],
      favoriteArtists: (json['artists'] as List<dynamic>?)
              ?.map((e) => Artist.fromJson(e))
              .toList() ??
          [],
      favoriteAlbums: (json['albums'] as List<dynamic>?)
              ?.map((e) => Album.fromJson(e))
              .toList() ??
          [],
      playlists: (json['playlists'] as List<dynamic>?)
              ?.map((e) => Playlist.fromJson(e))
              .toList() ??
          [],
    );
  }
}
