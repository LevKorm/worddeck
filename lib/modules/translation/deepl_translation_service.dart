import 'package:supabase_flutter/supabase_flutter.dart';
import '../../contracts/i_translation_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../models/word_input.dart';
import '../../models/translation_result.dart';

/// Calls the `translate` Supabase Edge Function, which proxies DeepL
/// server-side. The DeepL API key never leaves the server.
///
/// Edge function endpoint: POST /functions/v1/translate
/// Input:  { text, source_lang, target_lang }
/// Output: { translation }
class DeepLTranslationService implements ITranslationService {
  final SupabaseClient _supabase;

  const DeepLTranslationService({required SupabaseClient supabase})
      : _supabase = supabase;

  @override
  Future<TranslationResult> translate(WordInput input) async {
    if (input.text.trim().isEmpty) {
      throw const TranslationException('Word is required');
    }

    try {
      final session = _supabase.auth.currentSession;
      final response = await _supabase.functions.invoke(
        'translate',
        body: {
          'text': input.text.trim(),
          'source_lang': input.sourceLang.toUpperCase(),
          'target_lang': input.targetLang.toUpperCase(),
        },
        headers: {
          if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
        },
      );

      final data = response.data as Map<String, dynamic>?;
      final translation = data?['translation'] as String?;

      if (translation == null || translation.isEmpty) {
        final error = data?['error'] as String?;
        throw TranslationException(error ?? 'Empty translation received');
      }

      return TranslationResult(
        original: input.text.trim(),
        translation: translation,
        sourceLang: input.sourceLang,
        targetLang: input.targetLang,
      );
    } on FunctionException catch (e) {
      final details = e.details;
      final msg = details is Map ? details['error']?.toString() : details?.toString();
      final clean = msg ?? 'Translation service unavailable. Please try again.';
      if (clean.contains('quota')) throw const TranslationException('DeepL translation quota exceeded');
      if (clean.contains('API key')) throw const TranslationException('Translation service misconfigured');
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
