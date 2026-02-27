import 'package:equatable/equatable.dart';
import '../../models/song.dart';

abstract class LibraryEvent extends Equatable {
  const LibraryEvent();

  @override
  List<Object?> get props => [];
}

// ==================== GENERAL ====================

class LibraryLoadAll extends LibraryEvent {}

class LibraryRefresh extends LibraryEvent {}

class LibraryReset extends LibraryEvent {}

// ==================== FAVORITES ====================

class LibraryLoadFavorites extends LibraryEvent {}

class LibraryAddToFavorites extends LibraryEvent {
  final String songId;

  const LibraryAddToFavorites(this.songId);

  @override
  List<Object?> get props => [songId];
}

class LibraryRemoveFromFavorites extends LibraryEvent {
  final String songId;

  const LibraryRemoveFromFavorites(this.songId);

  @override
  List<Object?> get props => [songId];
}

class LibraryToggleFavorite extends LibraryEvent {
  final Song song;

  const LibraryToggleFavorite(this.song);

  @override
  List<Object?> get props => [song];
}

class LibraryLoadFavoriteArtists extends LibraryEvent {}

class LibraryLoadFavoriteAlbums extends LibraryEvent {}

class LibraryRemoveArtistFromFavorites extends LibraryEvent {
  final String artistId;

  const LibraryRemoveArtistFromFavorites(this.artistId);

  @override
  List<Object?> get props => [artistId];
}

class LibraryRemoveAlbumFromFavorites extends LibraryEvent {
  final String albumId;

  const LibraryRemoveAlbumFromFavorites(this.albumId);

  @override
  List<Object?> get props => [albumId];
}

// ==================== PLAYLISTS ====================

class LibraryLoadPlaylists extends LibraryEvent {}

class LibraryLoadPlaylist extends LibraryEvent {
  final String playlistId;

  const LibraryLoadPlaylist(this.playlistId);

  @override
  List<Object?> get props => [playlistId];
}

class LibraryCreatePlaylist extends LibraryEvent {
  final String name;
  final String? description;
  final bool isPublic;

  const LibraryCreatePlaylist({
    required this.name,
    this.description,
    this.isPublic = false,
  });

  @override
  List<Object?> get props => [name, description, isPublic];
}

class LibraryUpdatePlaylist extends LibraryEvent {
  final String playlistId;
  final String? name;
  final String? description;
  final bool? isPublic;

  const LibraryUpdatePlaylist({
    required this.playlistId,
    this.name,
    this.description,
    this.isPublic,
  });

  @override
  List<Object?> get props => [playlistId, name, description, isPublic];
}

class LibraryDeletePlaylist extends LibraryEvent {
  final String playlistId;

  const LibraryDeletePlaylist(this.playlistId);

  @override
  List<Object?> get props => [playlistId];
}

class LibraryAddSongToPlaylist extends LibraryEvent {
  final String playlistId;
  final String songId;

  const LibraryAddSongToPlaylist({
    required this.playlistId,
    required this.songId,
  });

  @override
  List<Object?> get props => [playlistId, songId];
}

class LibraryRemoveSongFromPlaylist extends LibraryEvent {
  final String playlistId;
  final String songId;

  const LibraryRemoveSongFromPlaylist({
    required this.playlistId,
    required this.songId,
  });

  @override
  List<Object?> get props => [playlistId, songId];
}
