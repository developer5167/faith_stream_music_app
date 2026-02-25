import 'api_client.dart';

class SongService {
  final ApiClient apiClient;

  SongService(this.apiClient);

  /// Create a new song
  Future<Map<String, dynamic>> createSong({
    required String title,
    required String language,
    required String genre,
    String? lyrics,
    String? description,
    String? albumId,
    int? trackNumber,
    String? audioUrl,
    String? coverImageUrl,
  }) async {
    final response = await apiClient.post(
      '/songs',
      data: {
        'title': title,
        'language': language,
        'genre': genre,
        if (lyrics != null && lyrics.isNotEmpty) 'lyrics': lyrics,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (albumId != null && albumId.isNotEmpty) 'album_id': albumId,
        if (trackNumber != null) 'track_number': trackNumber,
        if (audioUrl != null && audioUrl.isNotEmpty)
          'audio_original_url': audioUrl,
        if (coverImageUrl != null && coverImageUrl.isNotEmpty)
          'cover_image_url': coverImageUrl,
      },
    );

    return response.data is Map ? response.data : {};
  }

  /// Update song with audio and/or cover URLs
  Future<void> updateSong({
    required String songId,
    String? audioUrl,
    String? coverImageUrl,
  }) async {
    final Map<String, dynamic> updateData = {};

    if (audioUrl != null && audioUrl.isNotEmpty) {
      updateData['audio_original_url'] = audioUrl;
    }

    if (coverImageUrl != null && coverImageUrl.isNotEmpty) {
      updateData['cover_image_url'] = coverImageUrl;
    }

    if (updateData.isNotEmpty) {
      await apiClient.patch('/songs/$songId', data: updateData);
    }
  }

  /// Get artist's songs
  Future<List<dynamic>> getMySongs() async {
    final response = await apiClient.get('/songs/my');
    final data = response.data;
    if (data is List) return data;
    return [];
  }

  /// Get all available albums for the artist (for song creation)
  Future<List<dynamic>> getMyAlbums() async {
    final response = await apiClient.get('/albums/my');
    final data = response.data;
    if (data is List) return data;
    return [];
  }

  /// Get song details
  Future<Map<String, dynamic>?> getSong(String songId) async {
    final response = await apiClient.get('/songs/$songId');
    return response.data is Map ? response.data : null;
  }
}
