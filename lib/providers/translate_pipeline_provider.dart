import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/errors/failure.dart';
import '../models/enrichment_result.dart';
import '../models/flash_card.dart';
import '../models/translation_result.dart';
import '../models/word_input.dart';
import '../modules/auth/auth_provider.dart';
import '../modules/cards/card_provider.dart';
import '../modules/enrichment/enrichment_provider.dart';
import '../modules/feed/feed_provider.dart';
import '../modules/spaces/space_provider.dart';
import '../modules/translation/translation_provider.dart';

/// Combined state for the Translate screen.
/// Holds both translation + enrichment results and the save state.
class TranslatePipelineState {
  final bool isTranslating;
  final bool isEnriching;
  final TranslationResult? translation;
  final EnrichmentResult? enrichment;
  final Failure? failure;
  final bool isSaved;
  final WordInput? lastInput;

  const TranslatePipelineState({
    this.isTranslating  = false,
    this.isEnriching    = false,
    this.translation,
    this.enrichment,
    this.failure,
    this.isSaved        = false,
    this.lastInput,
  });

  bool get isLoading => isTranslating || isEnriching;
  bool get hasResult => translation != null;

  TranslatePipelineState copyWith({
    bool? isTranslating,
    bool? isEnriching,
    TranslationResult? translation,
    EnrichmentResult? enrichment,
    Failure? failure,
    bool? clearFailure,
    bool? isSaved,
    WordInput? lastInput,
  }) =>
      TranslatePipelineState(
        isTranslating: isTranslating ?? this.isTranslating,
        isEnriching:   isEnriching   ?? this.isEnriching,
        translation:   translation   ?? this.translation,
        enrichment:    enrichment    ?? this.enrichment,
        failure:       clearFailure == true ? null : failure ?? this.failure,
        isSaved:       isSaved      ?? this.isSaved,
        lastInput:     lastInput    ?? this.lastInput,
      );
}

/// Orchestrates the full translate → enrich pipeline.
///
/// This is the ONLY place where TranslationService and EnrichmentService
/// interact. Neither module is aware of the other.
///
/// Pipeline:
///   1. translate(WordInput) via ITranslationService (DeepL)
///   2. enrich concurrently using translation context (Gemini)
///   3. Combine into TranslatePipelineState
///   4. saveCard() → ICardRepository.saveCard()
class TranslatePipelineNotifier extends StateNotifier<TranslatePipelineState> {
  final Ref _ref;

  TranslatePipelineNotifier(this._ref)
      : super(const TranslatePipelineState());

  Future<void> translate(WordInput input) async {
    state = TranslatePipelineState(
      isTranslating: true,
      lastInput: input,
    );

    // ── Step 1: Translation ────────────────────────────────────────────────
    final TranslationResult translationResult;
    try {
      translationResult = await _ref
          .read(translationServiceProvider)
          .translate(input);
    } catch (e) {
      state = TranslatePipelineState(
        failure: _toFailure(e),
        lastInput: input,
      );
      return;
    }

    // ── Step 1b: Normalize direction ────────────────────────────────────────
    // Convention: `word` = learning language, `translation` = native language.
    // If the user typed in their native language, the translation API returns
    // original=native, translation=learning. We swap so that `word` is always
    // the learning-language word.
    final activeSpace = _ref.read(activeSpaceProvider);
    final learningLang = activeSpace?.learningLanguage;

    final bool needsSwap = learningLang != null &&
        translationResult.sourceLang.toUpperCase() != learningLang.toUpperCase() &&
        translationResult.targetLang.toUpperCase() == learningLang.toUpperCase();

    final TranslationResult normalized;
    if (needsSwap) {
      // Swap: learning-language word becomes `original`, native becomes `translation`
      normalized = TranslationResult(
        original:    translationResult.translation,
        translation: translationResult.original,
        sourceLang:  translationResult.targetLang,  // now learning lang
        targetLang:  translationResult.sourceLang,  // now native lang
      );
    } else {
      normalized = translationResult;
    }

    // Update state with translation while enrichment loads
    state = state.copyWith(
      isTranslating: false,
      isEnriching: true,
      translation: normalized,
    );

    // ── Step 2: Enrichment — always about the learning-language word ────────
    // After normalization, `normalized.original` is the learning-language word
    // and `normalized.sourceLang` is the learning language code.
    EnrichmentResult? enrichmentResult;
    try {
      enrichmentResult = await _ref.read(enrichmentServiceProvider).enrichWithTranslation(
        word:       normalized.original,
        translation:normalized.translation,
        sourceLang: normalized.sourceLang,
        targetLang: normalized.targetLang,
      );
    } catch (_) {
      // Enrichment failure is non-fatal — translation result is still useful
      enrichmentResult = null;
    }

    state = state.copyWith(
      isEnriching: false,
      enrichment: enrichmentResult,
    );
  }

