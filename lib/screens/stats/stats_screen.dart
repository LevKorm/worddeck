import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/statistics_provider.dart';
import '../../widgets/mastery_breakdown.dart';
import '../../widgets/stats_card.dart';
import 'stats_controller.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats        = ref.watch(fullStatisticsProvider);
    final isRefreshing = ref.watch(statsControllerProvider);
    final theme        = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(statsControllerProvider.notifier).refresh(),
        child: isRefreshing
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  // 2×2 summary grid with count-up animations
                  GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _AnimatedStatsCard(
                        icon: Icons.layers_rounded,
                        value: stats.totalCards,
                        label: 'Total Words',
                        color: const Color(0xFF6366F1),
                        delay: 0,
                      ),
                      _AnimatedStatsCard(
                        icon: Icons.flash_on_rounded,
                        value: stats.dueToday,
                        label: 'Due Today',
                        color: const Color(0xFFF59E0B),
                        delay: 80,
                      ),
                      _AnimatedStatsCard(
                        icon: Icons.local_fire_department_rounded,
                        value: stats.currentStreak,
                        label: 'Day Streak',
                        color: const Color(0xFFEF4444),
                        delay: 160,
                      ),
                      _AnimatedStatsCard(
                        icon: Icons.today_rounded,
                        value: stats.reviewsToday,
                        label: 'Reviewed Today',
                        color: const Color(0xFF22C55E),
                        delay: 240,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Daily goal progress
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.flag_rounded, size: 20),
                              const SizedBox(width: 8),
                              Text('Daily Goal',
                                  style: theme.textTheme.titleMedium),
                              const Spacer(),
                              Text(
                                '${stats.reviewsToday} / ${stats.dailyGoal}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween<double>(
                                begin: 0,
                                end: stats.dailyGoalProgress,
                              ),
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.easeOut,
                              builder: (_, value, __) =>
                                  LinearProgressIndicator(
                                value: value,
                                minHeight: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                      .animate(delay: 300.ms)
                      .fade(duration: 400.ms)
                      .slideY(begin: 0.1, end: 0, duration: 400.ms),

                  const SizedBox(height: 12),

                  // Mastery breakdown
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.school_rounded, size: 20),
                              const SizedBox(width: 8),
                              Text('Mastery Breakdown',
                                  style: theme.textTheme.titleMedium),
                            ],
                          ),
                          const SizedBox(height: 16),
                          MasteryBreakdown(
                            newCount:      stats.newCards,
                            learningCount: stats.learningCards,
                            reviewCount:   stats.reviewCards,
                            matureCount:   stats.matureCards,
                          ),
                        ],
                      ),
                    ),
                  )
                      .animate(delay: 400.ms)
                      .fade(duration: 400.ms)
                      .slideY(begin: 0.1, end: 0, duration: 400.ms),

                  const SizedBox(height: 12),

                  // Added today
                  if (stats.wordsAddedToday > 0)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.add_circle_outline_rounded),
                        title: const Text('Words added today'),
                        trailing: Text(
                          '${stats.wordsAddedToday}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    )
                        .animate(delay: 500.ms)
                        .fade(duration: 400.ms)
                        .slideY(begin: 0.1, end: 0, duration: 400.ms),
                ],
              ),
      ),
    );
  }
}

/// StatsCard with a count-up animation on the value.
class _AnimatedStatsCard extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final Color color;
  final int delay;

  const _AnimatedStatsCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      builder: (_, animatedValue, __) => StatsCard(
        icon: icon,
        value: '$animatedValue',
        label: label,
        color: color,
      ),
    )
        .animate(delay: Duration(milliseconds: delay))
        .fade(duration: 350.ms)
        .scale(
          begin: const Offset(0.85, 0.85),
          end: const Offset(1, 1),
          duration: 350.ms,
          curve: Curves.easeOut,
        );
  }
}
