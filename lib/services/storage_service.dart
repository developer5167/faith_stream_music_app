import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../config/app_config.dart';
import '../models/user.dart';

class StorageService {
  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _prefs;

  StorageService(this._secureStorage, this._prefs);

  // Token Management
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: AppConfig.tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: AppConfig.tokenKey);
  }

  Future<void> deleteToken() async {
    await _secureStorage.delete(key: AppConfig.tokenKey);
  }

  // User Management
  Future<void> saveUser(User user) async {
    final userJson = jsonEncode(user.toJson());
    await _prefs.setString(AppConfig.userKey, userJson);
  }

  User? getUser() {
    final userJson = _prefs.getString(AppConfig.userKey);
    if (userJson != null) {
      return User.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  Future<void> deleteUser() async {
    await _prefs.remove(AppConfig.userKey);
  }

  // Theme Management
  Future<void> saveThemeMode(String mode) async {
    await _prefs.setString(AppConfig.themeKey, mode);
  }

  String? getThemeMode() {
    return _prefs.getString(AppConfig.themeKey);
  }

  // Onboarding
  Future<void> setOnboardingCompleted() async {
    await _prefs.setBool(AppConfig.onboardingKey, true);
  }

  bool isOnboardingCompleted() {
    return _prefs.getBool(AppConfig.onboardingKey) ?? false;
  }

  // Clear all data
  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
    await _prefs.clear();
  }
}
