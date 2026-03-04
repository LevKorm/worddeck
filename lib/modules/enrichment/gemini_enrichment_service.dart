import 'package:supabase_flutter/supabase_flutter.dart';
import '../../contracts/i_enrichment_service.dart';
import '../../core/errors/app_exception.dart';
import '../../models/enrichment_result.dart';

/// Calls the `enrich` Supabase Edge Function, which proxies Gemini
/// server-side. The Gemini API key never leaves the server.
///
/// Edge function endpoint: POST /functions/v1/enrich
/// Input:  { word, language, translation?, target_lang? }
/// Output: EnrichmentResult JSON
class GeminiEnrichmentService implements IEnrichmentService {
  final SupabaseClient _supabase;

  const GeminiEnrichmentService({required SupabaseClient supabase})
      : _supabase = supabase;

  @override
  Future<EnrichmentResult> enrich(String word, String language) =>
      _callEnrich(word: word, language: language);

  /// Extended version used by TranslatePipelineNotifier — passes translation
  /// context for a better prompt (matches the original Next.js behavior).
  Future<EnrichmentResult> enrichWithTranslation({
    required String word,
    required String translation,
    required String sourceLang,
    required String targetLang,
  }) =>
      _callEnrich(
        word: word,
        language: sourceLang,
        translation: translation,
        targetLang: targetLang,
      );

  Future<EnrichmentResult> _callEnrich({
    required String word,
    required String language,
    String? translation,
    String? targetLang,
  }) async {
    try {
      final body = <String, dynamic>{
        'word': word,
        'language': language,
        if (translation != null) 'translation': translation,
        if (targetLang != null) 'target_lang': targetLang,
      };

      final response = await _supabase.functions.invoke('enrich', body: body);

      final data = response.data;
      if (data == null) {
        throw const EnrichmentException('Empty response from enrichment service');
      }

      if (data is Map && data.containsKey('error')) {
        throw EnrichmentException(data['error']?.toString() ?? 'Enrichment failed');
      }

      return EnrichmentResult.fromJson(data as Map<String, dynamic>);
    } on FunctionException catch (e) {
      final details = e.details;
      final msg = details is Map ? details['error']?.toString() : details?.toString();
      final clean = msg ?? 'Enrichment service unavailable. Please try again.';
      if (clean.contains('quota')) throw const EnrichmentException('Gemini quota exceeded');
      throw EnrichmentException(clean);
    } catch (e) {
      if (e is EnrichmentException) rethrow;
      throw EnrichmentException(
        'Enrichment service unavailable. Please try again.',
        cause: e,
      );
    }
  }
}
