import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Single source of truth for the app's visual style.
///
/// Keeping theme configuration here (instead of scattering colors /
/// text styles across screens) means the whole app's look can be
/// re-skinned by editing one file.
class AppTheme {
  // Eco-green seed color drives the full Material 3 color scheme.
  static const Color seedColor = Color(0xFF2E7D32);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );

    // Global Nunito typography
    final nunitoTextTheme = GoogleFonts.nunitoTextTheme().copyWith(
      displayLarge: GoogleFonts.nunito(
        fontSize: 40,
        fontWeight: FontWeight.w800,
      ),

      headlineLarge: GoogleFonts.nunito(
        fontSize: 30,
        fontWeight: FontWeight.w800,
      ),

      headlineMedium: GoogleFonts.nunito(
        fontSize: 26,
        fontWeight: FontWeight.w700,
      ),

      titleLarge: GoogleFonts.nunito(
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),

      titleMedium: GoogleFonts.nunito(
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),

      bodyLarge: GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),

      bodyMedium: GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),

      bodySmall: GoogleFonts.nunito(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),

      labelLarge: GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),

      labelMedium: GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,

      // Apply Nunito globally
      textTheme: nunitoTextTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,

        titleTextStyle: GoogleFonts.nunito(
          color: scheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),

          textStyle: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),

          textStyle: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: scheme.outlineVariant,
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor:
            scheme.surfaceContainerHighest,

        labelStyle: GoogleFonts.nunito(
          color: scheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),

        side: BorderSide.none,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      visualDensity: VisualDensity.standard,
    );
  }
}