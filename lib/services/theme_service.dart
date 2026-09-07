import 'package:flutter/material.dart';
import 'secure_storage_service.dart';

/// Central theme management API service for handling dark mode, light mode,
/// and system preference theme persistence and dynamic updates.
class ThemeService {
  ThemeService._internal();
  static final ThemeService instance = ThemeService._internal();

  final SecureStorageService _storage = SecureStorageService();
  final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.dark);

  static const String _storageKey = 'app_theme_option';
  String _currentThemeOption = 'Dark';

  /// Currently selected theme option string ('System', 'Dark', 'Light')
  String get currentThemeOption => _currentThemeOption;

  /// Currently active ThemeMode enum
  ThemeMode get currentThemeMode => themeModeNotifier.value;

  /// List of supported theme option names
  List<String> get availableThemes => const ['System', 'Dark', 'Light'];

  /// Initialize theme mode from persisted secure storage on app launch
  Future<void> init() async {
    final savedOption = await _storage.readKey(_storageKey);
    if (savedOption != null && savedOption.isNotEmpty) {
      _currentThemeOption = savedOption;
    } else {
      _currentThemeOption = 'Dark';
    }
    themeModeNotifier.value = _mapOptionToMode(_currentThemeOption);
  }

  /// Update theme mode preference and persist selection
  Future<void> saveThemeOption(String option) async {
    _currentThemeOption = option;
    await _storage.writeKey(_storageKey, option);
    themeModeNotifier.value = _mapOptionToMode(option);
  }

  /// Convenience toggle between Dark and Light mode
  Future<void> toggleTheme(BuildContext context) async {
    final isDarkNow = Theme.of(context).brightness == Brightness.dark;
    final nextOption = isDarkNow ? 'Light' : 'Dark';
    await saveThemeOption(nextOption);
  }

  /// Helper to check if current effective brightness is dark
  bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  ThemeMode _mapOptionToMode(String option) {
    switch (option.toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.dark;
    }
  }
}
