import 'package:flutter/material.dart';
import '../models/enrichment_result.dart';
import '../models/translation_result.dart';
import 'translation_card.dart';

/// Thin adapter: extracts data from [TranslationResult] + [EnrichmentResult?]
/// and renders [TranslationCard].
class EnrichmentResultCard extends StatelessWidget {
  final TranslationResult translation;
  final EnrichmentResult? enrichment;
  final bool isSaved;
  final VoidCallback onSave;
  final VoidCallback? onSkip;
  final VoidCallback? onCopy;

  const EnrichmentResultCard({
    super.key,
    required this.translation,
    this.enrichment,
    required this.isSaved,
    required this.onSave,
    this.onSkip,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return TranslationCard(
      word: translation.original,
      translation: translation.translation,
      ipa: enrichment?.transcription,
      example: enrichment?.exampleSentence,
      synonyms: enrichment?.synonyms,
      usageNotes: enrichment?.usageNotes,
      didYouMean: enrichment?.didYouMean,
      onSave: onSave,
      onSkip: onSkip,
      onCopy: onCopy,
      isSaved: isSaved,
    );
  }
}
