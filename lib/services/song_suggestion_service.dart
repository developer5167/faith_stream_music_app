import 'api_client.dart';

class SongSuggestionService {
  final ApiClient _apiClient;

  SongSuggestionService(this._apiClient);

  Future<void> suggestSong({
    required String songName,
    required String ministryName,
    String? singerName,
    String? albumName,
  }) async {
    await _apiClient.post(
      '/song-suggestions',
      data: {
        'song_name': songName,
        'ministry_name': ministryName,
        'singer_name': singerName,
        'album_name': albumName,
      },
    );
  }
}
