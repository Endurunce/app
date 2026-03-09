import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Brand palette — warme, aardse huisstijl ──────────────────────────────────
class AppColors {
  // Primair — Mos
  static const brand     = Color(0xFF5A7A52); // moss — CTA, primaire kleur
  static const brandDeep = Color(0xFF8AAB7E); // sage — hover, progress

  // Achtergronden (gelaagd)
  static const bg            = Color(0xFFF7F3EE); // warme beige canvas
  static const surface       = Color(0xFFFFFCF8); // kaarten, sheets
  static const surfaceHigh   = Color(0xFFF0EBE3); // invoervelden, chips, rijen
  static const surfaceHigher = Color(0xFFE8E4DD); // modals, tooltips

  // Randen & scheidingen
  static const outline     = Color(0xFFE2D9CE); // border
  static const outlineHigh = Color(0xFFC9BFB3); // borderDark

  // Tekst
  static const onBg      = Color(0xFF2D2720); // ink — primaire tekst
  static const onSurface = Color(0xFF7A6E64); // inkMid — secondaire tekst
  static const muted     = Color(0xFFA89E93); // inkLight — placeholder, labels
  static const disabled  = Color(0xFFC9BFB3); // uitgeschakeld

  // Semantisch
  static const success    = Color(0xFF5A7A52); // moss
  static const successDim = Color(0xFFDEEBD8); // mossDim
  static const warning    = Color(0xFFC49A5A); // sand
  static const warningDim = Color(0xFFF5E8CC); // sandDim
  static const error      = Color(0xFFB85C3A); // terra
  static const errorDim   = Color(0xFFF5DDD5); // terraDim

  // Accenten
  static const terra     = Color(0xFFB85C3A); // waarschuwing, intensiteit
  static const terraDim  = Color(0xFFF5DDD5);
  static const sand      = Color(0xFFC49A5A); // informatief
  static const sandDim   = Color(0xFFF5E8CC);
  static const sky       = Color(0xFF4A7FA0); // lange duurloop
  static const skyDim    = Color(0xFFD6E8F5);
  static const lavender  = Color(0xFF7A6AAA); // trail / wandel
  static const lavDim    = Color(0xFFE8E3F5);
  static const stone     = Color(0xFF9E9488); // rustdag, uitgeschakeld
  static const stoneDim  = Color(0xFFEDE8E2);
  static const gold      = Color(0xFFB8862A); // race day, beloning
  static const goldDim   = Color(0xFFF5E8C0);
  static const strava    = Color(0xFFFC4C02);
  static const stravaDim = Color(0xFFFEE8DF);

  // Sessie-kleuren (licht-geoptimaliseerd)
  static const easy     = Color(0xFF5A7A52); // moss
  static const easyDim  = Color(0xFFDEEBD8); // mossDim
  static const tempo    = Color(0xFFB85C3A); // terra
  static const tempoDim = Color(0xFFF5DDD5); // terraDim
  static const longRun  = Color(0xFF4A7FA0); // sky
  static const longDim  = Color(0xFFD6E8F5); // skyDim
  static const interval = Color(0xFFC0392B); // intens rood
  static const intDim   = Color(0xFFF5DDD5); // terraDim
  static const hike     = Color(0xFF7A6AAA); // lavender
  static const hikeDim  = Color(0xFFE8E3F5); // lavDim
  static const cross    = Color(0xFFC49A5A); // sand
  static const crossDim = Color(0xFFF5E8CC); // sandDim
  static const race     = Color(0xFFB8862A); // gold
  static const raceDim  = Color(0xFFF5E8C0); // goldDim
  static const rest     = Color(0xFF9E9488); // stone
  static const restDim  = Color(0xFFEDE8E2); // stoneDim
}

