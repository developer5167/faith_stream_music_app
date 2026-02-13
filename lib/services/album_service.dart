import 'api_client.dart';

class AlbumService {
  final ApiClient apiClient;

  AlbumService(this.apiClient);

  /// Create a new album (without cover initially)
  Future<Map<String, dynamic>> createAlbum({
    required String title,
    required String description,
    required String language,
    required String releaseType,
  }) async {
    final response = await apiClient.post(
      '/albums',
      data: {
        'title': title,
        'description': description,
        'language': language,
        'release_type': releaseType,
      },
    );

    return response.data is Map ? response.data : {};
  }

  /// Update album with cover image URL
  Future<void> updateAlbumCover({
    required String albumId,
    required String coverImageUrl,
  }) async {
    await apiClient.patch(
      '/albums/$albumId',
      data: {'cover_image_url': coverImageUrl},
    );
  }

  /// Get artist's albums
  Future<List<dynamic>> getMyAlbums() async {
    final response = await apiClient.get('/albums/my');
    final data = response.data;
    if (data is List) return data;
    return [];
  }

  /// Submit album for review
  Future<void> submitAlbum({required String albumId}) async {
    await apiClient.post('/albums/submit', data: {'album_id': albumId});
  }

  /// Get tracks for a specific album
  Future<List<dynamic>> getAlbumTracks(String albumId) async {
    final response = await apiClient.get('/albums/tracks/$albumId');
    final data = response.data;
    
    if (data is Map && data.containsKey('songs')) {
      final songs = data['songs'];
      if (songs is List) return songs;
    }

    return [];
  }
}
