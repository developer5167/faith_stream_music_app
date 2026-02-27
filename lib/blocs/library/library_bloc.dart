import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/library_repository.dart';
import 'library_event.dart';
import 'library_state.dart';

class LibraryBloc extends Bloc<LibraryEvent, LibraryState> {
  final LibraryRepository _libraryRepository;

  LibraryBloc(this._libraryRepository) : super(LibraryInitial()) {
    on<LibraryLoadAll>(_onLoadAll);
    on<LibraryRefresh>(_onRefresh);
    on<LibraryLoadFavorites>(_onLoadFavorites);
    on<LibraryLoadFavoriteArtists>(_onLoadFavoriteArtists);
    on<LibraryLoadFavoriteAlbums>(_onLoadFavoriteAlbums);
    on<LibraryAddToFavorites>(_onAddToFavorites);
    on<LibraryRemoveFromFavorites>(_onRemoveFromFavorites);
    on<LibraryToggleFavorite>(_onToggleFavorite);
    on<LibraryRemoveArtistFromFavorites>(_onRemoveArtistFromFavorites);
    on<LibraryRemoveAlbumFromFavorites>(_onRemoveAlbumFromFavorites);
    on<LibraryLoadPlaylists>(_onLoadPlaylists);
    on<LibraryLoadPlaylist>(_onLoadPlaylist);
    on<LibraryCreatePlaylist>(_onCreatePlaylist);
    on<LibraryUpdatePlaylist>(_onUpdatePlaylist);
    on<LibraryDeletePlaylist>(_onDeletePlaylist);
    on<LibraryAddSongToPlaylist>(_onAddSongToPlaylist);
    on<LibraryRemoveSongFromPlaylist>(_onRemoveSongFromPlaylist);
    on<LibraryReset>((event, emit) => emit(LibraryInitial()));
  }

  Future<void> _onLoadAll(
    LibraryLoadAll event,
    Emitter<LibraryState> emit,
  ) async {
    emit(LibraryLoading());

    try {
      final favoritesResponse = await _libraryRepository.getFavorites();
      final playlistsResponse = await _libraryRepository.getPlaylists();
      final artistsResponse = await _libraryRepository.getFavoriteArtists();
      final albumsResponse = await _libraryRepository.getFavoriteAlbums();

      if (favoritesResponse.success &&
          playlistsResponse.success &&
          artistsResponse.success &&
          albumsResponse.success) {
        final favorites = favoritesResponse.data ?? [];
        final playlists = playlistsResponse.data ?? [];
        final artists = artistsResponse.data ?? [];
        final albums = albumsResponse.data ?? [];
        final favoriteSongIds = favorites.map((song) => song.id).toSet();

        emit(
          LibraryLoaded(
            favorites: favorites,
            favoriteArtists: artists,
            favoriteAlbums: albums,
            playlists: playlists,
            favoriteSongIds: favoriteSongIds,
          ),
        );
      } else {
        // Find first error
        String errorMessage = 'Failed to load library';
        if (!favoritesResponse.success) {
          errorMessage = favoritesResponse.message;
        } else if (!playlistsResponse.success) {
          errorMessage = playlistsResponse.message;
        } else if (!artistsResponse.success) {
          errorMessage = artistsResponse.message;
        } else if (!albumsResponse.success) {
          errorMessage = albumsResponse.message;
        }

        emit(LibraryError(errorMessage));
      }
    } catch (e) {
      emit(LibraryError('Failed to load library: $e'));
    }
  }

  Future<void> _onRefresh(
    LibraryRefresh event,
    Emitter<LibraryState> emit,
  ) async {
    // Reload without showing loading state
    final currentState = state;
    if (currentState is! LibraryLoaded) {
      add(LibraryLoadAll());
      return;
    }

    try {
      final favoritesResponse = await _libraryRepository.getFavorites();
      final playlistsResponse = await _libraryRepository.getPlaylists();
      final artistsResponse = await _libraryRepository.getFavoriteArtists();
      final albumsResponse = await _libraryRepository.getFavoriteAlbums();

      if (favoritesResponse.success &&
          playlistsResponse.success &&
          artistsResponse.success &&
          albumsResponse.success) {
        final favorites = favoritesResponse.data ?? [];
        final playlists = playlistsResponse.data ?? [];
        final artists = artistsResponse.data ?? [];
        final albums = albumsResponse.data ?? [];
        final favoriteSongIds = favorites.map((song) => song.id).toSet();

        emit(
          LibraryLoaded(
            favorites: favorites,
            favoriteArtists: artists,
            favoriteAlbums: albums,
            playlists: playlists,
            favoriteSongIds: favoriteSongIds,
          ),
        );
      }
    } catch (e) {
      // Keep current state on refresh error
    }
  }

