import 'dart:async';
import '../services/api_client.dart';
import '../utils/api_response.dart';

class StreamRepository {
  final ApiClient _apiClient;
  final _streamLoggedController = StreamController<void>.broadcast();

  Stream<void> get onStreamLogged => _streamLoggedController.stream;

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

      // Notify listeners that a stream was logged
      _streamLoggedController.add(null);

      return ApiResponse.success(
        data: null,
        message: 'Stream logged successfully',
      );
    } catch (e) {
      return ApiResponse.error(message: 'Failed to log stream: $e');
    }
  }

  /// Log only "Recently Played" without risking double-count on stream analytics.
  /// Called immediately when a song starts playing (before 30s threshold).
  Future<void> logRecentlyPlayed({required String songId}) async {
    try {
      await _apiClient.post('/stream/log-played', data: {'song_id': songId});
    } catch (_) {
      // Silently ignore — recently played is best-effort, not critical
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

  Future<ApiResponse<bool>> checkPlayLimit(String songId) async {
    try {
      final response = await _apiClient.get('/stream/$songId/check-limit');
      final canPlay = response.data['canPlay'] == true;
      if (!canPlay) {
        return ApiResponse.error(
          message: response.data['reason'] ?? 'Daily limit reached',
        );
      }
      return ApiResponse.success(data: true, message: 'OK');
    } catch (e) {
      return ApiResponse.error(message: 'Failed to verify play limit: $e');
    }
  }

  void dispose() {
    _streamLoggedController.close();
  }
}
