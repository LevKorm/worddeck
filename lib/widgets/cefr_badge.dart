import 'package:flutter/material.dart';

/// A compact badge that shows a CEFR level (A1–C2).
/// Returns [SizedBox.shrink] when [level] is null.
class CefrBadge extends StatelessWidget {
  final String? level;
  final double fontSize;

  const CefrBadge({super.key, required this.level, this.fontSize = 10});

  @override
  Widget build(BuildContext context) {
    if (level == null) return const SizedBox.shrink();
    final color = _colorFor(level!);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4), width: 0.8),
      ),
      child: Text(
        level!,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  static Color colorForLevel(String level) => _colorFor(level);

  static Color _colorFor(String level) {
    switch (level) {
      case 'A1': return const Color(0xFF4CAF50); // green
      case 'A2': return const Color(0xFF8BC34A); // light green
      case 'B1': return const Color(0xFF2196F3); // blue
      case 'B2': return const Color(0xFF9C27B0); // purple
      case 'C1': return const Color(0xFFFF9800); // orange
      case 'C2': return const Color(0xFFF44336); // red
      default:   return const Color(0xFF9E9E9E); // grey
    }
  }
}
