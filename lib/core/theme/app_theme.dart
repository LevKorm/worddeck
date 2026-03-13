import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

abstract final class AppTheme {
  /// The one and only theme. Dark-only app.
  static ThemeData get darkTheme {
    final dmSans = GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: _colorScheme,
      textTheme: _buildTextTheme(dmSans),
      appBarTheme: _appBarTheme,
      cardTheme: _cardTheme,
      inputDecorationTheme: _inputDecorationTheme,
      filledButtonTheme: _filledButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme,
      navigationBarTheme: _navigationBarTheme,
      bottomSheetTheme: _bottomSheetTheme,
      chipTheme: _chipTheme,
      dividerTheme: _dividerTheme,
      dialogTheme: _dialogTheme,
      snackBarTheme: _snackBarTheme,
      splashColor: AppColors.accentGlow,
      highlightColor: AppColors.accentGlow,
    );
  }

  // ── ColorScheme ──────────────────────────────────────────────────────────

  static const ColorScheme _colorScheme = ColorScheme(
    brightness: Brightness.dark,
    // Primary = accent amber
    primary: AppColors.accent,
    onPrimary: Color(0xFF000000),
    primaryContainer: AppColors.accentDim,
    onPrimaryContainer: AppColors.accent,
    // Secondary = indigo (functional: saved, vocabulary)
    secondary: AppColors.indigo,
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: AppColors.indigoDim,
    onSecondaryContainer: AppColors.indigo,
    // Tertiary = green (functional: positive stats)
    tertiary: AppColors.green,
    onTertiary: Color(0xFF000000),
    tertiaryContainer: AppColors.greenDim,
    onTertiaryContainer: AppColors.green,
    // Error = red
    error: AppColors.red,
    onError: Color(0xFF000000),
    errorContainer: AppColors.redDim,
    onErrorContainer: AppColors.red,
    // Surfaces
    surface: AppColors.surface,
    onSurface: AppColors.text,
    onSurfaceVariant: AppColors.textMuted,
    surfaceContainerHighest: AppColors.surface2,
    // Outlines
    outline: AppColors.surface3,
    outlineVariant: AppColors.textDim,
    // Misc
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: AppColors.text,
    onInverseSurface: AppColors.bg,
    inversePrimary: Color(0xFFB07820),
  );

  // ── TextTheme ────────────────────────────────────────────────────────────

  static TextTheme _buildTextTheme(TextTheme base) {
    return base.copyWith(
      headlineLarge: base.headlineLarge?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
        height: 1.2,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
        height: 1.3,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.text,
        height: 1.5,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.text,
        height: 1.5,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
        letterSpacing: 0.8,
      ),
    );
  }

  // ── Emoji text style ──────────────────────────────────────────────────
  // DM Sans has no emoji glyphs. Setting fontFamily to empty string
  // breaks the theme inheritance and lets CanvasKit's built-in font
  // fallback resolve emoji glyphs automatically (it downloads small
  // glyph ranges on demand, not the full 24 MB Noto Color Emoji).
  static const TextStyle emojiStyle = TextStyle(
    fontFamily: 'sans-serif',
    fontFamilyFallback: ['Apple Color Emoji', 'Segoe UI Emoji', 'Noto Color Emoji'],
  );

  // ── Custom text styles not in Material's TextTheme ───────────────────────
  // Cached as static finals — avoids re-creating TextStyle + font lookup
  // on every access (GoogleFonts.* getters do work each call).

  /// IPA transcriptions — JetBrains Mono (bundled locally).
  static const TextStyle transcriptionStyle = TextStyle(
        fontFamily: 'JetBrains Mono',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
      );

  /// Stat pill numbers — JetBrains Mono, smaller (bundled locally).
  static const TextStyle statNumberStyle = TextStyle(
        fontFamily: 'JetBrains Mono',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      );

  /// Translation text inside amber gradient box (dark on gold).
  static final TextStyle translationBoxStyle = GoogleFonts.dmSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF000000),
      );

  /// Feed slide hero word (white on gradient).
  static final TextStyle slideWordHero = GoogleFonts.dmSans(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      );

  /// Feed slide translation (white muted on gradient).
  static final TextStyle slideTranslation = GoogleFonts.dmSans(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: Colors.white60,
      );

  /// Feed slide type label (tiny uppercase on gradient).
  static final TextStyle slideTypeLabel = GoogleFonts.dmSans(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
        color: Colors.white38,
      );

  // ── Component Themes ─────────────────────────────────────────────────────

  static const AppBarTheme _appBarTheme = AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
      statusBarColor: Colors.transparent,
    ),
    iconTheme: IconThemeData(color: AppColors.textMuted, size: 22),
    titleTextStyle: TextStyle(
      fontFamily: 'DM Sans',
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.text,
    ),
  );

  static const CardThemeData _cardTheme = CardThemeData(
    color: AppColors.surface,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
  );

  static final InputDecorationTheme _inputDecorationTheme =
      InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surface,
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
    ),
    hintStyle: const TextStyle(
      fontFamily: 'DM Sans',
      fontSize: 16,
      fontWeight: FontWeight.w300,
      color: AppColors.textDim,
    ),
    labelStyle: const TextStyle(color: AppColors.textMuted),
    errorStyle: const TextStyle(color: AppColors.red),
    prefixIconColor: AppColors.textMuted,
    suffixIconColor: AppColors.textMuted,
  );

  static final FilledButtonThemeData _filledButtonTheme =
      FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.accent,
      foregroundColor: const Color(0xFF000000),
      disabledBackgroundColor: AppColors.surface2,
      disabledForegroundColor: AppColors.textDim,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      textStyle: const TextStyle(
        fontFamily: 'DM Sans',
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  static final OutlinedButtonThemeData _outlinedButtonTheme =
      OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.accent,
      side: const BorderSide(color: AppColors.surface3),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      textStyle: const TextStyle(
        fontFamily: 'DM Sans',
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  static const NavigationBarThemeData _navigationBarTheme =
      NavigationBarThemeData(
    backgroundColor: AppColors.bg,
    indicatorColor: AppColors.accentDim,
    height: 68,
    elevation: 0,
    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    iconTheme: WidgetStatePropertyAll(
      IconThemeData(size: 22, color: AppColors.textMuted),
    ),
    labelTextStyle: WidgetStatePropertyAll(
      TextStyle(
        fontFamily: 'DM Sans',
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
      ),
    ),
  );

  static const BottomSheetThemeData _bottomSheetTheme = BottomSheetThemeData(
    backgroundColor: AppColors.surface,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    constraints: BoxConstraints(maxWidth: 600),
  );

  static const ChipThemeData _chipTheme = ChipThemeData(
    backgroundColor: AppColors.surface2,
    selectedColor: AppColors.accentDim,
    disabledColor: AppColors.surface2,
    labelStyle: TextStyle(
      fontFamily: 'DM Sans',
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: AppColors.text,
    ),
    secondaryLabelStyle: TextStyle(
      fontFamily: 'DM Sans',
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: AppColors.accent,
    ),
    side: BorderSide.none,
    shape: StadiumBorder(),
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  );

  static const DividerThemeData _dividerTheme = DividerThemeData(
    color: AppColors.surface3,
    thickness: 1,
    space: 0,
  );

  static const DialogThemeData _dialogTheme = DialogThemeData(
    backgroundColor: AppColors.surface,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
    titleTextStyle: TextStyle(
      fontFamily: 'DM Sans',
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.text,
    ),
    contentTextStyle: TextStyle(
      fontFamily: 'DM Sans',
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.textMuted,
    ),
  );

  static const SnackBarThemeData _snackBarTheme = SnackBarThemeData(
    backgroundColor: AppColors.surface2,
    contentTextStyle: TextStyle(
      fontFamily: 'DM Sans',
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.text,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
    ),
    behavior: SnackBarBehavior.floating,
  );
}
