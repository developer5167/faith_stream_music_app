import '../models/home_feed.dart';
import '../services/api_client.dart';
import '../utils/api_response.dart';

class HomeRepository {
  final ApiClient _apiClient;

  HomeRepository(this._apiClient);

  Future<ApiResponse<HomeFeed>> getHomeFeed() async {
    try {
      final response = await _apiClient.get('/home');

      if (response.statusCode == 200) {
        final homeFeed = HomeFeed.fromJson(response.data);
        return ApiResponse.success(
          data: homeFeed,
          message: 'Home feed loaded successfully',
        );
      }

      return ApiResponse.error(
        message: response.data['message'] ?? 'Failed to load home feed',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }
}
