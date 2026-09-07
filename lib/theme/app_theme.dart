import 'package:flutter/material.dart';

class AppColors {
  // Dark Theme Palette (Zinc / Amber)
  static const Color bgDarker = Color(0xFF09090B); // Zinc 950
  static const Color bgDark = Color(0xFF141416); // Zinc 900
  static const Color cardBg = Color(0xFF1E1E22); // Zinc 850
  static const Color cardSurface = Color(0xFF27272A); // Zinc 800
  static const Color border = Color(0xFF3F3F46); // Zinc 700
  static const Color borderSubtle = Color(0xFF27272A);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFD4D4D8); // Zinc 300
  static const Color textMuted = Color(0xFFA1A1AA); // Zinc 400

  // Light Theme Palette (Slate / Amber)
  static const Color bgDarkerLight = Color(0xFFF8FAFC); // Slate 50
  static const Color bgDarkLight = Color(0xFFF1F5F9); // Slate 100
  static const Color cardBgLight = Color(0xFFFFFFFF); // White
  static const Color cardSurfaceLight = Color(0xFFF1F5F9); // Slate 100
  static const Color borderLight = Color(0xFFE2E8F0); // Slate 200
  static const Color borderSubtleLight = Color(0xFFF1F5F9);
  static const Color textPrimaryLight = Color(0xFF0F172A); // Slate 900
  static const Color textSecondaryLight = Color(0xFF334155); // Slate 700
  static const Color textMutedLight = Color(0xFF64748B); // Slate 500

  // Accent Colors (Cohesive across themes)
  static const Color accentAmber = Color(0xFFF59E0B); // Amber 500
  static const Color accentOrange = Color(0xFFD97706); // Amber 600
  static const Color dangerRed = Color(0xFFEF4444); // Red 500
  static const Color successGreen = Color(0xFF10B981); // Emerald 500
}

class AppThemePalette {
  final Brightness brightness;

  AppThemePalette._(this.brightness);

  factory AppThemePalette.of(BuildContext context) {
    return AppThemePalette._(Theme.of(context).brightness);
  }

  bool get isDark => brightness == Brightness.dark;
  bool get isDarkMode => isDark;

  Color get bgDarker => isDark ? AppColors.bgDarker : AppColors.bgDarkerLight;
  Color get bgDark => isDark ? AppColors.bgDark : AppColors.bgDarkLight;
  Color get cardBg => isDark ? AppColors.cardBg : AppColors.cardBgLight;
  Color get cardSurface => isDark ? AppColors.cardSurface : AppColors.cardSurfaceLight;
  Color get cardBgElevated => cardSurface;
  Color get bgElevated => cardSurface;
  Color get inputBg => isDark ? AppColors.cardSurface : AppColors.bgDarkLight;
  Color get border => isDark ? AppColors.border : AppColors.borderLight;
  Color get borderSubtle => isDark ? AppColors.borderSubtle : AppColors.borderSubtleLight;

  Color get accentAmber => AppColors.accentAmber;
  Color get accentOrange => AppColors.accentOrange;
  Color get accentPrimary => accentAmber;
  Color get dangerRed => AppColors.dangerRed;
  Color get danger => dangerRed;
  Color get successGreen => AppColors.successGreen;
  Color get success => successGreen;

  Color get textPrimary => isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;
  Color get textSecondary => isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;
  Color get textMuted => isDark ? AppColors.textMuted : AppColors.textMutedLight;
}

extension BuildContextThemeX on BuildContext {
  AppThemePalette get palette => AppThemePalette.of(this);
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  ThemeData get theme => Theme.of(this);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgDarker,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentAmber,
        secondary: AppColors.accentOrange,
        surface: AppColors.cardBg,
        error: AppColors.dangerRed,
        onPrimary: AppColors.bgDarker,
        onSurface: AppColors.textPrimary,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgDarker,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return const Color(0xFFA1A1AA);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accentAmber;
          }
          return AppColors.cardSurface;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return AppColors.border;
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.cardSurface,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w500),
        actionTextColor: AppColors.accentAmber,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bgDarkerLight,
      colorScheme: const ColorScheme.light(
        primary: AppColors.accentAmber,
        secondary: AppColors.accentOrange,
        surface: AppColors.cardBgLight,
        error: AppColors.dangerRed,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimaryLight,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBgLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgDarkerLight,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimaryLight,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimaryLight),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return const Color(0xFF71717A);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accentAmber;
          }
          return const Color(0xFFE4E4E7);
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return AppColors.borderLight;
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.cardBgLight,
        contentTextStyle: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 13.5, fontWeight: FontWeight.w500),
        actionTextColor: AppColors.accentAmber,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.borderLight),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class AppTextStyles {
  // Context-aware dynamic text styles
  static TextStyle overlineOf(BuildContext context) {
    return TextStyle(
      color: AppThemePalette.of(context).accentAmber,
      fontSize: 11,
      fontWeight: FontWeight.w800,
      letterSpacing: 2.2,
    );
  }

  static TextStyle displayHeadingOf(BuildContext context) {
    return TextStyle(
      color: AppThemePalette.of(context).textPrimary,
      fontSize: 28,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.8,
      height: 1.2,
    );
  }

  static TextStyle subTitleOf(BuildContext context) {
    return TextStyle(
      color: AppThemePalette.of(context).textMuted,
      fontSize: 13.5,
      fontWeight: FontWeight.w400,
      height: 1.4,
    );
  }

  static TextStyle cardTitleOf(BuildContext context) {
    return TextStyle(
      color: AppThemePalette.of(context).textPrimary,
      fontSize: 18,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
    );
  }

  static TextStyle statLabelOf(BuildContext context) {
    return TextStyle(
      color: AppThemePalette.of(context).textMuted,
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    );
  }

  // Static backward-compatible definitions
  static const TextStyle overline = TextStyle(
    color: AppColors.accentAmber,
    fontSize: 11,
    fontWeight: FontWeight.w800,
    letterSpacing: 2.2,
  );

  static const TextStyle displayHeading = TextStyle(
    color: Colors.white,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
    height: 1.2,
  );

  static const TextStyle subTitle = TextStyle(
    color: AppColors.textMuted,
    fontSize: 13.5,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static const TextStyle cardTitle = TextStyle(
    color: Colors.white,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
  );

  static const TextStyle cardTag = TextStyle(
    color: AppColors.accentAmber,
    fontSize: 10.5,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.6,
  );

  static const TextStyle statValue = TextStyle(
    color: Colors.white,
    fontSize: 17,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4,
  );

  static const TextStyle statLabel = TextStyle(
    color: AppColors.textMuted,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  static const TextStyle buttonText = TextStyle(
    color: AppColors.accentAmber,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
  );
}
