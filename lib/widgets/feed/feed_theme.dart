import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Feed-specific color palette shared across all feed widgets.
abstract final class FeedTheme {
  static const Color accent       = AppColors.accent;
  static const Color accentSoft   = AppColors.accentDim;
  static const Color success      = Color(0xFF4ADE80);
  static const Color warning      = Color(0xFFFFA94D);
  static const Color error        = Color(0xFFFF6B6B);
  static const Color info         = Color(0xFF74C0FC);
  static const Color heart        = Color(0xFFFF4D6A);
  static const Color suggest      = Color(0xFF38BDF8);
  static const Color purple       = Color(0xFFB06CFF);

  static const Color bgDark        = Color(0xFF0D0D1A);
  static const Color surfaceDark   = Color(0xFF13131F);
  static const Color cardDark      = Color(0xFF1A1A2E);
  static const Color borderDark    = Color(0xFF2A2A4A);
  static const Color textPrimary   = Color(0xFFF5F0E8);
  static const Color textSecondary = Color(0xFFB0A898);

  /// Uppercase type label on slide gradient backgrounds (white @ 35%).
  static const TextStyle typeLabelStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
    color: Color(0x59FFFFFF),
  );
}

/// Small pill/badge widget reused across many slides.
class FeedTag extends StatelessWidget {
  final String label;
  final Color color;
  final double fontSize;

  const FeedTag({
    super.key,
    required this.label,
    required this.color,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(38),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Horizontal rule with optional label.
class FeedDivider extends StatelessWidget {
  const FeedDivider({super.key});

  @override
  Widget build(BuildContext context) => Container(
        height: 1,
        color: Theme.of(context).dividerColor,
      );
}
