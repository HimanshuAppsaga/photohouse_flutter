import 'package:flutter/material.dart';

/// Categorization for PhotoHouse API Endpoints (Section 10 of mobile-api.md)
enum EndpointCategory {
  system,
  auth,
  events,
  upload,
  history,
  subscription,
  watermark,
  desktop;

  String get displayName {
    switch (this) {
      case EndpointCategory.system:
        return 'System & Health';
      case EndpointCategory.auth:
        return 'Authentication';
      case EndpointCategory.events:
        return 'Events & Albums';
      case EndpointCategory.upload:
        return 'Cloudflare R2 Uploads';
      case EndpointCategory.history:
        return 'Upload Sessions';
      case EndpointCategory.subscription:
        return 'Subscription & Quota';
      case EndpointCategory.watermark:
        return 'Watermark Settings';
      case EndpointCategory.desktop:
        return 'Desktop Releases';
    }
  }

  IconData get icon {
    switch (this) {
      case EndpointCategory.system:
        return Icons.health_and_safety_outlined;
      case EndpointCategory.auth:
        return Icons.lock_outline;
      case EndpointCategory.events:
        return Icons.collections_outlined;
      case EndpointCategory.upload:
        return Icons.cloud_upload_outlined;
      case EndpointCategory.history:
        return Icons.history_outlined;
      case EndpointCategory.subscription:
        return Icons.workspace_premium_outlined;
      case EndpointCategory.watermark:
        return Icons.branding_watermark_outlined;
      case EndpointCategory.desktop:
        return Icons.desktop_windows_outlined;
    }
  }
}

/// Health and connectivity status of an endpoint test
enum EndpointHealthStatus {
  untested,
  healthy,
  degraded,
  unauthorized,
  error;

  String get label {
    switch (this) {
      case EndpointHealthStatus.untested:
        return 'Untested';
      case EndpointHealthStatus.healthy:
        return 'Healthy';
      case EndpointHealthStatus.degraded:
        return 'Degraded';
      case EndpointHealthStatus.unauthorized:
        return '401 Auth Required';
      case EndpointHealthStatus.error:
        return 'Error';
    }
  }

  Color get color {
    switch (this) {
      case EndpointHealthStatus.untested:
        return const Color(0xFF9E9E9E);
      case EndpointHealthStatus.healthy:
        return const Color(0xFF10B981); // Emerald Green
      case EndpointHealthStatus.degraded:
        return const Color(0xFFF59E0B); // Amber
      case EndpointHealthStatus.unauthorized:
        return const Color(0xFF3B82F6); // Blue
      case EndpointHealthStatus.error:
        return const Color(0xFFEF4444); // Red
    }
  }
}

/// Model for a single API Endpoint specification from Section 10 of mobile-api.md
class EndpointSummaryItem {
  final int id;
  final String method;
  final String path;
  final bool requiresAuth;
  final String purpose;
  final EndpointCategory category;
  final String? sampleBody;
  final String? sampleParams;
  final String? expectedResponse;
  
  // Dynamic runtime smoke test states
  EndpointHealthStatus status;
  int? responseTimeMs;
  String? lastTestMessage;
  DateTime? lastTestedAt;

  EndpointSummaryItem({
    required this.id,
    required this.method,
    required this.path,
    required this.requiresAuth,
    required this.purpose,
    required this.category,
    this.sampleBody,
    this.sampleParams,
    this.expectedResponse,
    this.status = EndpointHealthStatus.untested,
    this.responseTimeMs,
    this.lastTestMessage,
    this.lastTestedAt,
  });