  Future<void> _onLoadFavorites(
    LibraryLoadFavorites event,
    Emitter<LibraryState> emit,
  ) async {
    emit(LibraryFavoritesLoading());

    try {
      final response = await _libraryRepository.getFavorites();

      if (response.success) {
        final favorites = response.data ?? [];
        final favoriteSongIds = favorites.map((song) => song.id).toSet();

        final currentState = state;
        if (currentState is LibraryLoaded) {
          emit(
            currentState.copyWith(
              favorites: favorites,
              favoriteSongIds: favoriteSongIds,
            ),
          );
        } else {
          emit(
            LibraryLoaded(
              favorites: favorites,
              favoriteSongIds: favoriteSongIds,
            ),
          );
        }
      } else {
        emit(LibraryError(response.message));
      }
    } catch (e) {
      emit(LibraryError('Failed to load favorites: $e'));
    }
  }

  Future<void> _onLoadFavoriteArtists(
    LibraryLoadFavoriteArtists event,
    Emitter<LibraryState> emit,
  ) async {
    emit(LibraryArtistsLoading());

    try {
      final response = await _libraryRepository.getFavoriteArtists();

      if (response.success) {
        final artists = response.data ?? [];

        final currentState = state;
        if (currentState is LibraryLoaded) {
          emit(currentState.copyWith(favoriteArtists: artists));
        } else {
          emit(LibraryLoaded(favoriteArtists: artists));
        }
      } else {
        emit(LibraryError(response.message));
      }
    } catch (e) {
      emit(LibraryError('Failed to load favorite artists: $e'));
    }
  }

  Future<void> _onLoadFavoriteAlbums(
    LibraryLoadFavoriteAlbums event,
    Emitter<LibraryState> emit,
  ) async {
    emit(LibraryAlbumsLoading());

    try {
      final response = await _libraryRepository.getFavoriteAlbums();

      if (response.success) {
        final albums = response.data ?? [];

        final currentState = state;
        if (currentState is LibraryLoaded) {
          emit(currentState.copyWith(favoriteAlbums: albums));
        } else {
          emit(LibraryLoaded(favoriteAlbums: albums));
        }
      } else {
        emit(LibraryError(response.message));
      }
    } catch (e) {
      emit(LibraryError('Failed to load favorite albums: $e'));
    }
  }

