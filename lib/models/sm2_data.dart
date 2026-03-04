/// SM-2 spaced repetition state — mirrors Supabase cards table columns:
///   ease_factor   float  DEFAULT 2.5
///   interval_days int    DEFAULT 0
///   repetitions   int    DEFAULT 0
///   next_review   timestamptz DEFAULT now()
///
/// Algorithm (from Next.js lib/sm2.ts):
///   EF' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
///   quality < 3  → reset: reps=0, interval=1
///   rep 1 → interval=1, rep 2 → interval=6, rep 3+ → round(interval * EF)
///   min EF = 1.3
class SM2Data {
  final int repetitions;
  final int intervalDays;
  final double easeFactor;
  final DateTime nextReview;

  const SM2Data({
    required this.repetitions,
    required this.intervalDays,
    required this.easeFactor,
    required this.nextReview,
  });

  factory SM2Data.initial() => SM2Data(
        repetitions: 0,
        intervalDays: 0,
        easeFactor: 2.5,
        nextReview: DateTime.now(),
      );

  SM2Data applyRating(int quality) {
    final now = DateTime.now();

    if (quality < 3) {
      return SM2Data(
        repetitions: 0,
        intervalDays: 1,
        easeFactor: easeFactor,
        nextReview: now.add(const Duration(days: 1)),
      );
    }

    final newReps = repetitions + 1;
    final int newInterval = switch (newReps) {
      1 => 1,
      2 => 6,
      _ => (intervalDays * easeFactor).round(),
    };

    var newEF =
        easeFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    if (newEF < 1.3) newEF = 1.3;

    return SM2Data(
      repetitions: newReps,
      intervalDays: newInterval,
      easeFactor: newEF,
      nextReview: now.add(Duration(days: newInterval)),
    );
  }

  bool get isDue => nextReview.isBefore(DateTime.now());
}
