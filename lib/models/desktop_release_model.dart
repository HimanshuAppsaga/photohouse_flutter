/// Represents the response from `GET /api/v1/desktop/check-update`
class DesktopCheckUpdateModel {

  final bool hasUpdate;
  final String latestVersion;
  final String? currentVersion;
  final String? releaseNotes;
  final String? pubDate;
  final String? downloadUrl;
  final String? signature;
  final String? platform;

  const DesktopCheckUpdateModel({
    required this.hasUpdate,
    required this.latestVersion,
    this.currentVersion,
    this.releaseNotes,
    this.pubDate,
    this.downloadUrl,
    this.signature,
    this.platform,
  });

  factory DesktopCheckUpdateModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> map =
        json.containsKey('data') && json['data'] is Map<String, dynamic>
            ? json['data'] as Map<String, dynamic>
            : json;

    return DesktopCheckUpdateModel(
      hasUpdate: map['has_update'] as bool? ??
          map['update_available'] as bool? ??
          (map['version'] != null && map['version'] != map['current_version']),
      latestVersion: (map['latest_version'] ?? map['version'] ?? '1.0.0').toString(),
      currentVersion: map['current_version']?.toString(),
      releaseNotes: (map['release_notes'] ?? map['notes'] ?? map['body'])?.toString(),
      pubDate: (map['pub_date'] ?? map['published_at'] ?? map['release_date'])?.toString(),
      downloadUrl: (map['download_url'] ?? map['url'])?.toString(),
      signature: map['signature']?.toString(),
      platform: map['platform']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'has_update': hasUpdate,
      'latest_version': latestVersion,
      if (currentVersion != null) 'current_version': currentVersion,
      if (releaseNotes != null) 'release_notes': releaseNotes,
      if (pubDate != null) 'pub_date': pubDate,
      if (downloadUrl != null) 'download_url': downloadUrl,
      if (signature != null) 'signature': signature,
      if (platform != null) 'platform': platform,
    };
  }

  @override
  String toString() {
    return 'DesktopCheckUpdateModel(hasUpdate: $hasUpdate, latestVersion: $latestVersion, downloadUrl: $downloadUrl)';
  }
}

/// Represents the response from `GET /api/v1/desktop/latest-build`
class DesktopLatestBuildModel {
  final String version;
  final String platform;
  final String? notes;
  final String? pubDate;
  final String? downloadUrl;
  final String? installerUrl;
  final String? updaterUrl;
  final String? signature;
  final int? fileSizeBytes;
  final String? minOsVersion;

  const DesktopLatestBuildModel({
    required this.version,
    required this.platform,
    this.notes,
    this.pubDate,
    this.downloadUrl,
    this.installerUrl,
    this.updaterUrl,
    this.signature,
    this.fileSizeBytes,
    this.minOsVersion,
  });

  factory DesktopLatestBuildModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> map =
        json.containsKey('data') && json['data'] is Map<String, dynamic>
            ? json['data'] as Map<String, dynamic>
            : json;

    return DesktopLatestBuildModel(
      version: (map['version'] ?? map['latest_version'] ?? '1.0.0').toString(),
      platform: (map['platform'] ?? 'macos_aarch64').toString(),
      notes: (map['notes'] ?? map['release_notes'] ?? map['changelog'])?.toString(),
      pubDate: (map['pub_date'] ?? map['published_at'] ?? map['created_at'])?.toString(),
      downloadUrl: (map['download_url'] ?? map['url'])?.toString(),
      installerUrl: (map['installer_url'] ?? map['download_installer_url'])?.toString(),
      updaterUrl: (map['updater_url'] ?? map['download_updater_url'])?.toString(),
      signature: map['signature']?.toString(),
      fileSizeBytes: map['file_size'] is int
          ? map['file_size'] as int
          : (map['file_size_bytes'] is int
              ? map['file_size_bytes'] as int
              : int.tryParse(map['file_size']?.toString() ?? '')),
      minOsVersion: (map['min_os_version'] ?? map['minimum_os'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'platform': platform,
      if (notes != null) 'notes': notes,
      if (pubDate != null) 'pub_date': pubDate,
      if (downloadUrl != null) 'download_url': downloadUrl,
      if (installerUrl != null) 'installer_url': installerUrl,
      if (updaterUrl != null) 'updater_url': updaterUrl,
      if (signature != null) 'signature': signature,
      if (fileSizeBytes != null) 'file_size': fileSizeBytes,
      if (minOsVersion != null) 'min_os_version': minOsVersion,
    };
  }

  @override
  String toString() {
    return 'DesktopLatestBuildModel(version: $version, platform: $platform, downloadUrl: $downloadUrl)';
  }
}

/// Represents the response from `GET /api/v1/desktop/download-update`
class DesktopDownloadResponseModel {
  final String downloadUrl;
  final String? platform;
  final String? type;
  final int statusCode;

  const DesktopDownloadResponseModel({
    required this.downloadUrl,
    this.platform,
    this.type,
    this.statusCode = 200,
  });

  factory DesktopDownloadResponseModel.fromJson(Map<String, dynamic> json, {int statusCode = 200}) {
    final Map<String, dynamic> map =
        json.containsKey('data') && json['data'] is Map<String, dynamic>
            ? json['data'] as Map<String, dynamic>
            : json;

    return DesktopDownloadResponseModel(
      downloadUrl: (map['download_url'] ?? map['url'] ?? map['location'] ?? '').toString(),
      platform: map['platform']?.toString(),
      type: map['type']?.toString(),
      statusCode: statusCode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'download_url': downloadUrl,
      if (platform != null) 'platform': platform,
      if (type != null) 'type': type,
      'status_code': statusCode,
    };
  }
}

/// Represents individual platform release details in Tauri updater manifest
class TauriPlatformReleaseModel {
  final String? signature;
  final String? url;

  const TauriPlatformReleaseModel({
    this.signature,
    this.url,
  });

  factory TauriPlatformReleaseModel.fromJson(Map<String, dynamic> json) {
    return TauriPlatformReleaseModel(
      signature: json['signature']?.toString(),
      url: json['url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (signature != null) 'signature': signature,
      if (url != null) 'url': url,
    };
  }
}

/// Represents response from `GET /api/v1/desktop/updater-manifest` (Tauri standard manifest)
class TauriUpdaterManifestModel {
  final String version;
  final String? notes;
  final String? pubDate;
  final Map<String, TauriPlatformReleaseModel> platforms;

  const TauriUpdaterManifestModel({
    required this.version,
    this.notes,
    this.pubDate,
    required this.platforms,
  });

  factory TauriUpdaterManifestModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> root =
        json.containsKey('data') && json['data'] is Map<String, dynamic>
            ? json['data'] as Map<String, dynamic>
            : json;

    final platformsMap = <String, TauriPlatformReleaseModel>{};
    if (root.containsKey('platforms') && root['platforms'] is Map<String, dynamic>) {
      final pMap = root['platforms'] as Map<String, dynamic>;
      pMap.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          platformsMap[key] = TauriPlatformReleaseModel.fromJson(value);
        }
      });
    }

    return TauriUpdaterManifestModel(
      version: (root['version'] ?? '1.0.0').toString(),
      notes: (root['notes'] ?? root['release_notes'])?.toString(),
      pubDate: (root['pub_date'] ?? root['published_at'])?.toString(),
      platforms: platformsMap,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      if (notes != null) 'notes': notes,
      if (pubDate != null) 'pub_date': pubDate,
      'platforms': platforms.map((key, value) => MapEntry(key, value.toJson())),
    };
  }
}
