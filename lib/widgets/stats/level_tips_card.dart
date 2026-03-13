import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';

class LevelTipsCard extends StatelessWidget {
  const LevelTipsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surface3, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'WHAT MOVES YOUR LEVEL UP',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textDim,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 14),
          _TipRow(emoji: '📖', text: 'Save new words'),
          _TipRow(emoji: '🔄', text: 'Review regularly'),
          _TipRow(emoji: '⭐', text: 'Master words you\'ve learned'),
          const SizedBox(height: 12),
          const Text(
            'The more words you master, the faster you climb.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              fontStyle: FontStyle.italic,
              color: AppColors.textDim,
            ),
          ),
        ],
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  final String emoji;
  final String text;

  const _TipRow({required this.emoji, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(emoji, style: AppTheme.emojiStyle.copyWith(fontSize: 16)),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
