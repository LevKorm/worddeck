import '../../contracts/i_review_engine.dart';
import '../../models/sm2_data.dart';
import '../../models/review_rating.dart';

/// Pure SM-2 spaced repetition engine.
///
/// Exact port of Next.js lib/sm2.ts — behavior is identical.
///
/// Algorithm:
///   quality 0 (Again): reset repetitions=0, interval=1 day, easeFactor UNCHANGED
///   quality 3 (Hard):  newReps++, EF decreases, interval by formula
///   quality 4 (Good):  newReps++, EF slight decrease, interval by formula
///   quality 5 (Easy):  newReps++, EF increases, interval by formula
///
/// Interval formula:
///   rep 1 → 1 day
///   rep 2 → 6 days
///   rep 3+ → round(intervalDays × easeFactor)
///
/// Ease factor formula (SM-2 standard):
///   EF' = EF + (0.1 - (5 - q) × (0.08 + (5 - q) × 0.02))
///   Minimum EF = 1.3
///
/// NOTE: The ease factor is NOT decreased on "Again" (quality 0).
/// This matches the Next.js implementation exactly. The formula only
/// applies when quality >= 3.
class SM2Engine implements IReviewEngine {
  const SM2Engine();

  @override
  SM2Data calculateNext(SM2Data current, ReviewRating rating) {
    final q = rating.quality;
    final now = DateTime.now();

    // Forgotten — reset progress, keep ease factor
    if (q < 3) {
      return SM2Data(
        repetitions: 0,
        intervalDays: 1,
        easeFactor: current.easeFactor,
        nextReview: now.add(const Duration(days: 1)),
      );
    }

    final newReps = current.repetitions + 1;

    // Interval schedule (matching Next.js)
    final int newInterval = switch (newReps) {
      1 => 1,
      2 => 6,
      _ => (current.intervalDays * current.easeFactor).round(),
    };

    // SM-2 ease factor update
    var newEF = current.easeFactor +
        (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02));
    if (newEF < 1.3) newEF = 1.3;

    return SM2Data(
      repetitions: newReps,
      intervalDays: newInterval,
      easeFactor: newEF,
      nextReview: now.add(Duration(days: newInterval)),
    );
  }

  @override
  SM2Data createInitial() => SM2Data.initial();

  /// Preview interval text without applying the review.
  /// Used by the review screen to show "1d / 6d / ~12d" hints on buttons.
  String previewInterval(SM2Data current, ReviewRating rating) {
    final next = calculateNext(current, rating);
    final days = next.intervalDays;
    if (days <= 1)  return '1d';
    if (days < 7)   return '${days}d';
    if (days < 30)  return '${(days / 7).round()}w';
    if (days < 365) return '${(days / 30).round()}mo';
    return '${(days / 365).round()}y';
  }
}