// ── Theme ─────────────────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData get theme {
    const cs = ColorScheme(
      brightness:               Brightness.light,
      primary:                  AppColors.brand,
      onPrimary:                Colors.white,
      primaryContainer:         AppColors.successDim,   // mossDim
      onPrimaryContainer:       AppColors.brand,
      secondary:                AppColors.terra,
      onSecondary:              Colors.white,
      secondaryContainer:       AppColors.terraDim,
      onSecondaryContainer:     AppColors.terra,
      tertiary:                 AppColors.sky,
      onTertiary:               Colors.white,
      tertiaryContainer:        AppColors.skyDim,
      onTertiaryContainer:      AppColors.sky,
      error:                    AppColors.error,
      onError:                  Colors.white,
      errorContainer:           AppColors.errorDim,
      onErrorContainer:         AppColors.terra,
      surface:                  AppColors.surface,
      onSurface:                AppColors.onBg,
      surfaceContainerHighest:  AppColors.surfaceHigher,
      surfaceContainerHigh:     AppColors.surfaceHigh,
      surfaceContainer:         AppColors.surfaceHigh,
      surfaceContainerLow:      AppColors.bg,
      surfaceContainerLowest:   AppColors.bg,
      onSurfaceVariant:         AppColors.onSurface,
      outline:                  AppColors.outline,
      outlineVariant:           AppColors.outlineHigh,
      shadow:                   Colors.black,
      scrim:                    Colors.black54,
      inverseSurface:           AppColors.onBg,
      onInverseSurface:         AppColors.surface,
      inversePrimary:           AppColors.brandDeep,    // sage
    );

    return ThemeData(
      useMaterial3:            true,
      colorScheme:             cs,
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
        surfaceTintColor:   Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor:          Colors.transparent,
          statusBarBrightness:     Brightness.light,     // iOS: donkere iconen
          statusBarIconBrightness: Brightness.dark,      // Android: donkere iconen
        ),
        titleTextStyle: TextStyle(
          fontSize:    20,
          fontWeight:  FontWeight.w700,
          color:       AppColors.onBg,
          letterSpacing: -0.3,
        ),
      ),

      // ── Cards ──
      cardTheme: CardThemeData(
        color:     AppColors.surface,
        elevation: 0,
        shadowColor: Color(0x122D2720),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.outline),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // ── NavigationBar ──
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:    AppColors.surface,
        indicatorColor:     Color(0x1A5A7A52), // moss 10%
        surfaceTintColor:   Colors.transparent,
        shadowColor:        Colors.black,
        elevation:          4,
        height:             72,
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
      ),

      // ── Bottom sheet ──
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor:      AppColors.surface,
        modalBackgroundColor: AppColors.surface,
        surfaceTintColor:     Colors.transparent,
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
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.brand, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        hintStyle:      const TextStyle(color: AppColors.muted),
        labelStyle:     const TextStyle(color: AppColors.muted),
        floatingLabelStyle: const TextStyle(color: AppColors.brand),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),

      // ── Buttons ──
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          minimumSize:     const Size(double.infinity, 52),
          shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
          textStyle:       const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3),
          elevation:       0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          minimumSize:     const Size(double.infinity, 52),
          shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
          textStyle:       const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3),
          elevation:       0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.onBg,
          minimumSize:     const Size(double.infinity, 52),
          shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
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
        elevation:       2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
      ),

      // ── Chip ──
      chipTheme: ChipThemeData(
        backgroundColor:  AppColors.surfaceHigh,
        selectedColor:    Color(0x1A5A7A52), // moss 10%
        side:             const BorderSide(color: AppColors.outline),
        shape:            RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
        labelStyle:       const TextStyle(fontSize: 13, color: AppColors.onSurface),
        checkmarkColor:   AppColors.brand,
        padding:          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      // ── Slider ──
      sliderTheme: const SliderThemeData(
        activeTrackColor:   AppColors.brand,
        thumbColor:         AppColors.brand,
        inactiveTrackColor: AppColors.outline,
        overlayColor:       Color(0x1A5A7A52),
      ),

      // ── Checkbox ──
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.brand;
          return Colors.transparent;
        }),
        side:  const BorderSide(color: AppColors.outlineHigh, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // ── Switch ──
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return AppColors.muted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.brand;
          return AppColors.surfaceHigh;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.transparent;
          return AppColors.outline;
        }),
      ),

      // ── Divider ──
      dividerTheme: const DividerThemeData(color: AppColors.outline, space: 1, thickness: 1),

      // ── Progress ──
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color:            AppColors.brand,
        linearTrackColor: AppColors.outline,
      ),

      // ── SnackBar ──
      snackBarTheme: SnackBarThemeData(
        backgroundColor:  AppColors.onBg,
        contentTextStyle: const TextStyle(color: AppColors.surface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        elevation: 2,
      ),

      // ── ListTile ──
      listTileTheme: const ListTileThemeData(
        tileColor:    Colors.transparent,
        iconColor:    AppColors.onSurface,
        textColor:    AppColors.onBg,
        subtitleTextStyle: TextStyle(color: AppColors.muted, fontSize: 13),
      ),

      // ── Dialog ──
      dialogTheme: DialogThemeData(
        backgroundColor:  AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 4,
        shadowColor: const Color(0x222D2720),
      ),
    );
  }
}
