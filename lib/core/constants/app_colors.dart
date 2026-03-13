import 'package:flutter/material.dart';

/// WordDeck brand color palette.
///
/// Design identity: "warm dark" — earthy grays, amber accent,
/// indigo + green as functional colors only.
abstract final class AppColors {
  // ── Backgrounds (layered, darkest → lightest) ──
  static const Color bg = Color(0xFF0D0D0D);        // scaffold / ground layer
  static const Color cardBlack = Color(0xFF131313); // translate card
  static const Color surface = Color(0xFF1E1E1E);
  static const Color surface2 = Color(0xFF2A2A2A);
  static const Color surface3 = Color(0xFF333333);

  // ── Accent (amber/gold — the brand color) ──
  static const Color accent = Color(0xFFE8A838);
  static const Color accentDim = Color(0x26E8A838); // 15% opacity
  static const Color accentGlow = Color(0x14E8A838); // 8% opacity

  // ── Functional ──
  static const Color indigo = Color(0xFF6366F1);
  static const Color indigoDim = Color(0x266366F1); // 15% opacity
  static const Color green = Color(0xFF4ADE80);
  static const Color greenDim = Color(0x1F4ADE80); // 12% opacity
  static const Color red = Color(0xFFF87171);
  static const Color redDim = Color(0x26F87171); // 15% opacity

  // ── Text ──
  static const Color text = Color(0xFFF0ECE4);
  static const Color textMuted = Color(0xFF9E9A92);
  static const Color textDim = Color(0xFF6B6760);

  // ── Review rating buttons ──
  static const Color ratingAgain = Color(0xFFF87171);
  static const Color ratingHard = Color(0xFFFBBF24);
  static const Color ratingGood = Color(0xFF4ADE80);
  static const Color ratingEasy = Color(0xFF60A5FA);

  // ── Stat pill presets (background, text) ──
  static const Color statDueBg = surface2;
  static const Color statDueText = textMuted;
  static const Color statReviewedBg = indigoDim;
  static const Color statReviewedText = indigo;
  static const Color statWordsBg = greenDim;
  static const Color statWordsText = green;

  // ── Card status ──
  static const Color statusPending = textMuted;
  static const Color statusLearning = accent;
  static const Color statusMastered = green;

  // ── Translation box gradient ──
  static const LinearGradient translationGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, Color(0xFFD4922A)],
  );

  // ── Feed slide gradients ──
  static const Map<String, LinearGradient> slideGradients = {
    'hero': LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
    ),
    'etymology': LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1A2A1A), Color(0xFF0A3A2A), Color(0xFF0A4A3A)],
    ),
    'sentences': LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2A1A1A), Color(0xFF3A1A0A), Color(0xFF4A2A0A)],
    ),
    'funFact': LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2A1A2A), Color(0xFF3A0A2A), Color(0xFF4A0A3A)],
    ),
    'synonymCloud': LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1A1A2A), Color(0xFF1A2A3A), Color(0xFF0A3A4A)],
    ),
    'miniStory': LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2A2A1A), Color(0xFF3A3A0A), Color(0xFF4A4A1A)],
    ),
    'wordFamily': LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1A2A2A), Color(0xFF0A3A3A), Color(0xFF0A4A4A)],
    ),
    'collocations': LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2A1A2A), Color(0xFF2A0A3A), Color(0xFF3A0A4A)],
    ),
    'grammar': LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1A1A1A), Color(0xFF2A2A2A), Color(0xFF333333)],
    ),
    'commonMistakes': LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2A1A1A), Color(0xFF3A0A0A), Color(0xFF4A1A1A)],
    ),
    'formalityScale': LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1A2A1A), Color(0xFF2A3A1A), Color(0xFF3A4A1A)],
    ),
    'idioms': LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2A2A1A), Color(0xFF2A1A0A), Color(0xFF3A2A1A)],
    ),
  };

  // ── Spacing scale ──
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 12;
  static const double spacingBase = 16;
  static const double spacingLg = 20;
  static const double spacingXl = 24;
  static const double spacingXxl = 32;

  // ── Border radii ──
  static const double radiusXs = 6;
  static const double radiusSm = 10;
  static const double radiusMd = 16;
  static const double radiusLg = 20;
  static const double radiusXl = 24;
  static const double radiusFull = 999;

  /// Convenience BorderRadius objects.
  static final BorderRadius borderRadiusSm = BorderRadius.circular(radiusSm);
  static final BorderRadius borderRadiusMd = BorderRadius.circular(radiusMd);
  static final BorderRadius borderRadiusLg = BorderRadius.circular(radiusLg);
  static final BorderRadius borderRadiusPill = BorderRadius.circular(radiusFull);
}
