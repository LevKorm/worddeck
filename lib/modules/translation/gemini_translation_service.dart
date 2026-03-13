import 'package:supabase_flutter/supabase_flutter.dart';
import '../../contracts/i_translation_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../models/word_input.dart';
import '../../models/translation_result.dart';

/// Calls the `translate-gemini` Supabase Edge Function, which proxies
/// Gemini Flash 2.5 server-side. The Gemini API key never leaves the server.
///
/// Edge function endpoint: POST /functions/v1/translate-gemini
/// Input:  { text, source_lang, target_lang }
/// Output: { translation }
class GeminiTranslationService implements ITranslationService {
  final SupabaseClient _supabase;

  const GeminiTranslationService({required SupabaseClient supabase})
      : _supabase = supabase;

  @override
  Future<TranslationResult> translate(WordInput input) async {
    if (input.text.trim().isEmpty) {
      throw const TranslationException('Word is required');
    }

    try {
      final session = _supabase.auth.currentSession;
      final response = await _supabase.functions.invoke(
        'translate-gemini',
        body: {
          'text':        input.text.trim(),
          'source_lang': input.sourceLang.toUpperCase(),
          'target_lang': input.targetLang.toUpperCase(),
        },
        headers: {
          if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
        },
      );

      final raw = response.data;
      if (raw == null) {
        throw const TranslationException('Empty response from translation service');
      }

      final data = raw is Map ? raw as Map<String, dynamic> : null;

      if (data != null && data.containsKey('error')) {
        throw TranslationException(
          data['error']?.toString() ?? 'Translation failed',
        );
      }

      final translation = data?['translation'] as String?;

      if (translation == null || translation.isEmpty) {
        // Surface the raw response for debugging if it's not a proper map
        final hint = data == null ? ' (raw: $raw)' : '';
        throw TranslationException('Empty translation received$hint');
      }

      return TranslationResult(
        original:    input.text.trim(),
        translation: translation,
        sourceLang:  input.sourceLang,
        targetLang:  input.targetLang,
      );
    } on FunctionException catch (e) {
      final details = e.details;
      final msg = details is Map
          ? details['error']?.toString()
          : details?.toString();
      final clean = msg ?? 'Translation service unavailable. Please try again.';
      if (clean.contains('quota')) {
        throw const TranslationException('Gemini translation quota exceeded');
      }
      throw TranslationException(clean);
    } catch (e) {
      if (e is TranslationException) rethrow;
      throw TranslationException(
        'Translation service unavailable. Please try again.',
        cause: e,
      );
    }
  }

  @override
  Future<List<String>> getSupportedLanguages() async =>
      AppConstants.supportedLanguageCodes;
}
