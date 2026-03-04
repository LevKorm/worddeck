import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/theme_constants.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark  => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary:         ThemeConstants.primaryOrange,
      onPrimary:       ThemeConstants.textPrimaryLight,
      primaryContainer:isLight
          ? ThemeConstants.primaryOrangeLight
          : ThemeConstants.primaryOrangeDark,
      onPrimaryContainer: isLight
          ? ThemeConstants.textPrimaryLight
          : ThemeConstants.textPrimaryDark,
      secondary:       isLight
          ? ThemeConstants.primaryOrangeDark
          : ThemeConstants.primaryOrangeLight,
      onSecondary:     ThemeConstants.textPrimaryLight,
      secondaryContainer: isLight
          ? const Color(0xFFFFEDD0)
          : const Color(0xFF3D2800),
      onSecondaryContainer: isLight
          ? ThemeConstants.textPrimaryLight
          : ThemeConstants.textPrimaryDark,
      surface:         isLight ? ThemeConstants.surfaceLight : ThemeConstants.surfaceDark,
      onSurface:       isLight ? ThemeConstants.textPrimaryLight : ThemeConstants.textPrimaryDark,
      surfaceContainerHighest: isLight ? ThemeConstants.cardLight : ThemeConstants.cardDark,
      onSurfaceVariant:isLight ? ThemeConstants.textSecondaryLight : ThemeConstants.textSecondaryDark,
      outline:         isLight ? ThemeConstants.borderLight : ThemeConstants.borderDark,
      error:           ThemeConstants.ratingAgain,
      onError:         Colors.white,
      errorContainer:  const Color(0xFFFFDAD6),
      onErrorContainer:const Color(0xFF410002),
      scrim:           Colors.black,
      shadow:          Colors.black,
    );

    final textTheme = GoogleFonts.outfitTextTheme(
      isLight ? ThemeData.light().textTheme : ThemeData.dark().textTheme,
    ).copyWith(
      displayLarge:  GoogleFonts.outfit(fontSize: 34, fontWeight: FontWeight.w700),
      displayMedium: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w700),
      headlineLarge: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w600),
      headlineMedium:GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600),
      titleLarge:    GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600),
      titleMedium:   GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w500),
      bodyLarge:     GoogleFonts.outfit(fontSize: 16),
      bodyMedium:    GoogleFonts.outfit(fontSize: 14),
      bodySmall:     GoogleFonts.outfit(fontSize: 12),
      labelLarge:    GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor:
          isLight ? ThemeConstants.bgLight : ThemeConstants.bgDark,
      appBarTheme: AppBarTheme(
        backgroundColor:
            isLight ? ThemeConstants.bgLight : ThemeConstants.bgDark,
        foregroundColor:
            isLight ? ThemeConstants.textPrimaryLight : ThemeConstants.textPrimaryDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: isLight ? ThemeConstants.textPrimaryLight : ThemeConstants.textPrimaryDark,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: ThemeConstants.elevationCard,
        color: isLight ? ThemeConstants.cardLight : ThemeConstants.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeConstants.radiusLG),
          side: BorderSide(
            color: isLight ? ThemeConstants.borderLight : ThemeConstants.borderDark,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight
            ? ThemeConstants.surfaceLight
            : ThemeConstants.surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ThemeConstants.radiusMD),
          borderSide: BorderSide(
            color: isLight ? ThemeConstants.borderLight : ThemeConstants.borderDark,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ThemeConstants.radiusMD),
          borderSide: BorderSide(
            color: isLight ? ThemeConstants.borderLight : ThemeConstants.borderDark,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ThemeConstants.radiusMD),
          borderSide: const BorderSide(
            color: ThemeConstants.primaryOrange,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: ThemeConstants.spaceMD,
          vertical: ThemeConstants.spaceMD,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ThemeConstants.primaryOrange,
          foregroundColor: ThemeConstants.textPrimaryLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ThemeConstants.radiusMD),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: ThemeConstants.spaceLG,
            vertical: ThemeConstants.spaceMD,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: ThemeConstants.primaryOrange),
          foregroundColor: ThemeConstants.primaryOrange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ThemeConstants.radiusMD),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:
            isLight ? ThemeConstants.surfaceLight : ThemeConstants.surfaceDark,
        indicatorColor: ThemeConstants.primaryOrange.withAlpha(30),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected
                ? ThemeConstants.primaryOrange
                : (isLight
                    ? ThemeConstants.textSecondaryLight
                    : ThemeConstants.textSecondaryDark),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected
                ? ThemeConstants.primaryOrange
                : (isLight
                    ? ThemeConstants.textSecondaryLight
                    : ThemeConstants.textSecondaryDark),
          );
        }),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor:
            isLight ? ThemeConstants.surfaceLight : ThemeConstants.surfaceDark,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(ThemeConstants.radiusXL),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeConstants.radiusFull),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isLight ? ThemeConstants.borderLight : ThemeConstants.borderDark,
        thickness: 1,
      ),
    );
  }
}
