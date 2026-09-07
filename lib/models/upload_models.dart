class PresignFileItem {
  final String clientId;
  final String filename;
  final String mimeType;
  final int fileSize;
  final List<String>? derivatives;

  const PresignFileItem({
    required this.clientId,
    required this.filename,
    required this.mimeType,
    required this.fileSize,
    this.derivatives,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'client_id': clientId,
      'filename': filename,
      'mime_type': mimeType,
      'file_size': fileSize,
    };
    if (derivatives != null && derivatives!.isNotEmpty) {
      map['derivatives'] = derivatives;
    }
    return map;
  }
}

class PresignedDerivativeItem {
  final String presignedUrl;
  final String storagePath;
  final String uploadVia;

  const PresignedDerivativeItem({
    required this.presignedUrl,
    required this.storagePath,
    required this.uploadVia,
  });

  factory PresignedDerivativeItem.fromJson(Map<String, dynamic> json) {
    return PresignedDerivativeItem(
      presignedUrl: json['presigned_url'] as String? ?? '',
      storagePath: json['storage_path'] as String? ?? '',
      uploadVia: json['upload_via'] as String? ?? 'r2',
    );
  }

  Map<String, dynamic> toJson() => {
        'presigned_url': presignedUrl,
        'storage_path': storagePath,
        'upload_via': uploadVia,
      };
}

class PresignedUploadItem {
  final String? clientId;
  final String presignedUrl;
  final String storagePath;
  final String uploadVia;
  final Map<String, PresignedDerivativeItem>? derivatives;

  const PresignedUploadItem({
    this.clientId,
    required this.presignedUrl,
    required this.storagePath,
    this.uploadVia = 'r2',
    this.derivatives,
  });

  factory PresignedUploadItem.fromJson(Map<String, dynamic> json) {
    Map<String, PresignedDerivativeItem>? derivMap;
    if (json['derivatives'] is Map<String, dynamic>) {
      derivMap = (json['derivatives'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          key,
          PresignedDerivativeItem.fromJson(value as Map<String, dynamic>),
        ),
      );
    }

    return PresignedUploadItem(
      clientId: json['client_id'] as String?,
      presignedUrl: json['presigned_url'] as String? ?? '',
      storagePath: json['storage_path'] as String? ?? '',
      uploadVia: json['upload_via'] as String? ?? 'r2',
      derivatives: derivMap,
    );
  }
}

class PresignBatchResponse {
  final List<PresignedUploadItem> uploads;

  const PresignBatchResponse({required this.uploads});

  factory PresignBatchResponse.fromJson(Map<String, dynamic> json) {
    final List<PresignedUploadItem> list = [];
    if (json['uploads'] is List) {
      for (final item in (json['uploads'] as List)) {
        if (item is Map<String, dynamic>) {
          list.add(PresignedUploadItem.fromJson(item));
        }
      }
    }
    return PresignBatchResponse(uploads: list);
  }
}

class RegisterUploadItem {
  final String? clientId;
  final String storagePath;
  final String filename;
  final String mimeType;
  final int fileSize;
  final int? albumId;
  final Map<String, dynamic>? media;
  final List<Map<String, dynamic>>? faces;

  const RegisterUploadItem({
    this.clientId,
    required this.storagePath,
    required this.filename,
    required this.mimeType,
    required this.fileSize,
    this.albumId,
    this.media,
    this.faces,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      if (clientId != null) 'client_id': clientId,
      'storage_path': storagePath,
      'filename': filename,
      'mime_type': mimeType,
      'file_size': fileSize,
    };
    if (albumId != null) map['album_id'] = albumId;
    if (media != null) map['media'] = media;
    if (faces != null) map['faces'] = faces;
    return map;
  }
}

class RegisteredPhotoItem {
  final String? clientId;
  final int photoId;
  final String photoUuid;
  final String status;

  const RegisteredPhotoItem({
    this.clientId,
    required this.photoId,
    required this.photoUuid,
    required this.status,
  });

  factory RegisteredPhotoItem.fromJson(Map<String, dynamic> json) {
    return RegisteredPhotoItem(
      clientId: json['client_id'] as String?,
      photoId: json['photo_id'] as int? ?? 0,
      photoUuid: json['photo_uuid'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
    );
  }
}

class RegisterBatchResponse {
  final List<RegisteredPhotoItem> photos;

  const RegisterBatchResponse({required this.photos});

  factory RegisterBatchResponse.fromJson(Map<String, dynamic> json) {
    final List<RegisteredPhotoItem> list = [];
    if (json['photos'] is List) {
      for (final item in (json['photos'] as List)) {
        if (item is Map<String, dynamic>) {
          list.add(RegisteredPhotoItem.fromJson(item));
        }
      }
    }
    return RegisterBatchResponse(photos: list);
  }
}

class BatchCompleteRequest {
  final int totalFiles;
  final int completedFiles;
  final int failedFiles;
  final int? albumId;

  const BatchCompleteRequest({
    required this.totalFiles,
    required this.completedFiles,
    required this.failedFiles,
    this.albumId,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'total_files': totalFiles,
      'completed_files': completedFiles,
      'failed_files': failedFiles,
    };
    if (albumId != null) map['album_id'] = albumId;
    return map;
  }
}

class BatchCompleteResponse {
  final String sessionUuid;
  final String status;

  const BatchCompleteResponse({
    required this.sessionUuid,
    required this.status,
  });

