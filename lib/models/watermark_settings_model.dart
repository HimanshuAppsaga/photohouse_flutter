class WatermarkSettingsModel {
  final bool enabled;
  final String type; // 'text' | 'logo'
  final String position; // 'top_left' | 'top_center' | 'top_right' | 'center_left' | 'center' | 'center_right' | 'bottom_left' | 'bottom_center' | 'bottom_right' | 'tiled'
  final int opacity; // 0-100
  final int scale; // 1-100
  final int margin; // 0-500
  final String? textContent; // max 255
  final int? textFontSize; // 8-200
  final String? textColor; // #RRGGBB
  final int? textRotation; // -180 to 180
  final String downloadOption; // 'watermarked' | 'original'
  final String? logoPath;
  final bool hasLogo;

  const WatermarkSettingsModel({
    this.enabled = true,
    this.type = 'text',
    this.position = 'bottom_right',
    this.opacity = 50,
    this.scale = 20,
    this.margin = 20,
    this.textContent = '',
    this.textFontSize = 32,
    this.textColor = '#FFFFFF',
    this.textRotation = 0,
    this.downloadOption = 'watermarked',
    this.logoPath,
    this.hasLogo = false,
  });

  /// Factory constructor to deserialize API JSON payload.
  factory WatermarkSettingsModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> data = json;
    if (json.containsKey('data') && json['data'] is Map<String, dynamic>) {
      data = json['data'] as Map<String, dynamic>;
    }

    int parseInt(dynamic val, int defaultVal) {
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? defaultVal;
      return defaultVal;
    }

    int? parseNullableInt(dynamic val) {
      if (val == null) return null;
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val);
      return null;
    }

    return WatermarkSettingsModel(
      enabled: data['enabled'] as bool? ?? true,
      type: (data['type'] as String?)?.toLowerCase() ?? 'text',
      position: (data['position'] as String?)?.toLowerCase() ?? 'bottom_right',
      opacity: parseInt(data['opacity'], 50),
      scale: parseInt(data['scale'], 20),
      margin: parseInt(data['margin'], 20),
      textContent: data['text_content'] as String?,
      textFontSize: parseNullableInt(data['text_font_size']),
      textColor: data['text_color'] as String?,
      textRotation: parseNullableInt(data['text_rotation']),
      downloadOption: (data['download_option'] as String?)?.toLowerCase() ?? 'watermarked',
      logoPath: data['logo_path'] as String?,
      hasLogo: data['has_logo'] as bool? ?? false,
    );
  }

  /// Converts model to JSON map for PUT update request payload.
  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'type': type,
      'position': position,
      'opacity': opacity,
      'scale': scale,
      'margin': margin,
      'text_content': textContent,
      'text_font_size': textFontSize,
      'text_color': textColor,
      'text_rotation': textRotation,
      'download_option': downloadOption,
    };
  }

  /// Creates a copy of model with specified updated values.
  WatermarkSettingsModel copyWith({
    bool? enabled,
    String? type,
    String? position,
    int? opacity,
    int? scale,
    int? margin,
    String? textContent,
    int? textFontSize,
    String? textColor,
    int? textRotation,
    String? downloadOption,
    String? logoPath,
    bool? hasLogo,
  }) {
    return WatermarkSettingsModel(
      enabled: enabled ?? this.enabled,
      type: type ?? this.type,
      position: position ?? this.position,
      opacity: opacity ?? this.opacity,
      scale: scale ?? this.scale,
      margin: margin ?? this.margin,
      textContent: textContent ?? this.textContent,
      textFontSize: textFontSize ?? this.textFontSize,
      textColor: textColor ?? this.textColor,
      textRotation: textRotation ?? this.textRotation,
      downloadOption: downloadOption ?? this.downloadOption,
      logoPath: logoPath ?? this.logoPath,
      hasLogo: hasLogo ?? this.hasLogo,
    );
  }

  // --- Helper Position & Option Mapping Utilities ---

  static const Map<String, String> positionDisplayMap = {
    'top_left': 'Top left',
    'top_center': 'Top center',
    'top_right': 'Top right',
    'center_left': 'Center left',
    'center': 'Center',
    'center_right': 'Center right',
    'bottom_left': 'Bottom left',
    'bottom_center': 'Bottom center',
    'bottom_right': 'Bottom right',
    'tiled': 'Tiled',
  };

  static const Map<String, String> displayToPositionMap = {
    'Top left': 'top_left',
    'Top center': 'top_center',
    'Top right': 'top_right',
    'Center left': 'center_left',
    'Center': 'center',
    'Center right': 'center_right',
    'Bottom left': 'bottom_left',
    'Bottom center': 'bottom_center',
    'Bottom right': 'bottom_right',
    'Tiled': 'tiled',
  };

  static const Map<String, String> downloadOptionDisplayMap = {
    'watermarked': 'Watermarked photo',
    'original': 'Original photo',
  };

  static const Map<String, String> displayToDownloadOptionMap = {
    'Watermarked photo': 'watermarked',
    'Original photo': 'original',
  };

  String get positionDisplayLabel => positionDisplayMap[position] ?? 'Bottom right';
  String get downloadOptionDisplayLabel => downloadOptionDisplayMap[downloadOption] ?? 'Watermarked photo';
  String get typeDisplayLabel => type == 'logo' ? 'Logo' : 'Text';

  static String displayToPosition(String display) => displayToPositionMap[display] ?? 'bottom_right';
  static String displayToDownloadOption(String display) => displayToDownloadOptionMap[display] ?? 'watermarked';
  static String displayToType(String display) => display.toLowerCase() == 'logo' ? 'logo' : 'text';
}
