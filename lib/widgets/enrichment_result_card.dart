import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/enrichment_result.dart';
import '../models/translation_result.dart';
import 'word_card_detail.dart';

/// Thin adapter: extracts data from [TranslationResult] + [EnrichmentResult?]
/// and renders [WordCardDetail] in translate-result context.
class EnrichmentResultCard extends ConsumerWidget {
  final TranslationResult translation;
  final EnrichmentResult? enrichment;
  final bool isEnriching;
  final bool isSaved;
  final bool alreadyInDeck;
  final VoidCallback onSave;
  final VoidCallback? onSkip;
  final VoidCallback? onCopy;
  final void Function(String corrected)? onDidYouMeanTap;
  final bool showLangToggle;
  final bool? showNative;
  final ValueChanged<bool>? onNativeChanged;
  final String? collectionId;
  final ValueChanged<String?>? onCollectionChanged;

  const EnrichmentResultCard({
    super.key,
    required this.translation,
    this.enrichment,
    this.isEnriching = false,
    required this.isSaved,
    this.alreadyInDeck = false,
    required this.onSave,
    this.onSkip,
    this.onCopy,
    this.onDidYouMeanTap,
    this.showLangToggle = true,
    this.showNative,
    this.onNativeChanged,
    this.collectionId,
    this.onCollectionChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return WordCardDetail(
      cardContext: alreadyInDeck
          ? WordCardContext.inDeck
          : WordCardContext.translateResult,
      word: translation.original,
      translation: translation.translation,
      ipa: enrichment?.transcription,
      cefrLevel: enrichment?.cefrLevel,
      exampleSentence: enrichment?.exampleSentence,
      exampleSentences: enrichment?.exampleSentences,
      synonyms: enrichment?.synonyms,
      synonymsEnriched: enrichment?.synonymsEnriched,
      usageNotes: enrichment?.usageNotes,
      usageNotesList: enrichment?.usageNotesList,
      grammar: enrichment?.grammar,
      didYouMean: enrichment?.didYouMean,
      exampleNative: enrichment?.exampleSentenceNative,
      synonymsNative: enrichment?.synonymsNative,
      usageNotesNative: enrichment?.usageNotesNative,
      sourceLang: translation.sourceLang,
      targetLang: translation.targetLang,
      isEnriching: isEnriching,
      isSaved: isSaved,
      alreadyInDeck: alreadyInDeck,
      onSave: onSave,
      onSkip: onSkip,
      onDidYouMeanTap: onDidYouMeanTap,
      showNative: showNative,
      onNativeChanged: onNativeChanged,
      collectionId: collectionId,
      onCollectionChanged: onCollectionChanged,
    );
  }
}
