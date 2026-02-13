import 'package:faith_stream_music_app/models/artist.dart';
import 'package:faith_stream_music_app/services/api_client.dart';

class ArtistService {
  final ApiClient apiClient;

  ArtistService(this.apiClient);

  Future<Artist?> getArtistDetails(String artistId) async {
    try {
      final response = await apiClient.get('/artist/verified/$artistId');
      if (response.data != null && response.data is Map<String, dynamic>) {
        return Artist.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('Error fetching artist details: $e');
      return null;
    }
  }
}
