import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/flash_card.dart';
import '../../models/review_rating.dart';
import '../../modules/auth/auth_provider.dart';
import '../../modules/cards/card_provider.dart';
import '../../modules/notifications/notification_provider.dart';
import '../../modules/review/review_provider.dart';
import '../../modules/spaces/space_provider.dart';
import '../../providers/statistics_provider.dart';

// ── State ──────────────────────────────────────────────────────────────────

class ReviewControllerState {
  final bool isFlipped;
  final int cardsReviewed;
  final bool isLoading;

  const ReviewControllerState({
    this.isFlipped     = false,
    this.cardsReviewed = 0,
    this.isLoading     = false,
  });

  ReviewControllerState copyWith({
    bool? isFlipped,
    int?  cardsReviewed,
    bool? isLoading,
  }) =>
      ReviewControllerState(
        isFlipped:     isFlipped     ?? this.isFlipped,
        cardsReviewed: cardsReviewed ?? this.cardsReviewed,
        isLoading:     isLoading     ?? this.isLoading,
      );
}

// ── Notifier ───────────────────────────────────────────────────────────────

class ReviewController extends StateNotifier<ReviewControllerState> {
  final Ref _ref;

  ReviewController(this._ref) : super(const ReviewControllerState());

  Future<void> loadDueCards() async {
    state = state.copyWith(isLoading: true);
    final userId = _ref.read(currentUserProvider)?.userId;
    if (userId != null) {
      final spaceId = _ref.read(activeSpaceProvider)?.id;
      await _ref.read(reviewProvider.notifier).loadSession(userId, spaceId: spaceId);
    }
    state = state.copyWith(isLoading: false);
  }

  void flipCard() => state = state.copyWith(isFlipped: !state.isFlipped);

  Future<void> rateCard(ReviewRating rating) async {
    _ref.read(reviewProvider.notifier).rate(rating);
    await _ref.read(sessionStatsProvider.notifier).recordReview();

    state = state.copyWith(
      isFlipped:     false,
      cardsReviewed: state.cardsReviewed + 1,
    );

    // Check if session just completed and schedule next reminder
    final session = _ref.read(reviewProvider);
    session.whenData((s) {
      if (s.isComplete && state.cardsReviewed > 0) {
        _scheduleNextReminder();
      }
    });
  }

  Map<ReviewRating, String> getIntervals(FlashCard card) =>
      _ref.read(reviewIntervalPreviewProvider(card));

  // ── Notification scheduling ──────────────────────────────────────────────

  Future<void> _scheduleNextReminder() async {
    try {
      final notifSettings = _ref.read(notificationSettingsProvider);
      if (!notifSettings.enabled) return;

      final cards     = _ref.read(cardListProvider).allCards;
      final now       = DateTime.now();
      final dueCards  = cards.where((c) => c.isDue).toList();
      final dueSoon   = cards
          .where((c) => !c.isDue && c.nextReview.isAfter(now))
          .toList()
        ..sort((a, b) => a.nextReview.compareTo(b.nextReview));

      // Determine when to remind based on frequency
      final reminderHours = switch (notifSettings.frequency) {
        'low'  => 24,
        'high' => 8,
        _      => 12, // medium
      };

      DateTime reminderTime;

      if (dueCards.isNotEmpty) {
        // Cards already due — remind after a short break
        reminderTime = now.add(Duration(hours: reminderHours ~/ 3));
      } else if (dueSoon.isNotEmpty) {
        // Remind when the earliest card becomes due
        reminderTime = dueSoon.first.nextReview;
      } else {
        // No cards — remind tomorrow at a reasonable hour
        reminderTime = DateTime(
          now.year,
          now.month,
          now.day + 1,
          10, // 10am default
        );
      }

      // Respect quiet hours
      final inQuiet = reminderTime.hour < notifSettings.minHour ||
          reminderTime.hour >= notifSettings.maxHour;
      if (inQuiet) {
        reminderTime = DateTime(
          reminderTime.year,
          reminderTime.month,
          reminderTime.day,
          notifSettings.minHour,
        );
        if (reminderTime.isBefore(now)) {
          reminderTime = reminderTime.add(const Duration(days: 1));
        }
      }

      final totalDue = dueCards.length + 1; // +1 approximation
      await _ref
          .read(notificationServiceProvider)
          .scheduleReviewReminder(reminderTime, totalDue);
    } catch (_) {
      // Notifications are best-effort; don't crash if Firebase isn't ready
    }
  }
}

// ── Provider ───────────────────────────────────────────────────────────────

final reviewControllerProvider = StateNotifierProvider.autoDispose<
    ReviewController, ReviewControllerState>(
  (ref) => ReviewController(ref),
);
