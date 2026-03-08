import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Brand palette ────────────────────────────────────────────────────────────
class AppColors {
  // Brand
  static const brand     = Color(0xFFFF7043); // Primary orange
  static const brandDeep = Color(0xFFE53935); // Deep red accent

  // Dark backgrounds (layered)
  static const bg            = Color(0xFF0D0D16); // Canvas
  static const surface       = Color(0xFF14141E); // Cards, sheets
  static const surfaceHigh   = Color(0xFF1C1C2A); // Elevated cards
  static const surfaceHigher = Color(0xFF242436); // Modals, tooltips

  // Borders & dividers
  static const outline     = Color(0xFF2A2A3C);
  static const outlineHigh = Color(0xFF3A3A50);

  // Text
  static const onBg      = Color(0xFFEEEEF8); // Primary text
  static const onSurface = Color(0xFFCCCCDC); // Secondary text
  static const muted     = Color(0xFF7070A0); // Placeholder / hints
  static const disabled  = Color(0xFF44445A); // Disabled state

  // Semantic
  static const success    = Color(0xFF4CAF82);
  static const successDim = Color(0xFF152B22);
  static const warning    = Color(0xFFFFC107);
  static const warningDim = Color(0xFF2C2210);
  static const error      = Color(0xFFEF5350);
  static const errorDim   = Color(0xFF2D1414);

  // Session colors (dark-optimised)
  static const easy     = Color(0xFF4CAF82);
  static const easyDim  = Color(0xFF152B22);
  static const tempo    = Color(0xFFFF7043);
  static const tempoDim = Color(0xFF2D1A12);
  static const longRun  = Color(0xFF5BA4D4);
  static const longDim  = Color(0xFF122030);
  static const interval = Color(0xFFEF5350);
  static const intDim   = Color(0xFF2D1414);
  static const hike     = Color(0xFFB39DDB);
  static const hikeDim  = Color(0xFF1E1830);
  static const cross    = Color(0xFFFFCA28);
  static const crossDim = Color(0xFF2C2410);
  static const race     = Color(0xFFFFD54F);
  static const raceDim  = Color(0xFF2C260C);
  static const rest     = Color(0xFF6E6E9E);
  static const restDim  = Color(0xFF18182A);
}

