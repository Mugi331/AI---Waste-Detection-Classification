import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralised WE Snap colour palette.
///
/// Every screen/widget should reference these constants (or the
/// [ThemeData.colorScheme] roles derived from them below) rather than
/// hardcoding hex values — see the project handover doc, §4.
///
/// Two colour concepts stay deliberately separate elsewhere in the
/// app: these are decorative/UI accent colours, distinct from the
/// factually-meaningful recycling-bin colours in
/// `data/guidance_repository.dart` (which represent real bin colours
/// and must not be restyled to match this palette).
class AppColors {
  AppColors._();

  static const cream = Color(0xFFFFF8DF); // app background
  static const surfaceCard = Color(0xFFFFFDF5); // card / light surface
  static const pastelYellow = Color(0xFFFFF0A8); // primary CTA
  static const sage = Color(0xFFA9C98F); // recycling-green accent
  static const brownPrimary = Color(0xFF3B2E28); // main text
  static const brownSecondary = Color(0xFF766052); // muted/secondary text
  static const peachAccent = Color(0xFFFFD5B8);
  static const blueAccent = Color(0xFFCFE5F4);
  static const borderLight = Color(0xFFEADFCB); // hairline borders
  static const surfaceMuted = Color(0xFFF7EFD9); // preview/empty-state bg

  // Material-chip accent colours (HomeScreen only — decorative).
  static const chipPlastic = peachAccent;
  static const chipMetal = blueAccent;
  static const chipPaper = pastelYellow;
  static const chipGlass = sage;
}

/// Single source of truth for the app's visual style.
///
/// Keeping theme configuration here (instead of scattering colors /
/// text styles across screens) means the whole app's look can be
/// re-skinned by editing one file.
class AppTheme {
  static ThemeData light() {
    // Seed from the sage accent so Material3's algorithmically-derived
    // roles we DON'T explicitly override (tertiary, inverseSurface,
    // etc.) stay in the same warm/green family rather than defaulting
    // to a generic purple.
    final baseScheme = ColorScheme.fromSeed(
      seedColor: AppColors.sage,
      brightness: Brightness.light,
    );

    final scheme = baseScheme.copyWith(
      primary: AppColors.pastelYellow,
      onPrimary: AppColors.brownPrimary,
      primaryContainer: const Color(0xFFFFF7D6),
      onPrimaryContainer: AppColors.brownPrimary,
      secondary: AppColors.sage,
      onSecondary: AppColors.brownPrimary,
      secondaryContainer: const Color(0xFFE7F1DE),
      onSecondaryContainer: const Color(0xFF3F5A2C),
      surface: AppColors.surfaceCard,
      onSurface: AppColors.brownPrimary,
      onSurfaceVariant: AppColors.brownSecondary,
      surfaceContainerHighest: AppColors.surfaceMuted,
      outline: AppColors.brownSecondary,
      outlineVariant: AppColors.borderLight,
      error: const Color(0xFFC97B63),
      onError: Colors.white,
      errorContainer: const Color(0xFFFBE3DC),
      onErrorContainer: const Color(0xFF8C4A36),
    );

    // Global Nunito typography. Colours are intentionally left unset
    // here so each style inherits colorScheme.onSurface (brown) via
    // Flutter's Typography resolution, rather than hardcoding colour
    // in every single text style.
    final nunitoTextTheme = GoogleFonts.nunitoTextTheme().copyWith(
      displayLarge: GoogleFonts.nunito(fontSize: 40, fontWeight: FontWeight.w800),
      headlineLarge: GoogleFonts.nunito(fontSize: 35, fontWeight: FontWeight.w800),
      headlineMedium: GoogleFonts.nunito(fontSize: 26, fontWeight: FontWeight.w700),
      titleLarge: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w700),
      titleMedium: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w700),
      bodyLarge: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w500),
      bodyMedium: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w400),
      bodySmall: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w400),
      labelLarge: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700),
      labelMedium: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600),
      labelSmall: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.cream,
      textTheme: nunitoTextTheme,
      iconTheme: const IconThemeData(color: AppColors.brownSecondary),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.brownPrimary,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.nunito(
          color: AppColors.brownPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          textStyle: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700),
          elevation: 1,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          foregroundColor: AppColors.brownPrimary,
          side: const BorderSide(color: AppColors.borderLight, width: 1.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          textStyle: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderLight),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceMuted,
        labelStyle: GoogleFonts.nunito(
          color: AppColors.brownPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      visualDensity: VisualDensity.standard,
    );
  }
}
