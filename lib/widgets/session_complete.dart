import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/constants/app_colors.dart';

/// Celebration widget shown when all due cards have been reviewed.
class SessionComplete extends StatelessWidget {
  final int cardsReviewed;

  const SessionComplete({super.key, required this.cardsReviewed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const green = AppColors.green;
    const orange = AppColors.accent;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated green checkmark circle
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: green.withAlpha(26),
                shape: BoxShape.circle,
                border: Border.all(color: green.withAlpha(77), width: 2),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: green,
                size: 40,
              ),
            )
                .animate()
                .scale(
                  begin: const Offset(0.3, 0.3),
                  end: const Offset(1, 1),
                  duration: 500.ms,
                  curve: Curves.elasticOut,
                )
                .fade(duration: 300.ms),

            const SizedBox(height: 20),

            // Title
            Text(
              'All caught up!',
              style: theme.textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            )
                .animate(delay: 200.ms)
                .slideY(begin: 0.3, end: 0, duration: 400.ms, curve: Curves.easeOut)
                .fade(duration: 300.ms),

            const SizedBox(height: 8),

            // Subtitle
            Text(
              'You\'ve reviewed all due cards.\nCheck back later for more!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            )
                .animate(delay: 350.ms)
                .slideY(begin: 0.3, end: 0, duration: 400.ms, curve: Curves.easeOut)
                .fade(duration: 300.ms),

            // Session summary card (only when cards were reviewed)
            if (cardsReviewed > 0) ...[
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: green.withAlpha(15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: green.withAlpha(38)),
                ),
                child: Column(
                  children: [
                    // Celebration emoji row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🎉', style: TextStyle(fontSize: 28))
                            .animate(delay: 500.ms)
                            .scale(
                              begin: const Offset(0, 0),
                              duration: 400.ms,
                              curve: Curves.elasticOut,
                            ),
                        const SizedBox(width: 8),
                        const Text('🔥', style: TextStyle(fontSize: 28))
                            .animate(delay: 600.ms)
                            .scale(
                              begin: const Offset(0, 0),
                              duration: 400.ms,
                              curve: Curves.elasticOut,
                            ),
                        const SizedBox(width: 8),
                        const Text('⭐', style: TextStyle(fontSize: 28))
                            .animate(delay: 700.ms)
                            .scale(
                              begin: const Offset(0, 0),
                              duration: 400.ms,
                              curve: Curves.elasticOut,
                            ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Session complete!',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$cardsReviewed card${cardsReviewed == 1 ? '' : 's'} reviewed',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
                  .animate(delay: 450.ms)
                  .slideY(begin: 0.4, end: 0, duration: 450.ms, curve: Curves.easeOut)
                  .fade(duration: 350.ms),
            ],

            const SizedBox(height: 24),

            // Streak encouragement
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.local_fire_department_rounded,
                    color: orange, size: 20),
                const SizedBox(width: 6),
                Text(
                  'Keep your streak going!',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
                .animate(delay: 650.ms)
                .fade(duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
