import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../contracts/i_enrichment_service.dart';
import '../../models/enrichment_result.dart';
import '../../modules/auth/auth_provider.dart';
import 'gemini_enrichment_service.dart';

final enrichmentServiceProvider = Provider<IEnrichmentService>((ref) {
  return GeminiEnrichmentService(
    supabase: ref.read(supabaseClientProvider),
  );
});

// ── Enrichment state ──────────────────────────────────────────────────────────

class EnrichmentNotifier
    extends StateNotifier<AsyncValue<EnrichmentResult?>> {
  final IEnrichmentService _service;

  EnrichmentNotifier(this._service) : super(const AsyncValue.data(null));

  Future<void> enrich(String word, String language) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _service.enrich(word, language));
  }

  void clear() => state = const AsyncValue.data(null);
}

final enrichmentProvider = StateNotifierProvider.autoDispose<
    EnrichmentNotifier, AsyncValue<EnrichmentResult?>>(
  (ref) => EnrichmentNotifier(ref.read(enrichmentServiceProvider)),
);
