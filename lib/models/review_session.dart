import 'flash_card.dart';

/// Immutable snapshot of an active review session.
@immutable
class ReviewSession {
  final List<FlashCard> cards;
  final int currentIndex;
  final int correctCount;    // cards rated Hard / Good / Easy

  const ReviewSession({
    required this.cards,
    this.currentIndex = 0,
    this.correctCount = 0,
  });

  bool get isComplete => cards.isEmpty || currentIndex >= cards.length;
  int  get totalCount  => cards.length;
  int  get reviewedCount => currentIndex;

  FlashCard? get currentCard =>
      isComplete ? null : cards[currentIndex];

  ReviewSession advance({required bool wasCorrect}) => ReviewSession(
        cards: cards,
        currentIndex: currentIndex + 1,
        correctCount: correctCount + (wasCorrect ? 1 : 0),
      );

  ReviewSession copyWith({List<FlashCard>? cards, int? currentIndex, int? correctCount}) =>
      ReviewSession(
        cards: cards ?? this.cards,
        currentIndex: currentIndex ?? this.currentIndex,
        correctCount: correctCount ?? this.correctCount,
      );
}

class _Immutable {
  const _Immutable();
}
const immutable = _Immutable();
