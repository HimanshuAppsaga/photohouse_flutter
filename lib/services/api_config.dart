class ApiConfig {
  /// Base API URL for production
  static const String baseUrl = "https://photohouse.appsaga.io/api/v1";

  // ---------------------------------------------------------------------------
  // Endpoints: System, Health & Auth
  // ---------------------------------------------------------------------------
  static const String healthEndpoint = "/health";
  static const String brandingEndpoint = "/platform/branding";
  static const String loginEndpoint = "/auth/login";
  static const String userEndpoint = "/user";
  static const String logoutEndpoint = "/auth/logout";

  // ---------------------------------------------------------------------------
  // Endpoints: Events & Albums
  // ---------------------------------------------------------------------------
  static const String eventsEndpoint = "/events";
  static String eventDetailsEndpoint(String uuid) => "/events/$uuid";
  static String eventAlbumsEndpoint(String uuid) => "/events/$uuid/albums";

  // ---------------------------------------------------------------------------
  // Endpoints: Direct Cloudflare R2 Upload Flow
  // ---------------------------------------------------------------------------
  static String presignSingleEndpoint(String uuid) => "/events/$uuid/upload/presign";
  static String presignBatchEndpoint(String uuid) => "/events/$uuid/upload/presign-batch";
  static String completeSingleEndpoint(String uuid) => "/events/$uuid/upload/complete";
  static String registerBatchEndpoint(String uuid) => "/events/$uuid/upload/register-batch";
  static String originalCompleteEndpoint(String uuid) => "/events/$uuid/upload/original-complete";
  static String facesEndpoint(String uuid) => "/events/$uuid/upload/faces";
  static String batchCompleteEndpoint(String uuid) => "/events/$uuid/upload/batch-complete";

  // ---------------------------------------------------------------------------
  // Endpoints: Upload History, Subscription & Watermark
  // ---------------------------------------------------------------------------
  static const String uploadSessionsEndpoint = "/upload-sessions";
  static const String subscriptionEndpoint = "/subscription";
  static const String watermarkSettingsEndpoint = "/watermark-settings";

  // ---------------------------------------------------------------------------
  // Endpoints: Desktop Release & Tauri Updater
  // ---------------------------------------------------------------------------
  static String desktopCheckUpdateEndpoint({required String platform, required String currentVersion}) =>
      '/desktop/check-update?platform=${Uri.encodeComponent(platform)}&current_version=${Uri.encodeComponent(currentVersion)}';

  static String desktopLatestBuildEndpoint({required String platform}) =>
      '/desktop/latest-build?platform=${Uri.encodeComponent(platform)}';

  static String desktopDownloadUpdateEndpoint({required String platform, String type = 'installer'}) =>
      '/desktop/download-update?platform=${Uri.encodeComponent(platform)}&type=${Uri.encodeComponent(type)}';

  static const String desktopUpdaterManifestEndpoint = "/desktop/updater-manifest";

  // ---------------------------------------------------------------------------
  // Endpoint Summary Meta & System Metrics
  // ---------------------------------------------------------------------------
  static const int totalApiEndpointsCount = 23;
  static const int publicApiEndpointsCount = 3;
  static const int authenticatedApiEndpointsCount = 20;

  // ---------------------------------------------------------------------------
  // Default Headers & Network Configuration
  // ---------------------------------------------------------------------------
  static const Map<String, String> defaultHeaders = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  static const Duration requestTimeout = Duration(seconds: 30);

  // ---------------------------------------------------------------------------
  // Upload Rules & Platform Constants
  // ---------------------------------------------------------------------------
  static const int maxBatchUploadSize = 100;
  static const int maxFileSizeBytes = 104857600; // 100 MB (104,857,600 bytes)
  static const int presignedUrlTtlMinutes = 60;
  static const int defaultPageSize = 50;
  static const int maxUploadConcurrency = 3;

  static const List<String> allowedMimeTypes = [
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/heic',
    'image/heif',
    'image/tiff',
  ];

  static const List<String> desktopPlatforms = [
    'macos_aarch64',
    'macos_x86_64',
    'windows_x64',
  ];
}


