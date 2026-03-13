import 'package:flutter/material.dart';
import '../../core/cefr/cefr_level_calculator.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';

class LevelHeroCard extends StatelessWidget {
  final CefrLevelResult level;

  const LevelHeroCard({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    final meta = cefrLevelMeta[level.currentLevel];
    final isMax = level.currentLevel == 'C2' && level.progress >= 1.0;
    final pctText = '${(level.progress * 100).round()}%';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surface3, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emoji
          if (meta != null)
            Text(meta.emoji, style: AppTheme.emojiStyle.copyWith(fontSize: 32)),
          const SizedBox(height: 12),

          // Level code
          Text(
            level.currentLevel,
            style: const TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 4),

          // Level name
          Text(
            meta?.name ?? level.currentLevel,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 20),

          // Progress bar + percentage
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: level.progress.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.accent, Color(0xFFF0C060)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                pctText,
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Points to next
          Text(
            isMax
                ? 'You\'ve reached the highest level!'
                : '${level.pointsToNext} points to ${level.nextLevel}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),

          // Description
          if (meta != null)
            Text(
              meta.description,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
        ],
      ),
    );
  }
}
