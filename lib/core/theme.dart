import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
// AppColors — uygulamanın renk sabitlerini tek yerden yönetir.
// Tüm widget'lar Theme.of(context).extension<AppColors>()
// üzerinden erişir.
// ─────────────────────────────────────────────────────────────
class AppColors extends ThemeExtension<AppColors> {
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color border;
  final Color inputFill;
  final Color textDark;
  final Color textMid;
  final Color textLight;
  final Color primaryTeal;
  final Color primaryTealSoft;
  final Color primaryBlue;
  final Color primaryBlueSoft;
  final Color success;
  final Color successBg;
  final Color danger;
  final Color dangerBg;
  final Color warning;
  final Color warningBg;

  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.border,
    required this.inputFill,
    required this.textDark,
    required this.textMid,
    required this.textLight,
    required this.primaryTeal,
    required this.primaryTealSoft,
    required this.primaryBlue,
    required this.primaryBlueSoft,
    required this.success,
    required this.successBg,
    required this.danger,
    required this.dangerBg,
    required this.warning,
    required this.warningBg,
  });

  // ── LIGHT ──────────────────────────────────────────────────
  static const light = AppColors(
    background: Color(0xFFF8F9FC),
    surface: Colors.white,
    surfaceVariant: Color(0xFFF1F5F9),
    border: Color(0xFFE2E8F0),
    inputFill: Color(0xFFF1F5F9),
    textDark: Color(0xFF1E293B),
    textMid: Color(0xFF64748B),
    textLight: Color(0xFF94A3B8),
    primaryTeal: Color(0xFF0F766E),
    primaryTealSoft: Color(0xFFE7F5F3),
    primaryBlue: Color(0xFF2563EB),
    primaryBlueSoft: Color(0xFFEFF6FF),
    success: Color(0xFF0A8C3B),
    successBg: Color(0xFFE9F7EE),
    danger: Color(0xFFDC2626),
    dangerBg: Color(0xFFFEE2E2),
    warning: Color(0xFFF59E0B),
    warningBg: Color(0xFFFEF3C7),
  );

  // ── DARK ───────────────────────────────────────────────────
  static const dark = AppColors(
    background: Color(0xFF0F1117),
    surface: Color(0xFF1A1D27),
    surfaceVariant: Color(0xFF252836),
    border: Color(0xFF2E3347),
    inputFill: Color(0xFF252836),
    textDark: Color(0xFFF1F5F9),
    textMid: Color(0xFF94A3B8),
    textLight: Color(0xFF64748B),
    primaryTeal: Color(0xFF14B8A6),
    primaryTealSoft: Color(0xFF0F2B28),
    primaryBlue: Color(0xFF3B82F6),
    primaryBlueSoft: Color(0xFF0F1D3B),
    success: Color(0xFF34D399),
    successBg: Color(0xFF052E16),
    danger: Color(0xFFF87171),
    dangerBg: Color(0xFF3B0F0F),
    warning: Color(0xFFFBBF24),
    warningBg: Color(0xFF3B2800),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? border,
    Color? inputFill,
    Color? textDark,
    Color? textMid,
    Color? textLight,
    Color? primaryTeal,
    Color? primaryTealSoft,
    Color? primaryBlue,
    Color? primaryBlueSoft,
    Color? success,
    Color? successBg,
    Color? danger,
    Color? dangerBg,
    Color? warning,
    Color? warningBg,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      border: border ?? this.border,
      inputFill: inputFill ?? this.inputFill,
      textDark: textDark ?? this.textDark,
      textMid: textMid ?? this.textMid,
      textLight: textLight ?? this.textLight,
      primaryTeal: primaryTeal ?? this.primaryTeal,
      primaryTealSoft: primaryTealSoft ?? this.primaryTealSoft,
      primaryBlue: primaryBlue ?? this.primaryBlue,
      primaryBlueSoft: primaryBlueSoft ?? this.primaryBlueSoft,
      success: success ?? this.success,
      successBg: successBg ?? this.successBg,
      danger: danger ?? this.danger,
      dangerBg: dangerBg ?? this.dangerBg,
      warning: warning ?? this.warning,
      warningBg: warningBg ?? this.warningBg,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      border: Color.lerp(border, other.border, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
      textDark: Color.lerp(textDark, other.textDark, t)!,
      textMid: Color.lerp(textMid, other.textMid, t)!,
      textLight: Color.lerp(textLight, other.textLight, t)!,
      primaryTeal: Color.lerp(primaryTeal, other.primaryTeal, t)!,
      primaryTealSoft: Color.lerp(primaryTealSoft, other.primaryTealSoft, t)!,
      primaryBlue: Color.lerp(primaryBlue, other.primaryBlue, t)!,
      primaryBlueSoft: Color.lerp(primaryBlueSoft, other.primaryBlueSoft, t)!,
      success: Color.lerp(success, other.success, t)!,
      successBg: Color.lerp(successBg, other.successBg, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerBg: Color.lerp(dangerBg, other.dangerBg, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningBg: Color.lerp(warningBg, other.warningBg, t)!,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Kolaylık uzantısı — context.colors ile erişim
// ─────────────────────────────────────────────────────────────
extension AppColorsContext on BuildContext {
  AppColors get colors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;
}

// ─────────────────────────────────────────────────────────────
// NeuraTheme
// ─────────────────────────────────────────────────────────────
class NeuraTheme {
  static const Color primary = Color(0xFF2260FF);
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Colors.white;
  static const Color textDark = Color(0xFF1E293B);
  static const Color textGrey = Color(0xFF94A3B8);

  static ThemeData get theme => lightTheme;

  static ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.light.background,
        cardColor: AppColors.light.surface,
        dividerColor: AppColors.light.border,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.light.surface,
          foregroundColor: AppColors.light.textDark,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        drawerTheme: DrawerThemeData(
          backgroundColor: AppColors.light.surface,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppColors.light.surface,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.light.inputFill,
        ),
        extensions: const [AppColors.light],
      );

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF14B8A6),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.dark.background,
        cardColor: AppColors.dark.surface,
        dividerColor: AppColors.dark.border,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.dark.surface,
          foregroundColor: AppColors.dark.textDark,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        drawerTheme: DrawerThemeData(
          backgroundColor: AppColors.dark.surface,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppColors.dark.surface,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.dark.inputFill,
        ),
        extensions: const [AppColors.dark],
      );
}
