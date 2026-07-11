import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palette for the dark, purple→near-black look.
abstract final class AppColors {
  static const Color violet = Color(0xFFB388FF); // primary accent / text
  static const Color violetDeep = Color(0xFF7C3AED); // buttons, bar fill start
  static const Color magenta = Color(0xFFE95FE0); // bar fill end, highlights
  static const Color gap = Color(0xFFFF6B8A); // "not practiced" marker

  static const Color card = Color(0x1AFFFFFF); // translucent surface on gradient
  static const Color cardBorder = Color(0x22FFFFFF);

  /// Background gradient: deep violet at the top → almost black at the bottom.
  static const List<Color> background = [
    Color(0xFF3A1078),
    Color(0xFF1B0B3A),
    Color(0xFF08050F),
  ];

  static const List<Color> barFill = [violetDeep, magenta];
}

/// Builds the app's single dark theme with the Space Grotesk type family.
ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.violetDeep,
    brightness: Brightness.dark,
  ).copyWith(
    primary: AppColors.violet,
    secondary: AppColors.magenta,
    surface: const Color(0xFF160B2E),
  );

  final base = ThemeData(colorScheme: scheme, brightness: Brightness.dark);

  return base.copyWith(
    // Transparent so the gradient (painted once, app-wide) shows through.
    scaffoldBackgroundColor: Colors.transparent,
    canvasColor: Colors.transparent,
    textTheme: GoogleFonts.spaceGroteskTextTheme(base.textTheme),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xCC160B2E),
      indicatorColor: AppColors.violetDeep.withValues(alpha: 0.35),
      elevation: 0,
      labelTextStyle: WidgetStateProperty.all(
        GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.violetDeep,
        foregroundColor: Colors.white,
        textStyle: GoogleFonts.spaceGrotesk(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
    ),
  );
}
