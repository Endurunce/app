import 'package:flutter/material.dart';

class AppColors {
  static const bg        = Color(0xFFF7F3EE);
  static const surface   = Color(0xFFFFFCF8);
  static const surface2  = Color(0xFFF0EBE3);
  static const border    = Color(0xFFE2D9CE);
  static const ink       = Color(0xFF2D2720);
  static const inkMid    = Color(0xFF7A6E64);
  static const inkLight  = Color(0xFFA89E93);
  static const moss      = Color(0xFF5A7A52);
  static const mossDim   = Color(0xFFDEEBD8);
  static const sage      = Color(0xFF8AAB7E);
  static const terra     = Color(0xFFB85C3A);
  static const terraDim  = Color(0xFFF5DDD5);
  static const sand      = Color(0xFFC49A5A);
  static const sandDim   = Color(0xFFF5E8CC);
  static const sky       = Color(0xFF4A7FA0);
  static const skyDim    = Color(0xFFD6E8F5);
  static const lavender  = Color(0xFF7A6AAA);
  static const lavDim    = Color(0xFFE8E3F5);
  static const stone     = Color(0xFF9E9488);
  static const stoneDim  = Color(0xFFEDE8E2);
  static const gold      = Color(0xFFB8862A);
  static const goldDim   = Color(0xFFF5E8C0);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.light(
      primary:   AppColors.moss,
      secondary: AppColors.sand,
      surface:   AppColors.surface,
      error:     AppColors.terra,
      onPrimary: Colors.white,
      onSurface: AppColors.ink,
    ),
    fontFamily: 'sans-serif',
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.ink,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Georgia',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.moss, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.moss,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        elevation: 0,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.moss),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, space: 1),
  );
}
