import 'package:flutter/material.dart';

/// "Warm" — the cream/terracotta theme, an alternative to [AppTheme]'s indigo.
///
/// Structured identically to AppTheme (same widget themes, same font) so the
/// two are true siblings a user can switch between — only the colour tokens
/// differ. The dark variant has no source mockup; it is my own warm-toned
/// complement (dark chocolate surface, brightened terracotta/olive) so system
/// dark mode still looks intentional rather than falling back to the light
/// palette. Revisit it if a real dark mockup shows up.
class WarmTheme {
  WarmTheme._();

  static const _fontFamily = 'Inter';

  // ── Brand ──────────────────────────────────────────────────────────────────
  static const _terracotta = Color(0xFFB5602E);
  static const _olive = Color(0xFF4F5D3A);

  // ── Light tokens ─────────────────────────────────────────────────────────
  static const _lightBg = Color(0xFFF3E8D8); // cream page background
  static const _lightSurface = Color(0xFFFBF6EC); // list rows / cards
  static const _lightContainer = Color(0xFFEFE3D0); // chips, fills, icon boxes
  static const _lightOnSurface = Color(0xFF2A2118); // warm near-black
  static const _lightOnVariant = Color(0xFF7A6E5C); // warm taupe
  static const _lightOutline = Color(0xFFB8A98D);

  // ── Dark tokens (designed complement — see class doc) ──────────────────────
  static const _darkBg = Color(0xFF1E1712);
  static const _darkSurface = Color(0xFF2A2119);
  static const _darkContainer = Color(0xFF33291F);
  static const _darkOnSurface = Color(0xFFF0E4D0);
  static const _darkOnVariant = Color(0xFFC2B39B);
  static const _darkOutline = Color(0xFF6E6152);

  // ─────────────────────────────────────────────────────────────────────────

  static ThemeData get light => _build(
        brightness: Brightness.light,
        scheme: const ColorScheme(
          brightness: Brightness.light,
          primary: _terracotta,
          onPrimary: Colors.white,
          primaryContainer: Color(0xFFF3D9C4),
          onPrimaryContainer: Color(0xFF5C2A0E),
          secondary: _olive,
          onSecondary: Colors.white,
          // The hero "next bill" card's mint-green background.
          secondaryContainer: Color(0xFFDCE8D0),
          onSecondaryContainer: Color(0xFF23301A),
          tertiary: Color(0xFFB08A3E), // muted gold, used sparingly
          onTertiary: Colors.white,
          tertiaryContainer: Color(0xFFF0E0BC),
          onTertiaryContainer: Color(0xFF463209),
          error: Color(0xFFA6402C),
          onError: Colors.white,
          errorContainer: Color(0xFFF5D8D0),
          onErrorContainer: Color(0xFF5C1D10),
          surface: _lightSurface,
          onSurface: _lightOnSurface,
          onSurfaceVariant: _lightOnVariant,
          surfaceContainerLowest: _lightBg,
          surfaceContainerLow: Color(0xFFF6EEDF),
          surfaceContainer: _lightContainer,
          surfaceContainerHigh: _lightContainer,
          surfaceContainerHighest: Color(0xFFE8DAC3),
          outline: _lightOutline,
          outlineVariant: Color(0xFFE3D6C0),
          shadow: Color(0xFF2A2118),
          scrim: Colors.black,
          inverseSurface: Color(0xFF3A2E22),
          onInverseSurface: Color(0xFFF3E8D8),
          inversePrimary: Color(0xFFE0A87E),
        ),
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        scheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: Color(0xFFE0935B),
          onPrimary: Color(0xFF3D1D08),
          primaryContainer: Color(0xFF5C3319),
          onPrimaryContainer: Color(0xFFF3D9C4),
          secondary: Color(0xFF9DB37E),
          onSecondary: Color(0xFF23301A),
          secondaryContainer: Color(0xFF3B4A2C),
          onSecondaryContainer: Color(0xFFDCE8D0),
          tertiary: Color(0xFFD1B36E),
          onTertiary: Color(0xFF3B2B06),
          tertiaryContainer: Color(0xFF554016),
          onTertiaryContainer: Color(0xFFF0E0BC),
          error: Color(0xFFE0846B),
          onError: Color(0xFF3D160E),
          errorContainer: Color(0xFF5C2418),
          onErrorContainer: Color(0xFFF5D8D0),
          surface: _darkSurface,
          onSurface: _darkOnSurface,
          onSurfaceVariant: _darkOnVariant,
          surfaceContainerLowest: _darkBg,
          surfaceContainerLow: Color(0xFF241C15),
          surfaceContainer: _darkContainer,
          surfaceContainerHigh: _darkContainer,
          surfaceContainerHighest: Color(0xFF3F3327),
          outline: _darkOutline,
          outlineVariant: Color(0xFF3F3327),
          shadow: Colors.black,
          scrim: Colors.black,
          inverseSurface: Color(0xFFF0E4D0),
          onInverseSurface: Color(0xFF2A2119),
          inversePrimary: _terracotta,
        ),
      );

  // ─────────────────────────────────────────────────────────────────────────
  // Everything below mirrors AppTheme's widget theming 1:1 so the two themes
  // behave identically — only the ColorScheme fed in differs.

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
          fontWeight: FontWeight.w800,
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
          fontWeight: FontWeight.w800,
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
          ? const Color(0xFF2A2118).withValues(alpha: 0.10)
          : Colors.black.withValues(alpha: 0.4),
    );
  }

  // ── Type scale ─────────────────────────────────────────────────────────────
  // Big display headlines ("My cards", "Card Vault") use Playfair Display, a
  // bundled serif — matches the mockups' editorial look, which heavy-weight
  // Inter alone couldn't. Everything titleLarge and smaller (card titles, list
  // rows, buttons, labels) stays on Inter: serif at UI sizes reads as
  // old-fashioned rather than elegant, and Inter is what the rest of the app's
  // widget theming (buttons, inputs, chips) is already built around.
  static const _displayFont = 'PlayfairDisplay';

  static TextTheme _textTheme(Color onSurface, Color onVariant) {
    TextStyle h(double size, FontWeight w, double spacing) => TextStyle(
          fontSize: size,
          fontWeight: w,
          letterSpacing: spacing,
          height: 1.2,
          color: onSurface,
        );
    TextStyle display(double size, FontWeight w, double spacing) => TextStyle(
          fontFamily: _displayFont,
          fontSize: size,
          fontWeight: w,
          letterSpacing: spacing,
          height: 1.15,
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
      displaySmall: display(34, FontWeight.w800, -0.2),
      headlineMedium: display(26, FontWeight.w800, -0.2),
      headlineSmall: display(22, FontWeight.w700, -0.1),
      titleLarge: h(19, FontWeight.w800, -0.2),
      titleMedium: h(16, FontWeight.w700, -0.1),
      titleSmall: h(14, FontWeight.w700, 0),
      bodyLarge: body(15.5, FontWeight.w500),
      bodyMedium: body(14, FontWeight.w400),
      bodySmall: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w400,
          height: 1.4,
          color: onVariant),
      labelLarge: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0),
      labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: onVariant),
    );
  }
}
