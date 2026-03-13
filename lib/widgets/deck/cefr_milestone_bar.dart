import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/cefr_level_provider.dart';

/// CEFR milestone progress bar using the weighted scoring system.
class CefrMilestoneBar extends ConsumerWidget {
  const CefrMilestoneBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = ref.watch(cefrLevelProvider);
    final isMax = level.currentLevel == 'C2' && level.progress >= 1.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Current level badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.accentDim,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              level.currentLevel,
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Progress bar
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: level.progress.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accent, Color(0xFFF0C060)],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Label
          Text(
            isMax ? 'Max level' : '${level.pointsToNext} to ${level.nextLevel}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textDim,
            ),
          ),
          const SizedBox(width: 6),
          // Info button
          GestureDetector(
            onTap: () => context.push('/stats'),
            child: const Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: AppColors.textDim,
            ),
          ),
        ],
      ),
    );
  }
}
