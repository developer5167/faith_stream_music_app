import 'package:equatable/equatable.dart';
import '../../models/song.dart';
import '../../models/artist.dart';
import '../../models/album.dart';
import '../../models/playlist.dart';

abstract class LibraryState extends Equatable {
  const LibraryState();

  @override
  List<Object?> get props => [];
}

class LibraryInitial extends LibraryState {}

class LibraryLoading extends LibraryState {}

class LibraryLoaded extends LibraryState {
  final List<Song> favorites;
  final List<Artist> favoriteArtists;
  final List<Album> favoriteAlbums;
  final List<Playlist> playlists;
  final Set<String> favoriteSongIds;

  const LibraryLoaded({
    this.favorites = const [],
    this.favoriteArtists = const [],
    this.favoriteAlbums = const [],
    this.playlists = const [],
    this.favoriteSongIds = const {},
  });

  bool isFavorite(String songId) => favoriteSongIds.contains(songId);

  LibraryLoaded copyWith({
    List<Song>? favorites,
    List<Artist>? favoriteArtists,
    List<Album>? favoriteAlbums,
    List<Playlist>? playlists,
    Set<String>? favoriteSongIds,
  }) {
    return LibraryLoaded(
      favorites: favorites ?? this.favorites,
      favoriteArtists: favoriteArtists ?? this.favoriteArtists,
      favoriteAlbums: favoriteAlbums ?? this.favoriteAlbums,
      playlists: playlists ?? this.playlists,
      favoriteSongIds: favoriteSongIds ?? this.favoriteSongIds,
    );
  }

  @override
  List<Object?> get props => [
    favorites,
    favoriteArtists,
    favoriteAlbums,
    playlists,
    favoriteSongIds,
  ];
}

class LibraryError extends LibraryState {
  final String message;

  const LibraryError(this.message);

  @override
  List<Object?> get props => [message];
}

// Specific loading states for better UX
class LibraryFavoritesLoading extends LibraryState {}

class LibraryPlaylistsLoading extends LibraryState {}

class LibraryArtistsLoading extends LibraryState {}

class LibraryAlbumsLoading extends LibraryState {}

class LibraryPlaylistLoading extends LibraryState {
  final String playlistId;

  const LibraryPlaylistLoading(this.playlistId);

  @override
  List<Object?> get props => [playlistId];
}

class LibraryPlaylistLoaded extends LibraryState {
  final Playlist playlist;

  const LibraryPlaylistLoaded(this.playlist);

  @override
  List<Object?> get props => [playlist];
}

// Success states for operations
class LibraryOperationSuccess extends LibraryState {
  final String message;
  final LibraryLoaded previousState;

  const LibraryOperationSuccess({
    required this.message,
    required this.previousState,
  });

  @override
  List<Object?> get props => [message, previousState];
}