  /// Save the current result as a FlashCard for [userId].
  /// Pass [collectionId] to assign the card to a collection on save.
  /// Pass [spaceId] to scope the card to a language space.
  Future<void> saveCard(String userId, {String? collectionId, String? spaceId}) async {
    final t = state.translation;
    final e = state.enrichment;
    if (t == null) return;

    try {
      final card = FlashCard(
        id:                     '',       // generated by Supabase
        userId:                 userId,
        word:                   t.original,
        translation:            t.translation,
        transcription:          e?.transcription,
        exampleSentence:        e?.exampleSentence,
        synonyms:               e?.synonyms,
        usageNotes:             e?.usageNotes,
        exampleSentenceNative:  e?.exampleSentenceNative,
        synonymsNative:         e?.synonymsNative,
        usageNotesNative:       e?.usageNotesNative,
        collectionId:           collectionId,
        spaceId:                spaceId,
        cefrLevel:              e?.cefrLevel,
        grammar:                e?.grammar,
        synonymsEnriched:       e?.synonymsEnriched,
        exampleSentences:       e?.exampleSentences,
        usageNotesList:         e?.usageNotesList,
        wordLang:               t.sourceLang,
        translationLang:        t.targetLang,
        status:                 CardStatus.learning,
        nextReview:             DateTime.now(),
        createdAt:              DateTime.now(),
      );
      await _ref.read(cardListProvider.notifier).saveCard(card);
      state = state.copyWith(isSaved: true);

      // Fire-and-forget: trigger feed generation for the newly saved card.
      // The saved card was prepended to allCards by CardListNotifier.
      final savedCards = _ref.read(cardListProvider).allCards;
      if (savedCards.isNotEmpty && savedCards.first.id.isNotEmpty) {
        final user = _ref.read(currentUserProvider);
        _ref
            .read(feedRepositoryProvider)
            .triggerFeedGeneration(
              userId,
              savedCards.first.id,
              targetLang: user?.learningLanguage,
              nativeLang: user?.nativeLanguage,
              spaceId: spaceId,
            )
            .then<void>((_) {}, onError: (_) {});
      }
    } catch (e) {
      state = state.copyWith(failure: DatabaseFailure(e.toString()));
    }
  }

  /// Instantly restore a cached result — no network calls.
  void restoreFromCache(
      TranslationResult translation, EnrichmentResult? enrichment, bool isSaved) {
    state = TranslatePipelineState(
      translation: translation,
      enrichment:  enrichment,
      isSaved:     isSaved,
      lastInput: WordInput(
        text:       translation.original,
        sourceLang: translation.sourceLang,
        targetLang: translation.targetLang,
      ),
    );
  }

  void reset() => state = const TranslatePipelineState();

  Failure _toFailure(Object e) {
    final msg = e.toString();
    if (msg.contains('quota'))   return const TranslationFailure('Translation quota exceeded');
    if (msg.contains('API key') || msg.contains('Gemini API')) {
      return const TranslationFailure('Translation service misconfigured');
    }
    if (msg.contains('internet') || msg.contains('connection')) {
      return const NetworkFailure();
    }
    return TranslationFailure(msg);
  }
}

final translatePipelineProvider = StateNotifierProvider.autoDispose<
    TranslatePipelineNotifier, TranslatePipelineState>(
  (ref) => TranslatePipelineNotifier(ref),
);
