/// All statistics shown on the Stats screen.
/// Calculated from FlashCard data in Supabase.
class AppStatistics {
  final int totalCards;
  final int dueToday;

  // Mastery breakdown (based on intervalDays thresholds)
  final int newCards;       // repetitions == 0
  final int learningCards;  // intervalDays < 7  (and repetitions > 0)
  final int reviewCards;    // 7 <= intervalDays < 21
  final int matureCards;    // intervalDays >= 21

  final int wordsAddedToday;  // createdAt >= today midnight
  final int currentStreak;    // stored in SharedPreferences
  final int reviewsToday;     // stored in SharedPreferences
  final int dailyGoal;        // stored in SharedPreferences (default 10)

  double get accuracy {
    final studied = totalCards - newCards;
    if (studied == 0) return 0;
    // Proxy: percentage of studied cards with ease_factor >= 2.0 (performing well)
    return matureCards / (studied == 0 ? 1 : studied);
  }

  double get dailyGoalProgress =>
      dailyGoal == 0 ? 0 : (reviewsToday / dailyGoal).clamp(0.0, 1.0);

  const AppStatistics({
    this.totalCards = 0,
    this.dueToday = 0,
    this.newCards = 0,
    this.learningCards = 0,
    this.reviewCards = 0,
    this.matureCards = 0,
    this.wordsAddedToday = 0,
    this.currentStreak = 0,
    this.reviewsToday = 0,
    this.dailyGoal = 10,
  });

  static const empty = AppStatistics();
}