  factory BatchCompleteResponse.fromJson(Map<String, dynamic> json) {
    return BatchCompleteResponse(
      sessionUuid: json['session_uuid'] as String? ?? '',
      status: json['status'] as String? ?? 'completed',
    );
  }
}

class UploadSessionItem {
  final String uuid;
  final String eventUuid;
  final int? albumId;
  final String source;
  final int totalFiles;
  final int completedFiles;
  final int failedFiles;
  final String status;
  final String? completedAt;
  final String createdAt;
  final String updatedAt;

  const UploadSessionItem({
    required this.uuid,
    required this.eventUuid,
    this.albumId,
    required this.source,
    required this.totalFiles,
    required this.completedFiles,
    required this.failedFiles,
    required this.status,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UploadSessionItem.fromJson(Map<String, dynamic> json) {
    return UploadSessionItem(
      uuid: json['uuid'] as String? ?? '',
      eventUuid: json['event_uuid'] as String? ?? '',
      albumId: json['album_id'] as int?,
      source: json['source'] as String? ?? 'desktop_agent',
      totalFiles: json['total_files'] as int? ?? 0,
      completedFiles: json['completed_files'] as int? ?? 0,
      failedFiles: json['failed_files'] as int? ?? 0,
      status: json['status'] as String? ?? 'pending',
      completedAt: json['completed_at'] as String?,
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'event_uuid': eventUuid,
        if (albumId != null) 'album_id': albumId,
        'source': source,
        'total_files': totalFiles,
        'completed_files': completedFiles,
        'failed_files': failedFiles,
        'status': status,
        if (completedAt != null) 'completed_at': completedAt,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  double get completionProgress =>
      totalFiles > 0 ? (completedFiles / totalFiles).clamp(0.0, 1.0) : 0.0;

  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isActive => status == 'active' || status == 'pending';

  String get formattedSource {
    switch (source.toLowerCase()) {
      case 'desktop_agent':
        return 'Desktop Agent';
      case 'browser':
        return 'Browser';
      case 'ftp':
        return 'FTP';
      default:
        return source;
    }
  }
}

class UploadSessionsResponse {
  final List<UploadSessionItem> sessions;
  final String? nextCursor;

  const UploadSessionsResponse({
    required this.sessions,
    this.nextCursor,
  });

  factory UploadSessionsResponse.fromJson(Map<String, dynamic> json) {
    final List<UploadSessionItem> list = [];
    if (json['data'] is List) {
      for (final item in (json['data'] as List)) {
        if (item is Map<String, dynamic>) {
          list.add(UploadSessionItem.fromJson(item));
        }
      }
    }
    String? nextCursor;
    if (json['meta'] is Map<String, dynamic>) {
      nextCursor = (json['meta'] as Map<String, dynamic>)['next_cursor'] as String?;
    }
    return UploadSessionsResponse(
      sessions: list,
      nextCursor: nextCursor,
    );
  }

  Map<String, dynamic> toJson() => {
        'data': sessions.map((s) => s.toJson()).toList(),
        'meta': {'next_cursor': nextCursor},
      };
}

/// Helper model representing a file queued for upload locally
class QueueUploadFile {
  final String clientId;
  final String filePath;
  final String filename;
  final String mimeType;
  final int fileSize;
  final int? albumId;
  double progress;
  String status; // 'pending', 'presigned', 'uploading', 'registered', 'failed'
  String? error;
  String? storagePath;
  String? presignedUrl;
  DateTime? presignedAt;

  QueueUploadFile({
    required this.clientId,
    required this.filePath,
    required this.filename,
    required this.mimeType,
    required this.fileSize,
    this.albumId,
    this.progress = 0.0,
    this.status = 'pending',
    this.error,
    this.storagePath,
    this.presignedUrl,
    this.presignedAt,
  });

  /// Check whether the R2 presigned URL is missing or older than 55 minutes
  /// (Presigned URLs are valid for 60 minutes).
  bool get isPresignExpired {
    if (presignedUrl == null || presignedUrl!.isEmpty || presignedAt == null) {
      return true;
    }
    final ageMinutes = DateTime.now().difference(presignedAt!).inMinutes;
    return ageMinutes >= 55;
  }

  Map<String, dynamic> toJson() => {
        'client_id': clientId,
        'file_path': filePath,
        'filename': filename,
        'mime_type': mimeType,
        'file_size': fileSize,
        if (albumId != null) 'album_id': albumId,
        'progress': progress,
        'status': status,
        if (error != null) 'error': error,
        if (storagePath != null) 'storage_path': storagePath,
        if (presignedUrl != null) 'presigned_url': presignedUrl,
        if (presignedAt != null) 'presigned_at': presignedAt!.toIso8601String(),
      };

  factory QueueUploadFile.fromJson(Map<String, dynamic> json) {
    return QueueUploadFile(
      clientId: json['client_id'] as String? ?? '',
      filePath: json['file_path'] as String? ?? '',
      filename: json['filename'] as String? ?? '',
      mimeType: json['mime_type'] as String? ?? 'image/jpeg',
      fileSize: json['file_size'] as int? ?? 0,
      albumId: json['album_id'] as int?,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'pending',
      error: json['error'] as String?,
      storagePath: json['storage_path'] as String?,
      presignedUrl: json['presigned_url'] as String?,
      presignedAt: json['presigned_at'] != null
          ? DateTime.tryParse(json['presigned_at'] as String)
          : null,
    );
  }
}

