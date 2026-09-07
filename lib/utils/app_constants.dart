import '../services/api_config.dart';

class AppConstants {
  // App General Information
  static const String appName = 'PhotoHouse';
  static const String appVersion = '1.0.0';

  // API Base Configuration (Delegates to ApiConfig)
  static const String baseUrl = ApiConfig.baseUrl;

  // Secure Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String tenantKey = 'tenant_data';
  static const String deviceNameKey = 'device_name';

  // Upload Limits & Defaults
  static const int maxUploadBatchSize = ApiConfig.maxBatchUploadSize;
  static const int maxFileSizeBytes = ApiConfig.maxFileSizeBytes;
  static const int defaultPaginationLimit = ApiConfig.defaultPageSize;

  // Cache & Session TTL
  static const int presignedUrlTtlMinutes = ApiConfig.presignedUrlTtlMinutes;
}
