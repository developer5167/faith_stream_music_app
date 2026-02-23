class AppConfig {
  // API Configuration
  static const String baseUrl = 'http://192.168.15.168:9000/api';

  // Endpoints (without /api prefix since it's in baseUrl)
  static const String authEndpoint = '/auth';
  static const String homeEndpoint = '/home';
  static const String songsEndpoint = '/songs';
  static const String albumsEndpoint = '/albums';
  static const String artistsEndpoint = '/artists';
  static const String subscriptionsEndpoint = '/subscriptions';
  static const String streamEndpoint = '/stream';
  static const String complaintsEndpoint = '/complaints';
  static const String adminEndpoint = '/admin';
  static const String uploadEndpoint = '/upload';
  static const String payoutsEndpoint = '/payouts';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String themeKey = 'theme_mode';
  static const String onboardingKey = 'onboarding_completed';

  // App Info
  static const String appName = 'FaithStream';
  static const String appVersion = '1.0.0';

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Pagination
  static const int pageSize = 20;

  // Audio
  static const int audioQualityHigh = 320; // kbps
  static const int audioQualityNormal = 128;
  static const int audioQualityLow = 64;

  // Cache
  static const Duration cacheExpiry = Duration(hours: 24);
  static const int maxCacheSize = 100; // MB
}
