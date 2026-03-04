import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../contracts/i_review_engine.dart';
import '../../models/flash_card.dart';
import '../../models/review_rating.dart';
import '../../models/review_session.dart';
import '../../models/sm2_data.dart';
import '../cards/card_provider.dart';
import 'sm2_engine.dart';

// ── Engine provider ───────────────────────────────────────────────────────────

final reviewEngineProvider = Provider<IReviewEngine>((ref) => const SM2Engine());

// ── Review session notifier ───────────────────────────────────────────────────

class ReviewNotifier extends StateNotifier<AsyncValue<ReviewSession>> {
  final IReviewEngine _engine;
  final Ref _ref;

  ReviewNotifier(this._engine, this._ref)
      : super(const AsyncValue.data(ReviewSession(cards: [])));

  /// Load due cards for [userId] and start a new session.
  Future<void> loadSession(String userId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = _ref.read(cardRepositoryProvider);
      final dueCards = await repo.getDueCards(userId, DateTime.now());
      return ReviewSession(cards: dueCards);
    });
  }

  /// Process [rating] for the current card:
  ///   1. Apply SM-2 via engine
  ///   2. Persist updated card to Supabase
  ///   3. Advance session index
  Future<void> rate(ReviewRating rating) async {
    final session = state.valueOrNull;
    if (session == null || session.isComplete) return;

    final card = session.currentCard!;

    // Apply SM-2
    final currentSM2 = SM2Data(
      repetitions: card.repetitions,
      intervalDays: card.intervalDays,
      easeFactor: card.easeFactor,
      nextReview: card.nextReview,
    );
    final newSM2 = _engine.calculateNext(currentSM2, rating);

    // Determine new status
    final newStatus = _resolveStatus(card.status, newSM2, rating);

    final updatedCard = card.copyWith(
      repetitions: newSM2.repetitions,
      intervalDays: newSM2.intervalDays,
      easeFactor: newSM2.easeFactor,
      nextReview: newSM2.nextReview,
      status: newStatus,
    );

    // Persist (fire-and-forget is ok; card list will reload)
    final repo = _ref.read(cardRepositoryProvider);
    await repo.updateCard(updatedCard);

    // Also update card list cache
    _ref.read(cardListProvider.notifier).updateCard(updatedCard);

    // Advance session
    final wasCorrect = rating.quality >= 3;
    state = AsyncValue.data(session.advance(wasCorrect: wasCorrect));
  }

  /// Restart the session with the same user.
  Future<void> restart(String userId) => loadSession(userId);

  CardStatus _resolveStatus(
    CardStatus current,
    SM2Data newSM2,
    ReviewRating rating,
  ) {
    if (rating == ReviewRating.again) return CardStatus.learning;
    if (newSM2.intervalDays >= 21)    return CardStatus.mastered;
    return CardStatus.learning;
  }
}

final reviewProvider =
    StateNotifierProvider.autoDispose<ReviewNotifier, AsyncValue<ReviewSession>>(
  (ref) => ReviewNotifier(ref.read(reviewEngineProvider), ref),
);

// ── Preview interval helper ───────────────────────────────────────────────────

/// Returns a human-readable interval preview string for each rating button,
/// given the current card's SM2 data. Used by ReviewScreen button labels.
final reviewIntervalPreviewProvider =
    Provider.autoDispose.family<Map<ReviewRating, String>, FlashCard>(
  (ref, card) {
    final engine = ref.read(reviewEngineProvider) as SM2Engine;
    final sm2 = SM2Data(
      repetitions: card.repetitions,
      intervalDays: card.intervalDays,
      easeFactor: card.easeFactor,
      nextReview: card.nextReview,
    );
    return {
      for (final r in ReviewRating.values) r: engine.previewInterval(sm2, r),
    };
  },
);
