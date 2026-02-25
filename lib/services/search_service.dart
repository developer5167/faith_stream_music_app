import '../models/song.dart';
import '../models/album.dart';
import '../models/artist.dart';
import 'api_client.dart';

class SearchService {
  final ApiClient _apiClient;

  SearchService(this._apiClient);

  Future<Map<String, dynamic>> search(String query) async {
    final response = await _apiClient.get(
      '/search',
      queryParameters: {'q': query},
    );

    final data = response.data;

    return {
      'songs':
          (data['songs'] as List?)
              ?.map((json) => Song.fromJson(json))
              .toList() ??
          [],
      'albums':
          (data['albums'] as List?)
              ?.map((json) => Album.fromJson(json))
              .toList() ??
          [],
      'artists':
          (data['artists'] as List?)
              ?.map((json) => Artist.fromJson(json))
              .toList() ??
          [],
    };
  }
}
