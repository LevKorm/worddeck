import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../models/review_rating.dart';
import '../../modules/review/review_provider.dart';
import '../../modules/spaces/space_provider.dart';
import '../../providers/statistics_provider.dart';
import '../../widgets/rating_buttons.dart';
import '../../widgets/review_card.dart';
import '../../widgets/session_complete.dart';
import '../../widgets/synonym_card_sheet.dart';
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
    final ctrlState = ref.watch(reviewControllerProvider);
    final sessionAsync = ref.watch(reviewProvider);
    final sessionStats = ref.watch(sessionStatsProvider);
    final safeTop = MediaQuery.of(context).padding.top;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: sessionAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          ),
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
              return const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              );
            }

            final card = session.currentCard;
            if (card == null) {
              return SessionComplete(cardsReviewed: ctrlState.cardsReviewed);
            }

            final activeSpace = ref.watch(activeSpaceProvider);
            final sourceLang = activeSpace?.nativeLanguage ?? 'EN';
            final targetLang = activeSpace?.learningLanguage ?? 'UK';

            final intervals = ref
                .read(reviewControllerProvider.notifier)
                .getIntervals(card);

            final progress = sessionStats.dailyGoalProgress;
            final remaining = session.cards.length - session.currentIndex;

            return Column(
              children: [
                // ── Top bar: progress + counter ──────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            '$remaining card${remaining == 1 ? '' : 's'} left',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textDim,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${sessionStats.reviewsToday}/${sessionStats.dailyGoal}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                        builder: (context, value, _) => ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: SizedBox(
                            height: 4,
                            child: LinearProgressIndicator(
                              value: value,
                              backgroundColor: AppColors.surface,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.accent),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Card area ────────────────────────────────────────
                Expanded(
                  child: _SwipeArea(
                    key: ValueKey(card.id),
                    isFlipped: ctrlState.isFlipped,
                    onRate: (rating) => ref
                        .read(reviewControllerProvider.notifier)
                        .rateCard(rating),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: ReviewCard(
                        word: card.word,
                        ipa: card.transcription,
                        translation: card.translation ?? '',
                        example: card.exampleSentence,
                        synonyms: card.synonyms,
                        usageNotes: card.usageNotes,
                        exampleNative: card.exampleSentenceNative,
                        synonymsNative: card.synonymsNative,
                        usageNotesNative: card.usageNotesNative,
                        cefrLevel: card.cefrLevel,
                        sourceLang: sourceLang,
                        targetLang: targetLang,
                        isFlipped: ctrlState.isFlipped,
                        onFlip: _flip,
                        onSynonymTap: (s) => showSynonymCardSheet(
                          context,
                          ref,
                          s,
                          sourceLang,
                          targetLang,
                          parentCardId: card.id,
                          parentWord: card.word,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Swipe hints ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        '← Hard',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textDim,
                        ),
                      ),
                      Text(
                        'Easy →',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textDim,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Rating buttons ───────────────────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, safeBottom + 88 + 16),
                  child: RatingButtons(
                    intervals: intervals,
                    onRate: (rating) => ref
                        .read(reviewControllerProvider.notifier)
                        .rateCard(rating),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Tinder-style swipe wrapper ────────────────────────────────────────────────

class _SwipeArea extends StatefulWidget {
  final bool isFlipped;
  final ValueChanged<ReviewRating> onRate;
  final Widget child;

  const _SwipeArea({
    super.key,
    required this.isFlipped,
    required this.onRate,
    required this.child,
  });

  @override
  State<_SwipeArea> createState() => _SwipeAreaState();
}

class _SwipeAreaState extends State<_SwipeArea>
    with SingleTickerProviderStateMixin {
  Offset _offset = Offset.zero;
  late AnimationController _ctrl;
  Animation<Offset>? _anim;

  Offset? _pointerStart;
  int _pointerDownMs = 0;
  bool _tracking = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this);
    _ctrl.addListener(_onTick);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTick() {
    if (mounted && _anim != null) setState(() => _offset = _anim!.value);
  }

  void _onPointerDown(PointerDownEvent e) {
    _ctrl.stop();
    _pointerStart = e.position;
    _pointerDownMs = DateTime.now().millisecondsSinceEpoch;
    _tracking = false;
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (_pointerStart == null) return;
    if (_tracking) {
      setState(() => _offset += Offset(e.delta.dx, 0));
      return;
    }
    final dx = (e.position.dx - _pointerStart!.dx).abs();
    final dy = (e.position.dy - _pointerStart!.dy).abs();
    final elapsed = DateTime.now().millisecondsSinceEpoch - _pointerDownMs;
    if (dx > 8 && dx > dy * 1.5 && elapsed < 350) {
      _tracking = true;
      setState(() => _offset += Offset(e.delta.dx, 0));
    }
  }

  void _onPointerUp(PointerUpEvent e) {
    final start = _pointerStart;
    final downMs = _pointerDownMs;
    _pointerStart = null;
    if (!_tracking || start == null) {
      if (_offset != Offset.zero) _snapBack();
      return;
    }
    _tracking = false;
    final elapsed = DateTime.now().millisecondsSinceEpoch - downMs;
    final dx = e.position.dx - start.dx;
    final velocity = elapsed > 0 ? dx / elapsed * 1000 : 0.0;
    final width = MediaQuery.of(context).size.width;
    if (velocity.abs() > 300 || _offset.dx.abs() > width * 0.35) {
      final goRight = velocity != 0 ? velocity > 0 : _offset.dx > 0;
      _flyAway(goRight ? ReviewRating.easy : ReviewRating.hard);
    } else {
      _snapBack();
    }
  }

  void _onPointerCancel(PointerCancelEvent e) {
    _pointerStart = null;
    _tracking = false;
    _snapBack();
  }

  void _runTo(Offset target,
      {required Curve curve, required int ms, VoidCallback? onDone}) {
    _anim = Tween<Offset>(begin: _offset, end: target)
        .animate(CurvedAnimation(parent: _ctrl, curve: curve));
    _ctrl.duration = Duration(milliseconds: ms);
    _ctrl.reset();
    _ctrl.forward().then((_) {
      if (onDone != null && mounted) onDone();
    });
  }

  void _flyAway(ReviewRating rating) {
    final width = MediaQuery.of(context).size.width;
    final dir = rating == ReviewRating.easy ? 1.0 : -1.0;
    HapticFeedback.mediumImpact();
    _runTo(
      Offset(dir * width * 1.6, 0),
      curve: Curves.easeIn,
      ms: 300,
      onDone: () => widget.onRate(rating),
    );
  }

  void _snapBack() {
    _runTo(Offset.zero, curve: Curves.elasticOut, ms: 500);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final progress = (_offset.dx / (width * 0.5)).clamp(-1.0, 1.0);
    final overlayOpacity = progress.abs().clamp(0.0, 1.0);
    final isRight = _offset.dx >= 0;

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: Transform.translate(
        offset: _offset,
        child: Transform.rotate(
          angle: progress * 0.12,
          alignment: Alignment.bottomCenter,
          child: Stack(
            children: [
              widget.child,
              if (overlayOpacity > 0.04)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: (isRight
                                  ? AppColors.green
                                  : AppColors.red)
                              .withValues(alpha: overlayOpacity * 0.4),
                        ),
                        child: Center(
                          child: Opacity(
                            opacity: (overlayOpacity * 2).clamp(0.0, 1.0),
                            child: Transform.rotate(
                              angle: -progress * 0.12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: Colors.white, width: 3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isRight ? 'EASY' : 'HARD',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 4,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

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
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.textDim),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
