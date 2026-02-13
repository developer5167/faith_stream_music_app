import 'dart:developer';

import 'package:flutter/foundation.dart';

import '../models/auth_response.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../utils/api_response.dart';

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  Future<ApiResponse<AuthResponse>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print("🔍 Login Response Data: ${response.data}");
          print("🔍 Data Type: ${response.data.runtimeType}");
          print("🔍 Token: ${response.data['token']}");
          print("🔍 User: ${response.data['user']}");
        }

        final authResponse = AuthResponse.fromJson(response.data);
        if (kDebugMode) {
          print("✅ Login successful - AuthResponse: $authResponse");
        }
        log(authResponse.toString());
        return ApiResponse.success(
          data: authResponse,
          message: 'Login successful',
        );
      }

      return ApiResponse.error(
        message: response.data['message'] ?? 'Login failed',
        statusCode: response.statusCode,
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print("❌ Login Error: $e");
        print("❌ Stack Trace: $stackTrace");
      }
      return ApiResponse.error(message: e.toString());
    }
  }

  Future<ApiResponse<AuthResponse>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        '/auth/register',
        data: {'name': name, 'email': email, 'password': password},
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(response.data);
        return ApiResponse.success(
          data: authResponse,
          message: 'Registration successful',
        );
      }

      return ApiResponse.error(
        message: response.data['message'] ?? 'Registration failed',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }

  Future<ApiResponse<User>> getMe() async {
    try {
      final response = await _apiClient.get('/auth/me');

      if (response.statusCode == 200) {
        final user = User.fromJson(response.data['user']);
        return ApiResponse.success(
          data: user,
          message: 'User fetched successfully',
        );
      }

      return ApiResponse.error(
        message: response.data['message'] ?? 'Failed to fetch user',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }

  Future<ApiResponse<bool>> logout() async {
    try {
      // If your API has a logout endpoint
      // final response = await _apiClient.post('/auth/logout');
      // Just return success since logout is mostly client-side (clearing tokens)
      return ApiResponse<bool>.success(
        data: true,
        message: 'Logout successful',
      );
    } catch (e) {
      return ApiResponse<bool>.error(message: e.toString());
    }
  }
}
