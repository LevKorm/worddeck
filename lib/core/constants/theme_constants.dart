import 'package:flutter/material.dart';

class ThemeConstants {
  ThemeConstants._();

  // ── Brand ────────────────────────────────────────────────────────────────
  static const Color primaryOrange     = Color(0xFFF5A623);
  static const Color primaryOrangeLight= Color(0xFFFFBD4F);
  static const Color primaryOrangeDark = Color(0xFFD4891A);

  // ── Light mode ───────────────────────────────────────────────────────────
  static const Color bgLight           = Color(0xFFFFF8F0);  // warm cream
  static const Color surfaceLight      = Color(0xFFFFFFFF);
  static const Color cardLight         = Color(0xFFFFFDF8);
  static const Color borderLight       = Color(0xFFEEE0CC);
  static const Color textPrimaryLight  = Color(0xFF1A1208);
  static const Color textSecondaryLight= Color(0xFF7A6652);

  // ── Dark mode ────────────────────────────────────────────────────────────
  static const Color bgDark            = Color(0xFF0D0D1A);  // deep dark
  static const Color surfaceDark       = Color(0xFF13131F);  // slightly elevated
  static const Color cardDark          = Color(0xFF1A1A2E);  // card surface
  static const Color borderDark        = Color(0xFF2A2A4A);
  static const Color textPrimaryDark   = Color(0xFFF5F0E8);
  static const Color textSecondaryDark = Color(0xFFB0A898);

  // ── Status colors (card learning states) ─────────────────────────────────
  static const Color statusPending  = Color(0xFF9CA3AF);  // gray
  static const Color statusLearning = Color(0xFF3B82F6);  // blue
  static const Color statusMastered = Color(0xFF22C55E);  // green

  // ── Review rating colors ──────────────────────────────────────────────────
  static const Color ratingAgain = Color(0xFFEF4444);  // quality 0
  static const Color ratingHard  = Color(0xFFF97316);  // quality 3
  static const Color ratingGood  = Color(0xFF3B82F6);  // quality 4
  static const Color ratingEasy  = Color(0xFF22C55E);  // quality 5

  // ── Spacing ───────────────────────────────────────────────────────────────
  static const double spaceXXS =  2.0;
  static const double spaceXS  =  4.0;
  static const double spaceSM  =  8.0;
  static const double spaceMD  = 16.0;
  static const double spaceLG  = 24.0;
  static const double spaceXL  = 32.0;
  static const double spaceXXL = 48.0;

  // ── Border radius ─────────────────────────────────────────────────────────
  static const double radiusXS =  4.0;
  static const double radiusSM =  8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusFull = 999.0;

  // ── Elevation ────────────────────────────────────────────────────────────
  static const double elevationCard = 2.0;
  static const double elevationSheet = 4.0;
}
