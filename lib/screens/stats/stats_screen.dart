import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/level_definitions.dart';
import '../../core/theme/app_theme.dart' as app_theme;
import 'package:go_router/go_router.dart';
import '../../modules/cards/card_provider.dart';
import '../../providers/cefr_level_provider.dart';
import '../../providers/statistics_provider.dart';
import '../../widgets/cefr_badge.dart';
import '../../widgets/mastery_breakdown.dart';
import '../../widgets/stats/level_hero_card.dart';
import '../../widgets/stats/level_journey_list.dart';
import '../../widgets/stats/level_tips_card.dart';
import '../../widgets/stats_card.dart';
import 'stats_controller.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats        = ref.watch(fullStatisticsProvider);
    final cefrBreakdown = ref.watch(cefrBreakdownProvider);
    final cefrLevel    = ref.watch(cefrLevelProvider);
    final isRefreshing = ref.watch(statsControllerProvider);
    final theme        = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(statsControllerProvider.notifier).refresh(),
        child: isRefreshing
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  // ── YOUR LEVEL section ────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Text(
                      'YOUR LEVEL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDim,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  LevelHeroCard(level: cefrLevel)
                      .animate()
                      .fade(duration: 400.ms)
                      .slideY(begin: 0.1, end: 0, duration: 400.ms),
                  const SizedBox(height: 20),
                  LevelJourneyList(level: cefrLevel)
                      .animate(delay: 100.ms)
                      .fade(duration: 400.ms)
                      .slideY(begin: 0.1, end: 0, duration: 400.ms),
                  const SizedBox(height: 16),
                  const LevelTipsCard()
                      .animate(delay: 200.ms)
                      .fade(duration: 400.ms)
                      .slideY(begin: 0.1, end: 0, duration: 400.ms),
                  const SizedBox(height: 24),

                  // Level badge → Achievements page
                  _LevelNavRow(ref: ref),
                  const SizedBox(height: 12),
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
                        color: AppColors.indigo,
                        delay: 0,
                      ),
                      _AnimatedStatsCard(
                        icon: Icons.flash_on_rounded,
                        value: stats.dueToday,
                        label: 'Due Today',
                        color: AppColors.accent,
                        delay: 80,
                      ),
                      _AnimatedStatsCard(
                        icon: Icons.local_fire_department_rounded,
                        value: stats.currentStreak,
                        label: 'Day Streak',
                        color: AppColors.red,
                        delay: 160,
                      ),
                      _AnimatedStatsCard(
                        icon: Icons.today_rounded,
                        value: stats.reviewsToday,
                        label: 'Reviewed Today',
                        color: AppColors.green,
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

                  // CEFR breakdown
                  if (cefrBreakdown.isNotEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.bar_chart_rounded, size: 20),
                                const SizedBox(width: 8),
                                Text('CEFR Level Breakdown',
                                    style: theme.textTheme.titleMedium),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...['A1', 'A2', 'B1', 'B2', 'C1', 'C2']
                                .where((l) => cefrBreakdown.containsKey(l))
                                .map((level) {
                              final count = cefrBreakdown[level]!;
                              final pct = stats.totalCards > 0
                                  ? count / stats.totalCards
                                  : 0.0;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    CefrBadge(level: level, fontSize: 11),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: TweenAnimationBuilder<double>(
                                          tween: Tween<double>(begin: 0, end: pct),
                                          duration: const Duration(milliseconds: 700),
                                          curve: Curves.easeOut,
                                          builder: (_, v, __) =>
                                              LinearProgressIndicator(
                                            value: v,
                                            minHeight: 6,
                                            backgroundColor: theme
                                                .colorScheme.surfaceContainerHighest,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '$count',
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    )
                        .animate(delay: 450.ms)
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

class _LevelNavRow extends StatelessWidget {
  final WidgetRef ref;
  const _LevelNavRow({required this.ref});

  @override
  Widget build(BuildContext context) {
    final wordCount = ref.watch(cardListProvider).allCards.length;
    final level = getLevelForWords(wordCount);

    return GestureDetector(
      onTap: () => context.push('/stats/achievements'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.surface3, width: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              constraints: const BoxConstraints(minWidth: 32),
              height: 22,
              padding: const EdgeInsets.symmetric(horizontal: 7),
              decoration: BoxDecoration(
                color: level.badgeBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: level.badgeBorder, width: 1),
              ),
              alignment: Alignment.center,
              child: Text(
                'L${level.level}',
                style: app_theme.AppTheme.statNumberStyle.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: level.colorPrimary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Level ${level.level}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '· ${level.name}',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textDim, size: 20),
          ],
        ),
      ),
    );
  }
}