  /// Color code for HTTP Method tag
  Color get methodColor {
    switch (method.toUpperCase()) {
      case 'GET':
        return const Color(0xFF10B981); // Green
      case 'POST':
        return const Color(0xFF3B82F6); // Blue
      case 'PUT':
        return const Color(0xFFF59E0B); // Orange
      case 'DELETE':
        return const Color(0xFFEF4444); // Red
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  /// Copy with updated smoke test metrics
  EndpointSummaryItem copyWithTestResult({
    required EndpointHealthStatus status,
    required int responseTimeMs,
    required String lastTestMessage,
  }) {
    return EndpointSummaryItem(
      id: id,
      method: method,
      path: path,
      requiresAuth: requiresAuth,
      purpose: purpose,
      category: category,
      sampleBody: sampleBody,
      sampleParams: sampleParams,
      expectedResponse: expectedResponse,
      status: status,
      responseTimeMs: responseTimeMs,
      lastTestMessage: lastTestMessage,
      lastTestedAt: DateTime.now(),
    );
  }
}

/// Model for Section 11 Integration Checklist items
class IntegrationChecklistItem {
  final int step;
  final String title;
  final String description;
  final String endpointReference;
  final bool isCompleted;

  const IntegrationChecklistItem({
    required this.step,
    required this.title,
    required this.description,
    required this.endpointReference,
    this.isCompleted = true,
  });
}

/// Catalog containing all 23 API endpoints listed in Section 10 of mobile-api.md
class EndpointSummaryCatalog {
  static List<EndpointSummaryItem> getAllEndpoints() {
    return [
      // 1. Health
      EndpointSummaryItem(
        id: 1,
        method: 'GET',
        path: '/health',
        requiresAuth: false,
        purpose: 'Service health check',
        category: EndpointCategory.system,
        expectedResponse: '{"status": "ok", "app": "PhotoHouse API"}',
      ),
      // 2. Platform Branding
      EndpointSummaryItem(
        id: 2,
        method: 'GET',
        path: '/platform/branding',
        requiresAuth: false,
        purpose: 'White-label branding assets',
        category: EndpointCategory.system,
        expectedResponse: '{"app_name": "PhotoHouse", "logo_url": "..."}',
      ),
      // 3. Login
      EndpointSummaryItem(
        id: 3,
        method: 'POST',
        path: '/auth/login',
        requiresAuth: false,
        purpose: 'Issue a Bearer token',
        category: EndpointCategory.auth,
        sampleBody: '{"email": "you@studio.com", "password": "...", "device_name": "mobile-app"}',
        expectedResponse: '{"token": "1|...", "user": {...}}',
      ),
      // 4. Current User
      EndpointSummaryItem(
        id: 4,
        method: 'GET',
        path: '/user',
        requiresAuth: true,
        purpose: 'Current user + studio metadata',
        category: EndpointCategory.auth,
        expectedResponse: '{"id": "...", "name": "...", "studio": {...}}',
      ),
      // 5. Logout
      EndpointSummaryItem(
        id: 5,
        method: 'POST',
        path: '/auth/logout',
        requiresAuth: true,
        purpose: 'Revoke the current Bearer token',
        category: EndpointCategory.auth,
        expectedResponse: '{"message": "Logged out successfully"}',
      ),
      // 6. List Events
      EndpointSummaryItem(
        id: 6,
        method: 'GET',
        path: '/events',
        requiresAuth: true,
        purpose: 'List events (cursor paginated)',
        category: EndpointCategory.events,
        sampleParams: '?cursor=...&limit=50',
        expectedResponse: '{"data": [...], "meta": {"next_cursor": "..."}}',
      ),
      // 7. Single Event
      EndpointSummaryItem(
        id: 7,
        method: 'GET',
        path: '/events/{uuid}',
        requiresAuth: true,
        purpose: 'Show details of a single event',
        category: EndpointCategory.events,
        sampleParams: 'uuid = event_123',
        expectedResponse: '{"data": {"id": "...", "name": "..."}}',
      ),
      // 8. Event Albums
      EndpointSummaryItem(
        id: 8,
        method: 'GET',
        path: '/events/{uuid}/albums',
        requiresAuth: true,
        purpose: 'List albums of an event',
        category: EndpointCategory.events,
        sampleParams: 'uuid = event_123',
        expectedResponse: '{"data": [{"id": "...", "name": "Highlight"}]}',
      ),
      // 9. Presign Single Upload
      EndpointSummaryItem(
        id: 9,
        method: 'POST',
        path: '/events/{uuid}/upload/presign',
        requiresAuth: true,
        purpose: 'Presigned R2 URL — single file',
        category: EndpointCategory.upload,
        sampleBody: '{"filename": "photo.jpg", "mime_type": "image/jpeg", "file_size": 1048576}',
        expectedResponse: '{"upload_url": "https://r2.cloudflare...", "storage_path": "..."}',
      ),
      // 10. Presign Batch Upload
      EndpointSummaryItem(
        id: 10,
        method: 'POST',
        path: '/events/{uuid}/upload/presign-batch',
        requiresAuth: true,
        purpose: 'Presigned R2 URLs — up to 100 files',
        category: EndpointCategory.upload,
        sampleBody: '{"files": [{"filename": "img1.jpg", "file_size": 1000, "mime_type": "image/jpeg"}]}',
        expectedResponse: '{"files": [{"storage_path": "...", "upload_url": "..."}]}',
      ),
      // 11. Register Single Photo
      EndpointSummaryItem(
        id: 11,
        method: 'POST',
        path: '/events/{uuid}/upload/complete',
        requiresAuth: true,
        purpose: 'Register one uploaded photo in database',
        category: EndpointCategory.upload,
        sampleBody: '{"storage_path": "...", "filename": "photo.jpg", "mime_type": "image/jpeg"}',
        expectedResponse: '{"photo_id": "...", "status": "processed"}',
      ),
      // 12. Register Batch Photos
      EndpointSummaryItem(
        id: 12,
        method: 'POST',
        path: '/events/{uuid}/upload/register-batch',
        requiresAuth: true,
        purpose: 'Register up to 100 uploaded photos',
        category: EndpointCategory.upload,
        sampleBody: '{"photos": [{"storage_path": "...", "filename": "img1.jpg"}]}',
        expectedResponse: '{"registered_count": 1, "photos": [...]}',
      ),
      // 13. Mark Full-Res Original Complete
      EndpointSummaryItem(
        id: 13,
        method: 'POST',
        path: '/events/{uuid}/upload/original-complete',
        requiresAuth: true,
        purpose: 'Mark the full-res original uploaded',
        category: EndpointCategory.upload,
        sampleBody: '{"photo_id": "...", "original_storage_path": "..."}',
        expectedResponse: '{"success": true}',
      ),
      // 14. Attach Face Embeddings
      EndpointSummaryItem(
        id: 14,
        method: 'POST',
        path: '/events/{uuid}/upload/faces',
        requiresAuth: true,
        purpose: 'Attach client-side face embeddings',
        category: EndpointCategory.upload,
        sampleBody: '{"photo_id": "...", "embeddings": [[0.12, 0.45, ...]]}',
        expectedResponse: '{"faces_registered": 1}',
      ),
      // 15. Batch Complete Upload Session
      EndpointSummaryItem(
        id: 15,
        method: 'POST',
        path: '/events/{uuid}/upload/batch-complete',
        requiresAuth: true,
        purpose: 'Close an upload session & trigger processing',
        category: EndpointCategory.upload,
        sampleBody: '{"session_id": "sess_123", "total_files": 42}',
        expectedResponse: '{"session_id": "...", "status": "completed"}',
      ),
      // 16. Upload Sessions (History)
      EndpointSummaryItem(
        id: 16,
        method: 'GET',
        path: '/upload-sessions',
        requiresAuth: true,
        purpose: 'Upload history and session stats',
        category: EndpointCategory.history,
        sampleParams: '?page=1&per_page=20',
        expectedResponse: '{"data": [{"session_id": "...", "total_files": 120}]}',
      ),
      // 17. Subscription & Quota
      EndpointSummaryItem(
        id: 17,
        method: 'GET',
        path: '/subscription',
        requiresAuth: true,
        purpose: 'Plan, status, storage usage & limits',
        category: EndpointCategory.subscription,
        expectedResponse: '{"plan": "Pro", "storage_used_bytes": 5368709120, "storage_limit_bytes": 107374182400}',
      ),
      // 18. Read Watermark Config
      EndpointSummaryItem(
        id: 18,
        method: 'GET',
        path: '/watermark-settings',
        requiresAuth: true,
        purpose: 'Read watermark settings & overlay configuration',
        category: EndpointCategory.watermark,
        expectedResponse: '{"enabled": true, "text_content": "PhotoHouse Studio", "position": "bottom_right"}',
      ),
      // 19. Update Watermark Config
      EndpointSummaryItem(
        id: 19,
        method: 'PUT',
        path: '/watermark-settings',
        requiresAuth: true,
        purpose: 'Update studio watermark configuration',
        category: EndpointCategory.watermark,
        sampleBody: '{"enabled": true, "text_content": "Studio Proof", "opacity": 75}',
        expectedResponse: '{"enabled": true, "updated_at": "..."}',
      ),
      // 20. Desktop Check Update
      EndpointSummaryItem(
        id: 20,
        method: 'GET',
        path: '/desktop/check-update',
        requiresAuth: true,
        purpose: 'Check whether a newer Tauri desktop build is available',
        category: EndpointCategory.desktop,
        sampleParams: '?platform=macos_aarch64&current_version=1.0.0',
        expectedResponse: '{"has_update": false, "latest_version": "1.0.0"}',
      ),
      // 21. Desktop Latest Build
      EndpointSummaryItem(
        id: 21,
        method: 'GET',
        path: '/desktop/latest-build',
        requiresAuth: true,
        purpose: 'Get latest desktop build metadata',
        category: EndpointCategory.desktop,
        sampleParams: '?platform=windows_x64',
        expectedResponse: '{"version": "1.2.0", "platform": "windows_x64", "download_url": "..."}',
      ),
      // 22. Desktop Download Update
      EndpointSummaryItem(
        id: 22,
        method: 'GET',
        path: '/desktop/download-update',
        requiresAuth: true,
        purpose: '302 redirect to signed R2 download URL',
        category: EndpointCategory.desktop,
        sampleParams: '?platform=macos_x86_64&type=installer',
        expectedResponse: 'HTTP 302 Redirect -> https://pub-r2.photohouse.com/releases/...',
      ),
      // 23. Desktop Updater Manifest
      EndpointSummaryItem(
        id: 23,
        method: 'GET',
        path: '/desktop/updater-manifest',
        requiresAuth: true,
        purpose: 'Tauri updater manifest JSON endpoint',
        category: EndpointCategory.desktop,
        expectedResponse: '{"version": "1.2.0", "notes": "Bug fixes", "pub_date": "..."}',
      ),
    ];
  }

  /// Minimal integration checklist items from Section 11 of mobile-api.md
  static List<IntegrationChecklistItem> getIntegrationChecklist() {
    return const [
      IntegrationChecklistItem(
        step: 1,
        title: 'Platform Branding on Splash',
        description: 'Call GET /platform/branding on splash screen to theme the login interface dynamically.',
        endpointReference: 'GET /platform/branding',
      ),
      IntegrationChecklistItem(
        step: 2,
        title: 'Authentication & Keychain Token Storage',
        description: 'Call POST /auth/login with a stable device_name and securely store token in SecureStorage / Keychain.',
        endpointReference: 'POST /auth/login',
      ),
      IntegrationChecklistItem(
        step: 3,
        title: 'App Launch User Token Verification',
        description: 'Call GET /user on every app launch. Handle HTTP 401 response by resetting token and prompting re-login.',
        endpointReference: 'GET /user',
      ),
      IntegrationChecklistItem(
        step: 4,
        title: 'Events & Albums Selection',
        description: 'Call GET /events for event picker and GET /events/{uuid}/albums for specific album selection (album_id).',
        endpointReference: 'GET /events & GET /events/{uuid}/albums',
      ),
      IntegrationChecklistItem(
        step: 5,
        title: 'Direct R2 Chunked Upload Pipeline',
        description: 'Chunk selected photos into groups <= 100 -> presign-batch -> PUT bytes to Cloudflare R2 (concurrency 3-5) -> register-batch -> batch-complete.',
        endpointReference: 'POST /events/{uuid}/upload/presign-batch',
      ),
      IntegrationChecklistItem(
        step: 6,
        title: 'Upload Queue Persistence & Presign TTL',
        description: 'Persist the upload queue locally so uploads survive app restarts; re-presign URLs older than 60 minutes.',
        endpointReference: 'Presign TTL (60 mins)',
      ),
      IntegrationChecklistItem(
        step: 7,
        title: 'Quota Warning Before Large Uploads',
        description: 'Call GET /subscription before starting large upload batches to warn user when storage_percent is high (>85%).',
        endpointReference: 'GET /subscription',
      ),
      IntegrationChecklistItem(
        step: 8,
        title: 'Sign Out & Revoke Token',
        description: 'Call POST /auth/logout on sign-out to invalidate token on the server before clearing client storage.',
        endpointReference: 'POST /auth/logout',
      ),
    ];
  }
}
