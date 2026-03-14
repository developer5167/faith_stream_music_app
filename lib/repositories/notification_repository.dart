import '../models/notification.dart';
import '../services/api_client.dart';

class NotificationRepository {
  final ApiClient _apiClient;

  NotificationRepository(this._apiClient);

  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '/notifications',
        queryParameters: {'page': page.toString(), 'limit': limit.toString()},
      );

      final data = response.data;
      if (data['success'] == true) {
        final List<dynamic> itemsData = data['items'] ?? [];
        final notifications = itemsData
            .map((json) => NotificationModel.fromJson(json))
            .toList();
        return {'notifications': notifications, 'total': data['total'] ?? 0};
      }
      throw Exception(data['message'] ?? 'Failed to fetch notifications');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<bool> markAsRead(String id) async {
    try {
      final response = await _apiClient.patch('/notifications/$id/read');
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      final response = await _apiClient.patch('/notifications/mark-all-read');
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }
}
