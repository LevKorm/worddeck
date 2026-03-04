import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../modules/review/review_provider.dart';
import '../../widgets/rating_buttons.dart';
import '../../widgets/review_card.dart';
import '../../widgets/session_complete.dart';
import 'review_controller.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reviewControllerProvider.notifier).loadDueCards();
    });
  }

  void _flip() {
    HapticFeedback.mediumImpact();
    ref.read(reviewControllerProvider.notifier).flipCard();
  }

  @override
  Widget build(BuildContext context) {
    final ctrlState    = ref.watch(reviewControllerProvider);
    final sessionAsync = ref.watch(reviewProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review'),
        actions: [
          if (ctrlState.cardsReviewed > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${ctrlState.cardsReviewed} done',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),
        ],
      ),
      body: sessionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () {
            ref.read(reviewControllerProvider.notifier).loadDueCards();
          },
        ),
        data: (session) {
          if (session.isComplete) {
            return SessionComplete(cardsReviewed: ctrlState.cardsReviewed);
          }

          if (ctrlState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final card = session.currentCard;
          if (card == null) {
            return SessionComplete(cardsReviewed: ctrlState.cardsReviewed);
          }

          final intervals = ref
              .read(reviewControllerProvider.notifier)
              .getIntervals(card);

          final progress = session.cards.isEmpty
              ? 0.0
              : (session.currentIndex / session.cards.length).clamp(0.0, 1.0);

          return Column(
            children: [
              // Animated progress bar
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: progress),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ReviewCard(
                    word: card.word,
                    ipa: card.transcription,
                    translation: card.translation ?? '',
                    example: card.exampleSentence,
                    synonyms: card.synonyms,
                    usageNotes: card.usageNotes,
                    isFlipped: ctrlState.isFlipped,
                    onFlip: _flip,
                  ),
                ),
              ),

              if (ctrlState.isFlipped)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: RatingButtons(
                    intervals: intervals,
                    onRate: (rating) => ref
                        .read(reviewControllerProvider.notifier)
                        .rateCard(rating),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: FilledButton(
                    onPressed: _flip,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: const Text('Show Answer'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton(onPressed: onRetry, child: const Text('Try Again')),
          ],
        ),
      ),
    );
  }
}
