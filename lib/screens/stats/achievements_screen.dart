import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/level_definitions.dart';
import '../../core/theme/app_theme.dart';
import '../../modules/cards/card_provider.dart';

enum _AchievementState { completed, current, locked }

_AchievementState _getState(LevelDef levelDef, int currentLevel) {
  if (levelDef.level < currentLevel) return _AchievementState.completed;
  if (levelDef.level == currentLevel) return _AchievementState.current;
  return _AchievementState.locked;
}

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wordCount = ref.watch(cardListProvider).allCards.length;
    final currentLevel = getLevelForWords(wordCount);
    final progress = getLevelProgress(wordCount);
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.bg,
            title: const Text('Achievements'),
          ),

          // Current level hero
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: _CurrentLevelHero(
                level: currentLevel,
                progress: progress,
                wordCount: wordCount,
              ),
            ),
          ),

          // Section header
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                'Vocabulary Levels',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
            ),
          ),

          // Level tiles
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final lv = levels[index];
                final state = _getState(lv, currentLevel.level);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _LevelAchievementTile(
                        level: lv,
                        state: state,
                        levelProgress: state == _AchievementState.current
                            ? progress
                            : null,
                      ),
                      if (index < levels.length - 1)
                        Divider(
                          height: 1,
                          thickness: 0.5,
                          color: AppColors.surface3,
                          indent: 20,
                          endIndent: 20,
                        ),
                    ],
                  ),
                );
              },
              childCount: levels.length,
            ),
          ),

          // Coming soon header
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Text(
                'Coming Soon',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
            ),
          ),

          // Coming soon card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _ComingSoonCard(),
            ),
          ),

          // Bottom padding
          SliverToBoxAdapter(
            child: SizedBox(height: 100 + safeBottom),
          ),
        ],
      ),
    );
  }
}

class _CurrentLevelHero extends StatelessWidget {
  final LevelDef level;
  final double progress;
  final int wordCount;

  const _CurrentLevelHero({
    required this.level,
    required this.progress,
    required this.wordCount,
  });

  @override
  Widget build(BuildContext context) {
    final isMax = level.level == 14;
    final nextLevel =
        isMax ? level : getLevelForWords(level.startWords + level.span);
    final remaining = wordsToNextLevel(wordCount);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [level.colorPrimary, level.colorSecondary],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${level.level}',
                style: AppTheme.statNumberStyle.copyWith(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      level.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor:
                  AlwaysStoppedAnimation(Colors.white.withValues(alpha: 0.6)),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isMax
                ? 'Maximum level reached'
                : '$remaining words to ${nextLevel.name}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelAchievementTile extends StatelessWidget {
  final LevelDef level;
  final _AchievementState state;
  final double? levelProgress;

  const _LevelAchievementTile({
    required this.level,
    required this.state,
    this.levelProgress,
  });

  @override
  Widget build(BuildContext context) {
    final isLocked = state == _AchievementState.locked;
    final isCurrent = state == _AchievementState.current;
    final isCompleted = state == _AchievementState.completed;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Level icon
          Opacity(
            opacity: isLocked ? 0.3 : 1.0,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [level.colorPrimary, level.colorSecondary],
                ),
                borderRadius: BorderRadius.circular(12),
                border: isCurrent
                    ? Border.all(
                        color: level.colorPrimary.withValues(alpha: 0.15),
                        width: 1)
                    : null,
              ),
              alignment: Alignment.center,
              child: isLocked
                  ? Icon(Icons.lock_rounded,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.5))
                  : Text(
                      '${level.level}',
                      style: AppTheme.statNumberStyle.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  level.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isLocked ? AppColors.textDim : AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  level.description,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isLocked ? AppColors.textDim : AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  level.startWords == 0
                      ? 'Starting level'
                      : 'Unlocked at ${level.startWords} words',
                  style: AppTheme.statNumberStyle.copyWith(
                    fontSize: 10,
                    color: AppColors.textDim,
                  ),
                ),
              ],
            ),
          ),
          // Right indicator
          if (isCompleted)
            Icon(Icons.check_circle_rounded,
                size: 20, color: level.colorPrimary),
          if (isCurrent && levelProgress != null)
            SizedBox(
              width: 24,
              height: 24,
              child: CustomPaint(
                painter: _MiniProgressRing(
                  progress: levelProgress!,
                  color: level.colorPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniProgressRing extends CustomPainter {
  final double progress;
  final Color color;

  _MiniProgressRing({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Fill
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_MiniProgressRing old) =>
      old.progress != progress || old.color != color;
}

class _ComingSoonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.surface3, width: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'More achievements coming soon',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: const [
              _FutureChip(label: '🔥 Streak milestones'),
              _FutureChip(label: '📚 Review milestones'),
              _FutureChip(label: '📁 Collection goals'),
              _FutureChip(label: '🌍 Multi-language badges'),
            ],
          ),
        ],
      ),
    );
  }
}

class _FutureChip extends StatelessWidget {
  final String label;
  const _FutureChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, color: AppColors.textDim),
      ),
    );
  }
}