  Future<void> _onRemoveArtistFromFavorites(
    LibraryRemoveArtistFromFavorites event,
    Emitter<LibraryState> emit,
  ) async {
    final currentState = state;
    if (currentState is! LibraryLoaded) return;

    try {
      final response = await _libraryRepository.removeArtistFromFavorites(
        event.artistId,
      );

      if (response.success) {
        final updatedArtists = currentState.favoriteArtists
            .where((a) => a.id != event.artistId)
            .toList();

        emit(currentState.copyWith(favoriteArtists: updatedArtists));
      }
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _onRemoveAlbumFromFavorites(
    LibraryRemoveAlbumFromFavorites event,
    Emitter<LibraryState> emit,
  ) async {
    final currentState = state;
    if (currentState is! LibraryLoaded) return;

    try {
      final response = await _libraryRepository.removeAlbumFromFavorites(
        event.albumId,
      );

      if (response.success) {
        final updatedAlbums = currentState.favoriteAlbums
            .where((a) => a.id != event.albumId)
            .toList();

        emit(currentState.copyWith(favoriteAlbums: updatedAlbums));
      }
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _onAddToFavorites(
    LibraryAddToFavorites event,
    Emitter<LibraryState> emit,
  ) async {
    final currentState = state;
    if (currentState is! LibraryLoaded) return;

    try {
      final response = await _libraryRepository.addToFavorites(event.songId);

      if (response.success) {
        // Refresh favorites
        add(LibraryLoadFavorites());
      }
    } catch (e) {
      // Silent fail, could add snackbar notification
    }
  }

  Future<void> _onRemoveFromFavorites(
    LibraryRemoveFromFavorites event,
    Emitter<LibraryState> emit,
  ) async {
    final currentState = state;
    if (currentState is! LibraryLoaded) return;

    try {
      final response = await _libraryRepository.removeFromFavorites(
        event.songId,
      );

      if (response.success) {
        // Immediately update state
        final updatedFavorites = currentState.favorites
            .where((s) => s.id != event.songId)
            .toList();
        final updatedIds = Set<String>.from(currentState.favoriteSongIds)
          ..remove(event.songId);

        emit(
          currentState.copyWith(
            favorites: updatedFavorites,
            favoriteSongIds: updatedIds,
          ),
        );
      }
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _onToggleFavorite(
    LibraryToggleFavorite event,
    Emitter<LibraryState> emit,
  ) async {
    final currentState = state;
    if (currentState is! LibraryLoaded) return;

    final isFavorite = currentState.isFavorite(event.song.id);

    if (isFavorite) {
      add(LibraryRemoveFromFavorites(event.song.id));
    } else {
      add(LibraryAddToFavorites(event.song.id));
    }
  }

  Future<void> _onLoadPlaylists(
    LibraryLoadPlaylists event,
    Emitter<LibraryState> emit,
  ) async {
    emit(LibraryPlaylistsLoading());

    try {
      final response = await _libraryRepository.getPlaylists();

      if (response.success) {
        final playlists = response.data ?? [];

        final currentState = state;
        if (currentState is LibraryLoaded) {
          emit(currentState.copyWith(playlists: playlists));
        } else {
          emit(LibraryLoaded(playlists: playlists));
        }
      } else {
        emit(LibraryError(response.message));
      }
    } catch (e) {
      emit(LibraryError('Failed to load playlists: $e'));
    }
  }

  Future<void> _onLoadPlaylist(
    LibraryLoadPlaylist event,
    Emitter<LibraryState> emit,
  ) async {
    emit(LibraryPlaylistLoading(event.playlistId));

    try {
      final response = await _libraryRepository.getPlaylist(event.playlistId);

      if (response.success && response.data != null) {
        emit(LibraryPlaylistLoaded(response.data!));
      } else {
        emit(LibraryError(response.message));
      }
    } catch (e) {
      emit(LibraryError('Failed to load playlist: $e'));
    }
  }

  Future<void> _onCreatePlaylist(
    LibraryCreatePlaylist event,
    Emitter<LibraryState> emit,
  ) async {
    final currentState = state;

    try {
      final response = await _libraryRepository.createPlaylist(
        name: event.name,
        description: event.description,
        isPublic: event.isPublic,
      );

      if (response.success) {
        // Refresh playlists
        add(LibraryLoadPlaylists());

        if (currentState is LibraryLoaded) {
          emit(
            LibraryOperationSuccess(
              message: 'Playlist created successfully',
              previousState: currentState,
            ),
          );
        }
      } else {
        emit(LibraryError(response.message));
      }
    } catch (e) {
      emit(LibraryError('Failed to create playlist: $e'));
    }
  }

  Future<void> _onUpdatePlaylist(
    LibraryUpdatePlaylist event,
    Emitter<LibraryState> emit,
  ) async {
    try {
      final response = await _libraryRepository.updatePlaylist(
        playlistId: event.playlistId,
        name: event.name,
        description: event.description,
        isPublic: event.isPublic,
      );

      if (response.success) {
        // Refresh playlists
        add(LibraryLoadPlaylists());
      } else {
        emit(LibraryError(response.message));
      }
    } catch (e) {
      emit(LibraryError('Failed to update playlist: $e'));
    }
  }

  Future<void> _onDeletePlaylist(
    LibraryDeletePlaylist event,
    Emitter<LibraryState> emit,
  ) async {
    final currentState = state;
    if (currentState is! LibraryLoaded) return;

    try {
      final response = await _libraryRepository.deletePlaylist(
        event.playlistId,
      );

      if (response.success) {
        // Immediately remove from state
        final updatedPlaylists = currentState.playlists
            .where((p) => p.id != event.playlistId)
            .toList();

        emit(currentState.copyWith(playlists: updatedPlaylists));
      } else {
        emit(LibraryError(response.message));
      }
    } catch (e) {
      emit(LibraryError('Failed to delete playlist: $e'));
    }
  }

  Future<void> _onAddSongToPlaylist(
    LibraryAddSongToPlaylist event,
    Emitter<LibraryState> emit,
  ) async {
    try {
      final response = await _libraryRepository.addSongToPlaylist(
        playlistId: event.playlistId,
        songId: event.songId,
      );

      if (response.success) {
        // Could reload the specific playlist if viewing it
        add(LibraryLoadPlaylists());
      }
    } catch (e) {
      // Silent fail or show snackbar
    }
  }

  Future<void> _onRemoveSongFromPlaylist(
    LibraryRemoveSongFromPlaylist event,
    Emitter<LibraryState> emit,
  ) async {
    final currentState = state;
    if (currentState is! LibraryLoaded) return;

    try {
      final response = await _libraryRepository.removeSongFromPlaylist(
        playlistId: event.playlistId,
        songId: event.songId,
      );

      if (response.success) {
        // Optimistically update the playlist in the state
        final updatedPlaylists = currentState.playlists.map((playlist) {
          if (playlist.id == event.playlistId) {
            // Remove the song from this playlist
            final updatedSongs = playlist.songs
                .where((song) => song.id != event.songId)
                .toList();
            return playlist.copyWith(songs: updatedSongs);
          }
          return playlist;
        }).toList();

        emit(currentState.copyWith(playlists: updatedPlaylists));
      }
    } catch (e) {
      // Silent fail
    }
  }
}
