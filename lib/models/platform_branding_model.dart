class PlatformBrandingModel {
  final String appName;
  final String? logoUrl;
  final String? logoDarkUrl;
  final String? logoLightUrl;
  final String? faviconUrl;
  final String? loadingGifUrl;

  const PlatformBrandingModel({
    required this.appName,
    this.logoUrl,
    this.logoDarkUrl,
    this.logoLightUrl,
    this.faviconUrl,
    this.loadingGifUrl,
  });

  static const PlatformBrandingModel defaultBranding = PlatformBrandingModel(
    appName: 'PhotoHouse',
  );

  factory PlatformBrandingModel.fromJson(Map<String, dynamic> json) {
    return PlatformBrandingModel(
      appName: json['app_name']?.toString() ?? 'PhotoHouse',
      logoUrl: json['logo_url']?.toString(),
      logoDarkUrl: json['logo_dark_url']?.toString(),
      logoLightUrl: json['logo_light_url']?.toString(),
      faviconUrl: json['favicon_url']?.toString(),
      loadingGifUrl: json['loading_gif_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'app_name': appName,
      'logo_url': logoUrl,
      'logo_dark_url': logoDarkUrl,
      'logo_light_url': logoLightUrl,
      'favicon_url': faviconUrl,
      'loading_gif_url': loadingGifUrl,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlatformBrandingModel &&
          runtimeType == other.runtimeType &&
          appName == other.appName &&
          logoUrl == other.logoUrl &&
          logoDarkUrl == other.logoDarkUrl &&
          logoLightUrl == other.logoLightUrl &&
          faviconUrl == other.faviconUrl &&
          loadingGifUrl == other.loadingGifUrl;

  @override
  int get hashCode =>
      appName.hashCode ^
      logoUrl.hashCode ^
      logoDarkUrl.hashCode ^
      logoLightUrl.hashCode ^
      faviconUrl.hashCode ^
      loadingGifUrl.hashCode;

  @override
  String toString() =>
      'PlatformBrandingModel(appName: $appName, logoUrl: $logoUrl, logoDarkUrl: $logoDarkUrl, logoLightUrl: $logoLightUrl, faviconUrl: $faviconUrl, loadingGifUrl: $loadingGifUrl)';
}
