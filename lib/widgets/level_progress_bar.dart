import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/level_definitions.dart';
import '../core/theme/app_theme.dart';
import '../modules/cards/card_provider.dart';
import '../providers/statistics_provider.dart';

/// Stores word count snapshot taken when leaving idle, so deferred playback
/// works even though the widget is unmounted during non-idle states.
final levelBarSnapshotProvider = StateProvider<int?>((ref) => null);

class LevelProgressBar extends ConsumerStatefulWidget {
  const LevelProgressBar({super.key});

  @override
  ConsumerState<LevelProgressBar> createState() => _LevelProgressBarState();
}

class _LevelProgressBarState extends ConsumerState<LevelProgressBar>
    with TickerProviderStateMixin {
  // Bar fill animation
  late AnimationController _barCtrl;
  late Animation<double> _barAnim;

  // Shimmer
  late AnimationController _shimmerCtrl;

  // Chamber animations
  late AnimationController _chamberCtrl;
  late Animation<double> _chamberScale;

  // +1 float
  late AnimationController _plusOneCtrl;
  late Animation<double> _plusOneOpacity;
  late Animation<double> _plusOneOffset;

  // Word count bump
  late AnimationController _countBumpCtrl;
  late Animation<double> _countScale;

  // Chamber merge (dissolve)
  late AnimationController _mergeCtrl;
  late Animation<double> _mergeOpacity;
  late Animation<double> _mergeScale;

  // Level-up animations
  late AnimationController _levelUpCtrl;
  late Animation<double> _levelUpOpacity;
  late Animation<double> _levelUpOffset;
  late AnimationController _badgeGlowCtrl;
  late Animation<double> _badgeGlowAnim;
  late AnimationController _badgeBumpCtrl;
  late Animation<double> _badgeBumpScale;

  // Streak animations
  late AnimationController _streakCtrl;
  late Animation<double> _streakFlameScale;
  late AnimationController _streakPlusCtrl;
  late Animation<double> _streakPlusOpacity;
  late Animation<double> _streakPlusOffset;
  late AnimationController _streakBumpCtrl;
  late Animation<double> _streakNumScale;

  // Streak particles
  late AnimationController _particleCtrl;
  List<_Particle> _particles = [];

  int _prevChambers = -1;
  int _prevWordCount = -1;
  int _prevLevel = -1;
  bool _showLevelUpName = false;
  String _levelUpName = '';

  // ── Deferred animation state ─────────────────────────────────────────
  // Display overrides during deferred playback
  int? _displayWordCount;
  int? _displayChambers;
  double? _displayProgress;
  LevelDef? _displayLevel;
  bool _isPlayingDeferred = false;

  @override
  void initState() {
    super.initState();

    _barCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _barAnim = Tween<double>(begin: 0, end: 0).animate(
        CurvedAnimation(parent: _barCtrl, curve: Curves.easeOutBack));

    // Check for deferred playback on fresh mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final snapshot = ref.read(levelBarSnapshotProvider);
      if (snapshot != null) {
        ref.read(levelBarSnapshotProvider.notifier).state = null;
        final currentCount = ref.read(cardListProvider).allCards.length;
        if (currentCount > snapshot) {
          _playDeferredFromSnapshot(snapshot, currentCount);
        }
      }
    });

    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat();

    _chamberCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _chamberScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.4, end: 1.4), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 50),
    ]).animate(
        CurvedAnimation(parent: _chamberCtrl, curve: Curves.easeOut));

    _plusOneCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _plusOneOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1, end: 1), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 30),
    ]).animate(_plusOneCtrl);
    _plusOneOffset = Tween<double>(begin: 0, end: -20).animate(
        CurvedAnimation(parent: _plusOneCtrl, curve: Curves.easeOut));

    _countBumpCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _countScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1, end: 1.25), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 50),
    ]).animate(
        CurvedAnimation(parent: _countBumpCtrl, curve: Curves.easeOut));

    _mergeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _mergeOpacity = Tween<double>(begin: 1, end: 0).animate(
        CurvedAnimation(parent: _mergeCtrl, curve: Curves.easeOut));
    _mergeScale = Tween<double>(begin: 1, end: 2.5).animate(
        CurvedAnimation(parent: _mergeCtrl, curve: Curves.easeOut));

    _levelUpCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _levelUpOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1, end: 1), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 30),
    ]).animate(_levelUpCtrl);
    _levelUpOffset = Tween<double>(begin: 0, end: -24).animate(
        CurvedAnimation(parent: _levelUpCtrl, curve: Curves.easeOut));

    _badgeGlowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _badgeGlowAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 0.5), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 0), weight: 50),
    ]).animate(
        CurvedAnimation(parent: _badgeGlowCtrl, curve: Curves.easeInOut));

    _badgeBumpCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _badgeBumpScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1, end: 1.25), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 60),
    ]).animate(
        CurvedAnimation(parent: _badgeBumpCtrl, curve: Curves.easeOut));

    // Streak animations
    _streakCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _streakFlameScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1, end: 1.6), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.6, end: 1.2), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 40),
    ]).animate(
        CurvedAnimation(parent: _streakCtrl, curve: Curves.easeOut));

    _streakPlusCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _streakPlusOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1, end: 1), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 40),
    ]).animate(_streakPlusCtrl);
    _streakPlusOffset = Tween<double>(begin: 0, end: -18).animate(
        CurvedAnimation(parent: _streakPlusCtrl, curve: Curves.easeOut));

    _streakBumpCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _streakNumScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1, end: 1.25), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 50),
    ]).animate(
        CurvedAnimation(parent: _streakBumpCtrl, curve: Curves.easeOut));

    _particleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
  }

  void _playDeferredFromSnapshot(int snapshotCount, int currentCount) {
    final level = getLevelForWords(snapshotCount);
    final wordsInLevel = snapshotCount - level.startWords;
    final fromChambers = wordsInLevel % 3;
    final fromLevel = level.level;
    final fromProgress = getLevelProgress(snapshotCount);

    _isPlayingDeferred = true;
    setState(() {
      _displayWordCount = snapshotCount;
      _displayChambers = fromChambers;
      _displayProgress = fromProgress;
      _displayLevel = level;
    });

    // Brief pause so user sees the "before" state
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _animateStepByStep(snapshotCount, currentCount, fromChambers, fromLevel, fromProgress);
    });
  }

  void _animateStepByStep(
      int fromCount, int toCount, int fromChambers, int fromLevel, double fromProgress) {
    final totalAdded = toCount - fromCount;
    int current = fromCount;
    int prevCh = fromChambers;
    int prevLv = fromLevel;

    void nextStep() {
      if (!mounted || current >= toCount) {
        // Done — clear overrides
        if (mounted) {
          setState(() {
            _displayWordCount = null;
            _displayChambers = null;
            _displayProgress = null;
            _displayLevel = null;
            _isPlayingDeferred = false;
          });
          // Sync internal tracking state
          _prevWordCount = toCount;
          final finalLevel = getLevelForWords(toCount);
          _prevLevel = finalLevel.level;
          final wil = toCount - finalLevel.startWords;
          _prevChambers = wil % 3;
          _barAnim = AlwaysStoppedAnimation(getLevelProgress(toCount));
        }
        return;
      }

      current++;
      final level = getLevelForWords(current);
      final progress = getLevelProgress(current);
      final wil = current - level.startWords;
      final newCh = wil % 3;

      setState(() {
        _displayWordCount = current;
        _displayChambers = newCh;
        _displayProgress = progress;
        _displayLevel = level;
      });

      // +1 float
      _plusOneCtrl.reset();
      _plusOneCtrl.forward();

      // Count bump
      _countBumpCtrl.reset();
      _countBumpCtrl.forward();

      // Chamber merge: prev was 2, now 0
      if (prevCh == 2 && newCh == 0) {
        _chamberCtrl.reset();
        _chamberCtrl.forward();
        Future.delayed(const Duration(milliseconds: 250), () {
          if (!mounted) return;
          _mergeCtrl.reset();
          _mergeCtrl.forward().then((_) {
            if (!mounted) return;
            // Grow bar
            _barAnim = Tween<double>(begin: _barAnim.value, end: progress)
                .animate(CurvedAnimation(
                    parent: _barCtrl, curve: Curves.easeOutBack));
            _barCtrl.reset();
            _barCtrl.forward();
            setState(() {});
          });
        });
      } else if (newCh > prevCh || (prevCh == 0 && newCh > 0)) {
        _chamberCtrl.reset();
        _chamberCtrl.forward();
      }

      // Level-up
      if (level.level > prevLv && prevLv > 0) {
        _onLevelUp(level);
      }

      prevCh = newCh;
      prevLv = level.level;

      // Stagger: fast if many words, slower if few
      final delay = totalAdded > 5
          ? const Duration(milliseconds: 150)
          : const Duration(milliseconds: 300);
      Future.delayed(delay, nextStep);
    }

    nextStep();
  }

  @override
  void dispose() {
    _barCtrl.dispose();
    _shimmerCtrl.dispose();
    _chamberCtrl.dispose();
    _plusOneCtrl.dispose();
    _countBumpCtrl.dispose();
    _mergeCtrl.dispose();
    _levelUpCtrl.dispose();
    _badgeGlowCtrl.dispose();
    _badgeBumpCtrl.dispose();
    _streakCtrl.dispose();
    _streakPlusCtrl.dispose();
    _streakBumpCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  void _onWordsAdded(int newCount) {
    // Suppress if currently playing deferred animation
    if (_isPlayingDeferred) return;

    final level = getLevelForWords(newCount);
    final progress = getLevelProgress(newCount);
    final wordsInLevel = newCount - level.startWords;
    final newChambers = wordsInLevel % 3;

    // +1 float
    _plusOneCtrl.reset();
    _plusOneCtrl.forward();

    // Count bump
    _countBumpCtrl.reset();
    _countBumpCtrl.forward();

    // Check level-up
    if (_prevLevel > 0 && level.level > _prevLevel) {
      _onLevelUp(level);
    }
    _prevLevel = level.level;

    // Chamber merge: previous was 2 and now 0
    if (_prevChambers == 2 && newChambers == 0) {
      _chamberCtrl.reset();
      _chamberCtrl.forward();
      Future.delayed(const Duration(milliseconds: 250), () {
        if (!mounted) return;
        _mergeCtrl.reset();
        _mergeCtrl.forward().then((_) {
          if (!mounted) return;
          _barAnim = Tween<double>(begin: _barAnim.value, end: progress)
              .animate(CurvedAnimation(
                  parent: _barCtrl, curve: Curves.easeOutBack));
          _barCtrl.reset();
          _barCtrl.forward();
          setState(() {});
        });
      });
    } else if (newChambers > _prevChambers && _prevChambers >= 0) {
      _chamberCtrl.reset();
      _chamberCtrl.forward();
    }

    _prevChambers = newChambers;
  }

  void _onLevelUp(LevelDef newLevel) {
    _levelUpName = '${newLevel.name}!';
    _showLevelUpName = true;
    _levelUpCtrl.reset();
    _levelUpCtrl.forward().then((_) {
      if (mounted) setState(() => _showLevelUpName = false);
    });

    _badgeGlowCtrl.reset();
    _badgeGlowCtrl.forward();

    _badgeBumpCtrl.reset();
    _badgeBumpCtrl.forward();
  }

  void _onStreakIncreased() {
    if (_isPlayingDeferred) return;

    _streakCtrl.reset();
    _streakCtrl.forward();

    _streakPlusCtrl.reset();
    _streakPlusCtrl.forward();

    _streakBumpCtrl.reset();
    _streakBumpCtrl.forward();

    final rng = math.Random();
    _particles = List.generate(6, (i) {
      final angle = (i / 6) * 2 * math.pi + rng.nextDouble() * 0.5;
      return _Particle(
        angle: angle,
        color: const [
          Color(0xFFE8A838),
          Color(0xFFF59E0B),
          Color(0xFFFB923C),
          Color(0xFFFBBF24),
        ][i % 4],
        distance: 12 + rng.nextDouble() * 8,
      );
    });
    _particleCtrl.reset();
    _particleCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    final cards = ref.watch(cardListProvider).allCards;
    final realWordCount = cards.length;
    final session = ref.watch(sessionStatsProvider);

    // Use display overrides during deferred playback
    final wordCount = _displayWordCount ?? realWordCount;
    final level = _displayLevel ?? getLevelForWords(wordCount);
    final progress = _displayProgress ?? getLevelProgress(wordCount);
    final wordsInLevel = wordCount - level.startWords;
    final chambersFilled = _displayChambers ?? (wordsInLevel % 3);

    // Initialize on first build
    if (_prevWordCount < 0) {
      _prevWordCount = realWordCount;
      _prevLevel = level.level;
      _prevChambers = chambersFilled;
      _barAnim = AlwaysStoppedAnimation(progress);
    }

    // Listen for card additions (suppressed during deferred playback)
    ref.listen(cardListProvider, (prev, next) {
      if (_isPlayingDeferred) return;
      final prevCount = prev?.allCards.length ?? 0;
      final newCount = next.allCards.length;
      if (newCount > prevCount) {
        _prevWordCount = newCount;
        _onWordsAdded(newCount);
      }
    });

    // Listen for streak increases
    ref.listen(sessionStatsProvider, (prev, next) {
      if ((next.currentStreak) > (prev?.currentStreak ?? 0)) {
        _onStreakIncreased();
      }
    });

    final isMaxLevel = level.level == 14;
    final nextLevel =
        isMaxLevel ? level : getLevelForWords(level.startWords + level.span);
    final remaining = isMaxLevel ? 0 : (level.startWords + level.span) - wordCount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top row: badge + word count + streak
          Row(
            children: [
              _buildBadge(level),
              const SizedBox(width: 10),
              _buildWordCount(
                  wordCount, remaining, nextLevel, isMaxLevel, level),
              const Spacer(),
              _buildStreak(session.currentStreak),
            ],
          ),
          const SizedBox(height: 8),
          // Bar row: progress bar + chambers
          SizedBox(
            height: 8,
            child: Row(
              children: [
                Expanded(child: _buildBar(progress, level)),
                const SizedBox(width: 4),
                _buildChambers(level, chambersFilled),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(LevelDef level) {
    return GestureDetector(
      onTap: () => context.push('/stats/achievements'),
      child: AnimatedBuilder(
        animation: Listenable.merge([_badgeGlowCtrl, _badgeBumpCtrl]),
        builder: (context, child) {
          return Transform.scale(
            scale: _badgeBumpCtrl.isAnimating ? _badgeBumpScale.value : 1.0,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  constraints: const BoxConstraints(minWidth: 32),
                  height: 22,
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  decoration: BoxDecoration(
                    color: level.badgeBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: level.badgeBorder, width: 1),
                    boxShadow: _badgeGlowCtrl.isAnimating
                        ? [
                            BoxShadow(
                              color: level.colorPrimary
                                  .withValues(alpha: _badgeGlowAnim.value),
                              blurRadius: 12,
                              spreadRadius: 2,
                            )
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'L${level.level}',
                    style: AppTheme.statNumberStyle.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: level.colorPrimary,
                    ),
                  ),
                ),
                if (_showLevelUpName)
                  AnimatedBuilder(
                    animation: _levelUpCtrl,
                    builder: (context, _) => Positioned(
                      left: 0,
                      right: 0,
                      top: _levelUpOffset.value,
                      child: Opacity(
                        opacity: _levelUpOpacity.value,
                        child: Text(
                          _levelUpName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: level.colorPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWordCount(
      int wordCount, int remaining, LevelDef nextLevel, bool isMax,
      LevelDef level) {
    return GestureDetector(
      onTap: () => context.push('/stats'),
      child: AnimatedBuilder(
        animation: Listenable.merge([_countBumpCtrl, _plusOneCtrl]),
        builder: (context, _) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Transform.scale(
                scale:
                    _countBumpCtrl.isAnimating ? _countScale.value : 1.0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$wordCount',
                      style: AppTheme.statNumberStyle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Text(
                      'words',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textDim,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isMax
                          ? '· max level'
                          : '· $remaining to Lv.${nextLevel.level}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textDim,
                      ),
                    ),
                  ],
                ),
              ),
              if (_plusOneCtrl.isAnimating)
                Positioned(
                  top: _plusOneOffset.value,
                  left: 0,
                  child: Opacity(
                    opacity: _plusOneOpacity.value,
                    child: Text(
                      '+1',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: level.colorPrimary,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStreak(int streak) {
    return GestureDetector(
      onTap: () => context.go('/review'),
      child: AnimatedBuilder(
        animation: Listenable.merge(
            [_streakCtrl, _streakPlusCtrl, _streakBumpCtrl, _particleCtrl]),
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  if (_particleCtrl.isAnimating)
                    ..._particles.map((p) {
                      final t = _particleCtrl.value;
                      final dx = math.cos(p.angle) * p.distance * t;
                      final dy = math.sin(p.angle) * p.distance * t;
                      return Positioned(
                        left: 15 + dx - 2,
                        top: 15 + dy - 2,
                        child: Opacity(
                          opacity: (1 - t).clamp(0.0, 1.0),
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: p.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      );
                    }),
                  Transform.scale(
                    scale: _streakCtrl.isAnimating
                        ? _streakFlameScale.value
                        : 1.0,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.accentDim,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child:
                          const Text('🔥', style: TextStyle(fontSize: 15)),
                    ),
                  ),
                  if (_streakPlusCtrl.isAnimating)
                    Positioned(
                      top: _streakPlusOffset.value,
                      left: 6,
                      child: Opacity(
                        opacity: _streakPlusOpacity.value,
                        child: const Text(
                          '+1',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 6),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Transform.scale(
                    scale: _streakBumpCtrl.isAnimating
                        ? _streakNumScale.value
                        : 1.0,
                    child: Text(
                      '$streak',
                      style: AppTheme.statNumberStyle.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                  const Text(
                    'streak',
                    style: TextStyle(fontSize: 9, color: AppColors.textDim),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBar(double progress, LevelDef level) {
    return AnimatedBuilder(
      animation: Listenable.merge([_barCtrl, _shimmerCtrl]),
      builder: (context, _) {
        final barProgress =
            _barCtrl.isAnimating ? _barAnim.value : progress;
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(4),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final fillWidth = constraints.maxWidth * barProgress;
                return Stack(
                  children: [
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: fillWidth,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: level.barGradient,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    if (fillWidth > 0)
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: fillWidth,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Transform.translate(
                            offset: Offset(
                              (fillWidth * 1.4) * _shimmerCtrl.value -
                                  fillWidth * 0.4,
                              0,
                            ),
                            child: Container(
                              width: fillWidth * 0.4,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.white.withValues(alpha: 0.10),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildChambers(LevelDef level, int chambersFilled) {
    return AnimatedBuilder(
      animation: Listenable.merge([_chamberCtrl, _mergeCtrl]),
      builder: (context, _) {
        final isMerging = _mergeCtrl.isAnimating;
        final displayCount = isMerging ? 3 : chambersFilled;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final filled = i < displayCount;
            final isNew =
                filled && i == displayCount - 1 && _chamberCtrl.isAnimating;

            Widget chamber = Container(
              width: 6,
              height: 8,
              margin: EdgeInsets.only(left: i > 0 ? 2 : 0),
              decoration: BoxDecoration(
                color: filled ? level.chamberFilled : level.chamberEmpty,
                borderRadius: BorderRadius.circular(2.5),
                border: Border.all(
                  color: filled
                      ? level.chamberBorderFilled
                      : level.chamberBorderEmpty,
                  width: 0.5,
                ),
              ),
            );

            if (isNew) {
              chamber = Transform.scale(
                scaleY: _chamberScale.value,
                scaleX: 0.6 + (_chamberScale.value - 0.4) * 0.5 / 0.6,
                child: chamber,
              );
            }

            if (isMerging && filled) {
              chamber = Opacity(
                opacity: _mergeOpacity.value,
                child: Transform.scale(
                  scaleX: _mergeScale.value,
                  child: chamber,
                ),
              );
            }

            return chamber;
          }),
        );
      },
    );
  }
}

class _Particle {
  final double angle;
  final Color color;
  final double distance;

  const _Particle({
    required this.angle,
    required this.color,
    required this.distance,
  });
}
