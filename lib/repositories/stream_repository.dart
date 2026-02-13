import '../services/api_client.dart';
import '../utils/api_response.dart';

class StreamRepository {
  final ApiClient _apiClient;

  StreamRepository(this._apiClient);

  /// Log a stream event to the backend
  /// This should be called when a user plays a song for analytics/payment tracking
  Future<ApiResponse<void>> logStream({
    required String songId,
    required int durationListened, // in seconds
  }) async {
    try {
      await _apiClient.post(
        '/stream/log',
        data: {'song_id': songId, 'duration_listened': durationListened},
      );

      return ApiResponse.success(
        data: null,
        message: 'Stream logged successfully',
      );
    } catch (e) {
      return ApiResponse.error(message: 'Failed to log stream: $e');
    }
  }

  /// Get stream URL for a song (requires subscription)
  Future<ApiResponse<String>> getStreamUrl(String songId) async {
    try {
      final response = await _apiClient.get('/stream/$songId/url');

      final streamUrl = response.data['streamUrl'] as String?;
      if (streamUrl == null) {
        return ApiResponse.error(message: 'Stream URL not found');
      }

      return ApiResponse.success(
        data: streamUrl,
        message: 'Stream URL retrieved successfully',
      );
    } catch (e) {
      return ApiResponse.error(message: 'Failed to get stream URL: $e');
    }
  }
}