// ── Theme ─────────────────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData get theme {
    const cs = ColorScheme(
      brightness:          Brightness.dark,
      primary:             AppColors.brand,
      onPrimary:           Colors.white,
      primaryContainer:    Color(0xFF4A1A08),
      onPrimaryContainer:  Color(0xFFFFB59E),
      secondary:           AppColors.brandDeep,
      onSecondary:         Colors.white,
      secondaryContainer:  Color(0xFF4A0E0E),
      onSecondaryContainer:Color(0xFFFFB3AF),
      tertiary:            AppColors.longRun,
      onTertiary:          Colors.white,
      tertiaryContainer:   Color(0xFF0E2A3E),
      onTertiaryContainer: Color(0xFFADD4F0),
      error:               AppColors.error,
      onError:             Colors.white,
      errorContainer:      AppColors.errorDim,
      onErrorContainer:    Color(0xFFFFB3AE),
      surface:             AppColors.surface,
      onSurface:           AppColors.onBg,
      surfaceContainerHighest: AppColors.surfaceHigher,
      surfaceContainerHigh:    AppColors.surfaceHigh,
      surfaceContainer:        AppColors.surface,
      surfaceContainerLow:     AppColors.bg,
      surfaceContainerLowest:  AppColors.bg,
      onSurfaceVariant:    AppColors.onSurface,
      outline:             AppColors.outline,
      outlineVariant:      AppColors.outlineHigh,
      shadow:              Colors.black,
      scrim:               Colors.black,
      inverseSurface:      AppColors.onBg,
      onInverseSurface:    AppColors.bg,
      inversePrimary:      Color(0xFF8B2500),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: AppColors.bg,

      // ── Typography ──
      textTheme: const TextTheme(
        displayLarge:  TextStyle(fontSize: 57, fontWeight: FontWeight.w400, color: AppColors.onBg, letterSpacing: -0.25),
        displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w400, color: AppColors.onBg),
        displaySmall:  TextStyle(fontSize: 36, fontWeight: FontWeight.w400, color: AppColors.onBg),
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.onBg, letterSpacing: -0.5),
        headlineMedium:TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.onBg, letterSpacing: -0.3),
        headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.onBg),
        titleLarge:    TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.onBg),
        titleMedium:   TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.onBg, letterSpacing: 0.15),
        titleSmall:    TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onBg, letterSpacing: 0.1),
        bodyLarge:     TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.onBg),
        bodyMedium:    TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.onSurface),
        bodySmall:     TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.muted),
        labelLarge:    TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onBg, letterSpacing: 0.1),
        labelMedium:   TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.onSurface, letterSpacing: 0.5),
        labelSmall:    TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.muted, letterSpacing: 0.5),
      ),

      // ── AppBar ──
      appBarTheme: const AppBarTheme(
        backgroundColor:    AppColors.bg,
        foregroundColor:    AppColors.onBg,
        elevation:          0,
        scrolledUnderElevation: 0,
        centerTitle:        false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor:      Colors.transparent,
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.onBg,
          letterSpacing: -0.3,
        ),
      ),

      // ── Cards ──
      cardTheme: CardThemeData(
        color:     AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.outline),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // ── NavigationBar ──
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:      AppColors.surface,
        indicatorColor:       AppColors.brand.withOpacity(.2),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.brand, size: 24);
          }
          return const IconThemeData(color: AppColors.muted, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brand);
          }
          return const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.muted);
        }),
        surfaceTintColor:   Colors.transparent,
        shadowColor:        Colors.black,
        elevation:          8,
        height:             72,
      ),

      // ── Bottom sheet ──
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor:       AppColors.surfaceHigh,
        modalBackgroundColor:  AppColors.surfaceHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // ── Input ──
      inputDecorationTheme: InputDecorationTheme(
        filled:    true,
        fillColor: AppColors.surfaceHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.brand, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle:  const TextStyle(color: AppColors.muted),
        labelStyle: const TextStyle(color: AppColors.muted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // ── Buttons ──
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          minimumSize:     const Size(double.infinity, 52),
          shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle:       const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3),
          elevation:       0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          minimumSize:     const Size(double.infinity, 52),
          shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle:       const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3),
          elevation:       0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.onBg,
          minimumSize:     const Size(double.infinity, 52),
          shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side:            const BorderSide(color: AppColors.outline),
          textStyle:       const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.brand),
      ),

      // ── FAB ──
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        elevation:       4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
      ),

      // ── Chip ──
      chipTheme: ChipThemeData(
        backgroundColor:    AppColors.surfaceHigh,
        selectedColor:      AppColors.brand.withOpacity(.2),
        side:               const BorderSide(color: AppColors.outline),
        shape:              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        labelStyle:         const TextStyle(fontSize: 13, color: AppColors.onSurface),
        checkmarkColor:     AppColors.brand,
      ),

      // ── Slider ──
      sliderTheme: const SliderThemeData(
        activeTrackColor:   AppColors.brand,
        thumbColor:         AppColors.brand,
        inactiveTrackColor: AppColors.outline,
        overlayColor:       Color(0x1AFF7043),
      ),

      // ── Checkbox ──
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.brand;
          return Colors.transparent;
        }),
        side: const BorderSide(color: AppColors.outlineHigh, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // ── Divider ──
      dividerTheme: const DividerThemeData(color: AppColors.outline, space: 1, thickness: 1),

      // ── Progress ──
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color:           AppColors.brand,
        linearTrackColor: AppColors.outline,
      ),

      // ── SnackBar ──
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceHigher,
        contentTextStyle: const TextStyle(color: AppColors.onBg),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
