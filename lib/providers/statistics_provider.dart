import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/level_definitions.dart';
import '../models/app_statistics.dart';
import '../modules/cards/card_provider.dart';

// ── SharedPreferences keys ────────────────────────────────────────────────────
const _kStreak       = 'stats_streak';
const _kStreakDate   = 'stats_streak_date';
const _kReviewsToday = 'stats_reviews_today';
const _kReviewsDate  = 'stats_reviews_date';
const _kDailyGoal    = 'stats_daily_goal';

const _defaultDailyGoal = 10;

// ── Statistics provider ───────────────────────────────────────────────────────

/// Calculates AppStatistics from the loaded card list + SharedPreferences.
/// Reactively updates when cardListProvider changes.
final statisticsProvider = Provider.autoDispose<AppStatistics>((ref) {
  final cardState = ref.watch(cardListProvider);
  final cards     = cardState.allCards;

  if (cards.isEmpty) return AppStatistics.empty;

  final now   = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // Mastery breakdown (by intervalDays thresholds from Flutter prototype)
  var newCount      = 0;
  var learningCount = 0;
  var reviewCount   = 0;
  var matureCount   = 0;

  var wordsAddedToday = 0;
  var dueToday        = 0;

  for (final card in cards) {
    // Mastery level
    if (card.repetitions == 0) {
      newCount++;
    } else if (card.intervalDays < 7) {
      learningCount++;
    } else if (card.intervalDays < 21) {
      reviewCount++;
    } else {
      matureCount++;
    }

    // Due today
    if (card.isDue) dueToday++;

    // Added today
    final cardDate = DateTime(
        card.createdAt.year, card.createdAt.month, card.createdAt.day);
    if (cardDate == today) wordsAddedToday++;
  }

  // Streak + reviews today are stored in SharedPreferences.
  // We read them synchronously via a separate provider.
  // (Async values use separate providers below.)
  return AppStatistics(
    totalCards:     cards.length,
    dueToday:       dueToday,
    newCards:       newCount,
    learningCards:  learningCount,
    reviewCards:    reviewCount,
    matureCards:    matureCount,
    wordsAddedToday:wordsAddedToday,
    // Streak/reviews loaded separately
  );
});

// ── Streak + session tracking ─────────────────────────────────────────────────

class SessionStatsNotifier extends StateNotifier<SessionStats> {
  SessionStatsNotifier() : super(const SessionStats()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayStr();

    int streak = prefs.getInt(_kStreak) ?? 0;
    final reviewsDate = prefs.getString(_kReviewsDate) ?? '';
    final dailyGoal = prefs.getInt(_kDailyGoal) ?? _defaultDailyGoal;

    // Reset reviews counter if it's a new day
    final reviewsToday = reviewsDate == today
        ? (prefs.getInt(_kReviewsToday) ?? 0)
        : 0;

    state = SessionStats(
      currentStreak: streak,
      reviewsToday:  reviewsToday,
      dailyGoal:     dailyGoal,
    );
  }

  /// Call after each successful review session completion.
  Future<void> recordReview() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayStr();
    final yesterday = _yesterdayStr();

    // Update review count
    final reviewsDate  = prefs.getString(_kReviewsDate) ?? '';
    final reviewsToday = reviewsDate == today
        ? (prefs.getInt(_kReviewsToday) ?? 0) + 1
        : 1;
    await prefs.setInt(_kReviewsToday, reviewsToday);
    await prefs.setString(_kReviewsDate, today);

    // Update streak
    int streak = prefs.getInt(_kStreak) ?? 0;
    final streakDate = prefs.getString(_kStreakDate) ?? '';
    if (streakDate == today) {
      // Already counted today
    } else if (streakDate == yesterday) {
      streak++;                                  // consecutive day
    } else {
      streak = 1;                                // reset
    }
    await prefs.setInt(_kStreak, streak);
    await prefs.setString(_kStreakDate, today);

    state = state.copyWith(
      currentStreak: streak,
      reviewsToday:  reviewsToday,
    );
  }

  Future<void> setDailyGoal(int goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kDailyGoal, goal);
    state = state.copyWith(dailyGoal: goal);
  }

  static String _todayStr() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  static String _yesterdayStr() {
    final n = DateTime.now().subtract(const Duration(days: 1));
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }
}

class SessionStats {
  final int currentStreak;
  final int reviewsToday;
  final int dailyGoal;

  const SessionStats({
    this.currentStreak = 0,
    this.reviewsToday  = 0,
    this.dailyGoal     = _defaultDailyGoal,
  });

  SessionStats copyWith({int? currentStreak, int? reviewsToday, int? dailyGoal}) =>
      SessionStats(
        currentStreak: currentStreak ?? this.currentStreak,
        reviewsToday:  reviewsToday  ?? this.reviewsToday,
        dailyGoal:     dailyGoal     ?? this.dailyGoal,
      );

  double get dailyGoalProgress =>
      dailyGoal == 0 ? 0 : (reviewsToday / dailyGoal).clamp(0.0, 1.0);
}

final sessionStatsProvider =
    StateNotifierProvider<SessionStatsNotifier, SessionStats>(
  (ref) => SessionStatsNotifier(),
);

/// Current level definition based on word count.
final levelProvider = Provider.autoDispose<LevelDef>((ref) {
  final cards = ref.watch(cardListProvider).allCards;
  return getLevelForWords(cards.length);
});

/// Progress within the current level (0.0–1.0).
final levelProgressProvider = Provider.autoDispose<double>((ref) {
  final cards = ref.watch(cardListProvider).allCards;
  return getLevelProgress(cards.length);
});

/// CEFR level breakdown: level → count of cards at that level.
/// Only includes levels that have at least 1 card.
final cefrBreakdownProvider = Provider.autoDispose<Map<String, int>>((ref) {
  final cards = ref.watch(cardListProvider).allCards;
  final breakdown = <String, int>{};
  for (final card in cards) {
    if (card.cefrLevel != null) {
      breakdown[card.cefrLevel!] = (breakdown[card.cefrLevel!] ?? 0) + 1;
    }
  }
  return breakdown;
});

/// Full statistics combining card data + session data.
final fullStatisticsProvider = Provider.autoDispose<AppStatistics>((ref) {
  final base    = ref.watch(statisticsProvider);
  final session = ref.watch(sessionStatsProvider);
  return AppStatistics(
    totalCards:      base.totalCards,
    dueToday:        base.dueToday,
    newCards:        base.newCards,
    learningCards:   base.learningCards,
    reviewCards:     base.reviewCards,
    matureCards:     base.matureCards,
    wordsAddedToday: base.wordsAddedToday,
    currentStreak:   session.currentStreak,
    reviewsToday:    session.reviewsToday,
    dailyGoal:       session.dailyGoal,
  );
});
