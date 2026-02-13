import '../models/song.dart';
import '../models/playlist.dart';
import '../services/api_client.dart';
import '../utils/api_response.dart';

class LibraryRepository {
  final ApiClient _apiClient;

  LibraryRepository(this._apiClient);

  // ==================== FAVORITES ====================

  /// Get all favorite songs for the current user
  Future<ApiResponse<List<Song>>> getFavorites() async {
    try {
      final response = await _apiClient.get('/favorites');

      if (response.statusCode == 200) {
        final songs = (response.data['favorites'] as List<dynamic>)
            .map((json) => Song.fromJson(json))
            .toList();

        return ApiResponse.success(
          data: songs,
          message: 'Favorites loaded successfully',
        );
      }

      return ApiResponse.error(
        message: response.data['message'] ?? 'Failed to load favorites',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }

  /// Add a song to favorites
  Future<ApiResponse<void>> addToFavorites(String songId) async {
    try {
      final response = await _apiClient.post(
        '/favorites',
        data: {'song_id': songId},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse.success(data: null, message: 'Added to favorites');
      }

      return ApiResponse.error(
        message: response.data['message'] ?? 'Failed to add to favorites',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }

  /// Remove a song from favorites
  Future<ApiResponse<void>> removeFromFavorites(String songId) async {
    try {
      final response = await _apiClient.delete('/favorites/$songId');

      if (response.statusCode == 200) {
        return ApiResponse.success(
          data: null,
          message: 'Removed from favorites',
        );
      }

      return ApiResponse.error(
        message: response.data['message'] ?? 'Failed to remove from favorites',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }

  /// Check if a song is favorited
  Future<ApiResponse<bool>> isFavorite(String songId) async {
    try {
      final response = await _apiClient.get('/favorites/$songId/check');

      if (response.statusCode == 200) {
        final isFavorite = response.data['is_favorite'] ?? false;
        return ApiResponse.success(
          data: isFavorite,
          message: 'Favorite status checked',
        );
      }

      return ApiResponse.error(
        message: response.data['message'] ?? 'Failed to check favorite status',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }

  // ==================== PLAYLISTS ====================

  /// Get all playlists for the current user
  Future<ApiResponse<List<Playlist>>> getPlaylists() async {
    try {
      final response = await _apiClient.get('/playlists');

      if (response.statusCode == 200) {
        final playlists = (response.data['playlists'] as List<dynamic>)
            .map((json) => Playlist.fromJson(json))
            .toList();

        return ApiResponse.success(
          data: playlists,
          message: 'Playlists loaded successfully',
        );
      }

      return ApiResponse.error(
        message: response.data['message'] ?? 'Failed to load playlists',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }

  /// Get a single playlist by ID
  Future<ApiResponse<Playlist>> getPlaylist(String playlistId) async {
    try {
      final response = await _apiClient.get('/playlists/$playlistId');

      if (response.statusCode == 200) {
        final playlist = Playlist.fromJson(response.data['playlist']);

        return ApiResponse.success(
          data: playlist,
          message: 'Playlist loaded successfully',
        );
      }

      return ApiResponse.error(
        message: response.data['message'] ?? 'Failed to load playlist',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }

  /// Create a new playlist
  Future<ApiResponse<Playlist>> createPlaylist({
    required String name,
    String? description,
    bool isPublic = false,
  }) async {
    try {
      final response = await _apiClient.post(
        '/playlists',
        data: {'name': name, 'description': description, 'is_public': isPublic},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final playlist = Playlist.fromJson(response.data['playlist']);

        return ApiResponse.success(
          data: playlist,
          message: 'Playlist created successfully',
        );
      }

      return ApiResponse.error(
        message: response.data['message'] ?? 'Failed to create playlist',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }

  /// Update playlist details
  Future<ApiResponse<Playlist>> updatePlaylist({
    required String playlistId,
    String? name,
    String? description,
    bool? isPublic,
  }) async {
    try {
      final response = await _apiClient.put(
        '/playlists/$playlistId',
        data: {
          if (name != null) 'name': name,
          if (description != null) 'description': description,
          if (isPublic != null) 'is_public': isPublic,
        },
      );

      if (response.statusCode == 200) {
        final playlist = Playlist.fromJson(response.data['playlist']);

        return ApiResponse.success(
          data: playlist,
          message: 'Playlist updated successfully',
        );
      }

      return ApiResponse.error(
        message: response.data['message'] ?? 'Failed to update playlist',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }

  /// Delete a playlist
  Future<ApiResponse<void>> deletePlaylist(String playlistId) async {
    try {
      final response = await _apiClient.delete('/playlists/$playlistId');

      if (response.statusCode == 200) {
        return ApiResponse.success(
          data: null,
          message: 'Playlist deleted successfully',
        );
      }

      return ApiResponse.error(
        message: response.data['message'] ?? 'Failed to delete playlist',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }

  /// Add a song to a playlist
  Future<ApiResponse<void>> addSongToPlaylist({
    required String playlistId,
    required String songId,
  }) async {
    try {
      final response = await _apiClient.post(
        '/playlists/$playlistId/songs',
        data: {'song_id': songId},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse.success(
          data: null,
          message: 'Song added to playlist',
        );
      }

      return ApiResponse.error(
        message: response.data['message'] ?? 'Failed to add song to playlist',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }

  /// Remove a song from a playlist
  Future<ApiResponse<void>> removeSongFromPlaylist({
    required String playlistId,
    required String songId,
  }) async {
    try {
      final response = await _apiClient.delete(
        '/playlists/$playlistId/songs/$songId',
      );

      if (response.statusCode == 200) {
        return ApiResponse.success(
          data: null,
          message: 'Song removed from playlist',
        );
      }

      return ApiResponse.error(
        message:
            response.data['message'] ?? 'Failed to remove song from playlist',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }
}
