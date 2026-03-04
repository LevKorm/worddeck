import '../models/enrichment_result.dart';

abstract class IEnrichmentService {
  Future<EnrichmentResult> enrich(String word, String language);
}
