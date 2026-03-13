import '../models/enrichment_result.dart';

abstract class IEnrichmentService {
  Future<EnrichmentResult> enrich(String word, String language);

  /// Extended enrichment that includes translation context for a richer prompt.
  Future<EnrichmentResult> enrichWithTranslation({
    required String word,
    required String translation,
    required String sourceLang,
    required String targetLang,
  });
}
