import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../models/flash_card.dart';
import '../models/word_input.dart';
import '../models/translation_result.dart';
import '../models/enrichment_result.dart';
import '../modules/auth/auth_provider.dart';
import '../modules/cards/card_provider.dart';
import '../modules/collections/collection_provider.dart';
import '../modules/enrichment/enrichment_provider.dart';
import '../modules/feed/feed_provider.dart';
import '../modules/translation/translation_provider.dart';
import '../providers/connectivity_provider.dart';
import 'word_card_detail.dart';

/// Shows a modal bottom sheet to translate, enrich, and save a synonym word
/// as a new card, optionally linked to a parent card.
Future<void> showSynonymCardSheet(
  BuildContext context,
  WidgetRef ref,
  String synonym,
  String sourceLang,
  String targetLang, {
  String? parentCardId,
  String? parentWord,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => SynonymCardSheet(
      word: synonym,
      sourceLang: sourceLang,
      targetLang: targetLang,
      parentCardId: parentCardId,
      parentWord: parentWord,
    ),
  );
}

enum _Status { loading, loaded, error }

class SynonymCardSheet extends ConsumerStatefulWidget {
  final String word;
  final String sourceLang;
  final String targetLang;
  final String? parentCardId;
  final String? parentWord;

  const SynonymCardSheet({
    super.key,
    required this.word,
    required this.sourceLang,
    required this.targetLang,
    this.parentCardId,
    this.parentWord,
  });

  @override
  ConsumerState<SynonymCardSheet> createState() => _SynonymCardSheetState();
}

class _SynonymCardSheetState extends ConsumerState<SynonymCardSheet> {
  _Status _status = _Status.loading;
  String _loadingLabel = 'Translating\u2026';
  String? _errorMsg;
  TranslationResult? _translation;
  EnrichmentResult? _enrichment;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    if (ref.read(isOfflineProvider)) {
      setState(() {
        _status = _Status.error;
        _errorMsg = 'You are offline. Connect to the internet to add a card.';
      });
      return;
    }

    try {
      // Step 1: translate
      final translationService = ref.read(translationServiceProvider);
      final input = WordInput(
        text: widget.word,
        sourceLang: widget.sourceLang,
        targetLang: widget.targetLang,
      );
      _translation = await translationService.translate(input);

      // Step 2: enrich
      if (mounted) setState(() => _loadingLabel = 'Enriching\u2026');
      _enrichment = await ref.read(enrichmentServiceProvider).enrichWithTranslation(
        word: widget.word,
        translation: _translation!.translation,
        sourceLang: widget.sourceLang,
        targetLang: widget.targetLang,
      );

      if (mounted) setState(() => _status = _Status.loaded);
    } catch (_) {
      if (mounted) {
        setState(() {
          _status = _Status.error;
          _errorMsg = 'Failed to load. Please try again.';
        });
      }
    }
  }

  bool get _alreadyInDeck {
    final cards = ref.read(cardListProvider).allCards;
    return cards
        .any((c) => c.word.toLowerCase() == widget.word.toLowerCase());
  }

  Future<void> _save() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final now = DateTime.now();
    final card = FlashCard(
      id: '',
      userId: user.userId,
      word: widget.word,
      translation: _translation?.translation,
      transcription: _enrichment?.transcription,
      exampleSentence: _enrichment?.exampleSentence,
      synonyms: _enrichment?.synonyms,
      usageNotes: _enrichment?.usageNotes,
      exampleSentenceNative: _enrichment?.exampleSentenceNative,
      synonymsNative: _enrichment?.synonymsNative,
      usageNotesNative: _enrichment?.usageNotesNative,
      cefrLevel: _enrichment?.cefrLevel,
      grammar: _enrichment?.grammar,
      synonymsEnriched: _enrichment?.synonymsEnriched,
      exampleSentences: _enrichment?.exampleSentences,
      usageNotesList: _enrichment?.usageNotesList,
      parentCardId: widget.parentCardId,
      parentWord: widget.parentWord,
      collectionId: ref.read(pinnedCollectionProvider)?.id,
      nextReview: now,
      createdAt: now,
    );
    await ref.read(cardListProvider.notifier).saveCard(card);
    if (mounted) setState(() => _saved = true);

    // Fire-and-forget: trigger feed generation for the newly saved synonym card.
    final savedCards = ref.read(cardListProvider).allCards;
    if (savedCards.isNotEmpty && savedCards.first.id.isNotEmpty) {
      ref
          .read(feedRepositoryProvider)
          .triggerFeedGeneration(
            user.userId,
            savedCards.first.id,
            targetLang: user.learningLanguage,
            nativeLang: user.nativeLanguage,
          )
          .then<void>((_) {}, onError: (_) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.95,
      minChildSize: 0.3,
      expand: false,
      builder: (ctx, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          controller: scrollCtrl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textDim.withAlpha(100),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              if (_status == _Status.loading) ...[
                const SizedBox(height: 32),
                Center(
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 12),
                      Text(_loadingLabel,
                          style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ] else if (_status == _Status.error) ...[
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.redDim,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _errorMsg ?? 'Something went wrong.',
                      style: const TextStyle(color: AppColors.red),
                    ),
                  ),
                ),
              ] else ...[
                WordCardDetail(
                  cardContext: WordCardContext.synonymSheet,
                  word: widget.word,
                  translation: _translation?.translation ?? '',
                  ipa: _enrichment?.transcription,
                  cefrLevel: _enrichment?.cefrLevel,
                  parentWord: widget.parentWord,
                  exampleSentence: _enrichment?.exampleSentence,
                  exampleSentences: _enrichment?.exampleSentences,
                  synonyms: _enrichment?.synonyms,
                  synonymsEnriched: _enrichment?.synonymsEnriched,
                  usageNotes: _enrichment?.usageNotes,
                  usageNotesList: _enrichment?.usageNotesList,
                  grammar: _enrichment?.grammar,
                  exampleNative: _enrichment?.exampleSentenceNative,
                  synonymsNative: _enrichment?.synonymsNative,
                  usageNotesNative: _enrichment?.usageNotesNative,
                  sourceLang: widget.sourceLang,
                  targetLang: widget.targetLang,
                  isSaved: _saved,
                  alreadyInDeck: _alreadyInDeck,
                  onSave: _save,
                  onClose: () => Navigator.of(context).pop(),
                ),
              ],

              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        ),
      ),
    );
  }
}
