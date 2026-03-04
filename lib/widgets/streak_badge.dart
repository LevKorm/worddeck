import 'package:flutter/material.dart';

/// Fire icon + streak day count shown on the Translate screen.
class StreakBadge extends StatelessWidget {
  final int streakDays;

  const StreakBadge({super.key, required this.streakDays});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF97316).withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFF97316).withAlpha(51),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text(
            '$streakDays',
            style: theme.textTheme.labelLarge?.copyWith(
              color: const Color(0xFFF97316),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
