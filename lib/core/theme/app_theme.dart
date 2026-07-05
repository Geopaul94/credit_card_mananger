import 'package:flutter/material.dart';

/// Centralised "Refined Fintech" design system.
///
/// One restrained indigo accent, neutral cool-gray surfaces, hairline borders
/// over heavy shadows, and the Inter type family. Both light and dark are
/// first-class. Screens read [ColorScheme] roles, so changing tokens here
/// re-skins the whole app.
class AppTheme {
  AppTheme._();

  static const _fontFamily = 'Inter';

  // ── Brand ──────────────────────────────────────────────────────────────────
  static const _indigo = Color(0xFF4F46E5); // primary accent
  static const _indigoSoft = Color(0xFF6366F1); // secondary / gradient pair

  // ── Light tokens ─────────────────────────────────────────────────────────
  static const _lightBg = Color(0xFFF6F7F9); // app background
  static const _lightSurface = Color(0xFFFFFFFF); // cards
  static const _lightContainer = Color(0xFFF1F3F6); // chips, fills, icon boxes
  static const _lightOnSurface = Color(0xFF0F172A); // slate-900
  static const _lightOnVariant = Color(0xFF64748B); // slate-500
  static const _lightOutline = Color(0xFF94A3B8); // slate-400 (used at low α)

  // ── Dark tokens ──────────────────────────────────────────────────────────
  static const _darkBg = Color(0xFF0B1220);
  static const _darkSurface = Color(0xFF111A2E);
  static const _darkContainer = Color(0xFF1B2438);
  static const _darkOnSurface = Color(0xFFF1F5F9);
  static const _darkOnVariant = Color(0xFF94A3B8);
  static const _darkOutline = Color(0xFF475569);

  // ─────────────────────────────────────────────────────────────────────────

  static ThemeData get light => _build(
        brightness: Brightness.light,
        scheme: const ColorScheme(
          brightness: Brightness.light,
          primary: _indigo,
          onPrimary: Colors.white,
          primaryContainer: Color(0xFFE0E7FF),
          onPrimaryContainer: Color(0xFF312E81),
          secondary: _indigoSoft,
          onSecondary: Colors.white,
          secondaryContainer: Color(0xFFE0E7FF),
          onSecondaryContainer: Color(0xFF312E81),
          tertiary: Color(0xFF0D9488),
          onTertiary: Colors.white,
          tertiaryContainer: Color(0xFFDCFCE7),
          onTertiaryContainer: Color(0xFF166534),
          error: Color(0xFFDC2626),
          onError: Colors.white,
          errorContainer: Color(0xFFFEE2E2),
          onErrorContainer: Color(0xFF991B1B),
          surface: _lightSurface,
          onSurface: _lightOnSurface,
          onSurfaceVariant: _lightOnVariant,
          surfaceContainerLowest: _lightBg,
          surfaceContainerLow: Color(0xFFF4F6F9),
          surfaceContainer: _lightContainer,
          surfaceContainerHigh: _lightContainer,
          surfaceContainerHighest: Color(0xFFE9EDF2),
          outline: _lightOutline,
          outlineVariant: Color(0xFFE2E8F0),
          shadow: Color(0xFF0F172A),
          scrim: Colors.black,
          inverseSurface: Color(0xFF1E293B),
          onInverseSurface: Colors.white,
          inversePrimary: Color(0xFFC7D2FE),
        ),
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        scheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: Color(0xFF818CF8),
          onPrimary: Color(0xFF1E1B4B),
          primaryContainer: Color(0xFF3730A3),
          onPrimaryContainer: Color(0xFFE0E7FF),
          secondary: Color(0xFF8B93F8),
          onSecondary: Color(0xFF1E1B4B),
          secondaryContainer: Color(0xFF3730A3),
          onSecondaryContainer: Color(0xFFE0E7FF),
          tertiary: Color(0xFF2DD4BF),
          onTertiary: Color(0xFF042F2E),
          tertiaryContainer: Color(0xFF14532D),
          onTertiaryContainer: Color(0xFFBBF7D0),
          error: Color(0xFFF87171),
          onError: Color(0xFF450A0A),
          errorContainer: Color(0xFF7F1D1D),
          onErrorContainer: Color(0xFFFECACA),
          surface: _darkSurface,
          onSurface: _darkOnSurface,
          onSurfaceVariant: _darkOnVariant,
          surfaceContainerLowest: _darkBg,
          surfaceContainerLow: Color(0xFF131C30),
          surfaceContainer: _darkContainer,
          surfaceContainerHigh: _darkContainer,
          surfaceContainerHighest: Color(0xFF243049),
          outline: _darkOutline,
          outlineVariant: Color(0xFF334155),
          shadow: Colors.black,
          scrim: Colors.black,
          inverseSurface: Color(0xFFE2E8F0),
          onInverseSurface: Color(0xFF0F172A),
          inversePrimary: _indigo,
        ),
      );

  // ─────────────────────────────────────────────────────────────────────────

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme scheme,
  }) {
    final isLight = brightness == Brightness.light;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: _fontFamily,
      scaffoldBackgroundColor: scheme.surfaceContainerLowest,
      splashFactory: InkSparkle.splashFactory,
      textTheme: _textTheme(scheme.onSurface, scheme.onSurfaceVariant),

      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surfaceContainerLowest,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: scheme.shadow.withValues(alpha: 0.06),
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: scheme.onSurface,
        ),
      ),

      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.14)),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.primary.withValues(alpha: 0.4),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.4)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        hintStyle: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.18)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.error, width: 1.2),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.16)),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        labelStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),

      dividerTheme: DividerThemeData(
        color: scheme.outline.withValues(alpha: 0.12),
        thickness: 1,
        space: 1,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
        contentTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 14,
          height: 1.5,
          color: scheme.onSurfaceVariant,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          color: scheme.onInverseSurface,
        ),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        insetPadding: const EdgeInsets.all(16),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      splashColor: scheme.primary.withValues(alpha: 0.06),
      highlightColor: scheme.primary.withValues(alpha: 0.04),
      shadowColor: isLight
          ? const Color(0xFF1E293B).withValues(alpha: 0.10)
          : Colors.black.withValues(alpha: 0.4),
    );
  }

  // ── Type scale (Inter) ─────────────────────────────────────────────────────
  static TextTheme _textTheme(Color onSurface, Color onVariant) {
    TextStyle h(double size, FontWeight w, double spacing) => TextStyle(
          fontSize: size,
          fontWeight: w,
          letterSpacing: spacing,
          height: 1.2,
          color: onSurface,
        );
    TextStyle body(double size, FontWeight w) => TextStyle(
          fontSize: size,
          fontWeight: w,
          letterSpacing: 0,
          height: 1.45,
          color: onSurface,
        );

    return TextTheme(
      displaySmall: h(34, FontWeight.w800, -0.6),
      headlineMedium: h(26, FontWeight.w700, -0.4),
      headlineSmall: h(22, FontWeight.w700, -0.3),
      titleLarge: h(19, FontWeight.w700, -0.2),
      titleMedium: h(16, FontWeight.w600, -0.1),
      titleSmall: h(14, FontWeight.w600, 0),
      bodyLarge: body(15.5, FontWeight.w500),
      bodyMedium: body(14, FontWeight.w400),
      bodySmall: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w400,
          height: 1.4,
          color: onVariant),
      labelLarge: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0),
      labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          color: onVariant),
    );
  }
}
