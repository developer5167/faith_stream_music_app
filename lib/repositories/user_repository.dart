import '../models/user.dart';
import '../models/subscription.dart';
import '../services/api_client.dart';
import '../utils/api_response.dart';

class UserRepository {
  final ApiClient _apiClient;

  UserRepository(this._apiClient);

  // Getter to access ApiClient for services that need it
  ApiClient get apiClient => _apiClient;

  // Get user profile
  Future<ApiResponse<User>> getProfile() async {
    try {
      final response = await _apiClient.get('/users/profile');

      if (response.data['success'] == true && response.data['user'] != null) {
        return ApiResponse(
          success: true,
          data: User.fromJson(response.data['user']),
          message: response.data['message'] ?? 'Profile retrieved successfully',
        );
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to get profile',
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Error getting profile: $e');
    }
  }

  // Update user profile
  Future<ApiResponse<User>> updateProfile({
    String? name,
    String? phone,
    String? bio,
    String? profilePicUrl,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (phone != null) body['phone'] = phone;
      if (bio != null) body['bio'] = bio;
      if (profilePicUrl != null) body['profile_pic_url'] = profilePicUrl;

      final response = await _apiClient.put('/users/profile', data: body);

      if (response.data['success'] == true && response.data['user'] != null) {
        return ApiResponse(
          success: true,
          data: User.fromJson(response.data['user']),
          message: response.data['message'] ?? 'Profile updated successfully',
        );
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to update profile',
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Error updating profile: $e');
    }
  }

  // Debug function for Push Notifications
  Future<ApiResponse<void>> testPushNotification() async {
    try {
      final response = await _apiClient.post('/notifications/test');
      return ApiResponse(
        success: response.data['success'] == true,
        message: response.data['message'] ?? 'Test notification sent',
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Failed to send test: $e');
    }
  }

  // Artist-related APIs

  // Request artist status
  Future<ApiResponse<void>> requestArtist({
    required String artistName,
    String? bio,
    String? govtIdUrl,
    String? addressProofUrl,
    String? selfieVideoUrl,
    List<String>? supportingLinks,
  }) async {
    try {
      final body = {
        'artist_name': artistName,
        if (bio != null) 'bio': bio,
        if (govtIdUrl != null) 'govt_id_url': govtIdUrl,
        if (addressProofUrl != null) 'address_proof_url': addressProofUrl,
        if (selfieVideoUrl != null) 'selfie_video_url': selfieVideoUrl,
        if (supportingLinks != null && supportingLinks.isNotEmpty)
          'supporting_links': supportingLinks,
      };

      final response = await _apiClient.post('/artist/request', data: body);

      return ApiResponse(
        success: response.data['message'] != null,
        message: response.data['message'] ?? 'Artist request submitted',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error requesting artist status: $e',
      );
    }
  }

  // Get artist status
  Future<ApiResponse<Map<String, dynamic>>> getArtistStatus() async {
    try {
      final response = await _apiClient.get('/artist/status');

      return ApiResponse(
        success: true,
        data: response.data as Map<String, dynamic>,
        message: 'Artist status retrieved',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error getting artist status: $e',
      );
    }
  }

  // Get artist dashboard stats (songs, albums, streams, earnings)
  Future<ApiResponse<Map<String, dynamic>>> getArtistDashboardStats() async {
    try {
      final response = await _apiClient.get('/artist/dashboard-stats');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return ApiResponse(
          success: true,
          data: data,
          message: 'Stats retrieved',
        );
      }
      return ApiResponse(success: false, message: 'Invalid stats response');
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error getting dashboard stats: $e',
      );
    }
  }

  // Subscription-related APIs

  // Get subscription status
  Future<ApiResponse<Subscription>> getSubscriptionStatus() async {
    try {
      final response = await _apiClient.get('/subscriptions/status');

      if (response.data['subscription'] != null ||
          response.data['subscriptions'] != null) {
        final subData =
            response.data['subscription'] ?? response.data['subscriptions'];
        return ApiResponse(
          success: true,
          data: Subscription.fromJson(
            subData is List ? subData.first : subData,
          ),
          message: 'Subscription retrieved',
        );
      }

      return ApiResponse(
        success: true,
        data: null,
        message: 'No active subscription',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error getting subscription: $e',
      );
    }
  }

  // Create subscription — returns { payment_url, payment_link_id, amount }
  Future<ApiResponse<Map<String, dynamic>>> createSubscription() async {
    try {
      final response = await _apiClient.post(
        '/subscriptions/create-link',
        data: {},
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        return ApiResponse(
          success: true,
          data: data,
          message: 'Payment link created',
        );
      }
      return ApiResponse(
        success: false,
        message: data['message'] ?? 'Failed to create payment link',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error creating subscription: $e',
      );
    }
  }

  // Create Razorpay order for razorpay_flutter plugin checkout
  Future<ApiResponse<Map<String, dynamic>>> createSubscriptionOrder() async {
    try {
      final response = await _apiClient.post(
        '/subscriptions/create-order',
        data: {},
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        return ApiResponse(success: true, data: data, message: 'Order created');
      }
      return ApiResponse(
        success: false,
        message: data['message'] ?? 'Failed to create order',
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Error creating order: $e');
    }
  }

  // Verify Razorpay payment and activate subscription
  Future<ApiResponse<Map<String, dynamic>>> verifySubscriptionPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    try {
      final response = await _apiClient.post(
        '/subscriptions/verify-payment',
        data: {
          'razorpay_order_id': orderId,
          'razorpay_payment_id': paymentId,
          'razorpay_signature': signature,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        return ApiResponse(
          success: true,
          data: data,
          message: 'Subscription activated',
        );
      }
      return ApiResponse(
        success: false,
        message: data['message'] ?? 'Verification failed',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error verifying payment: $e',
      );
    }
  }
}
