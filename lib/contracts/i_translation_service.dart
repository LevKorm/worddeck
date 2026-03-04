import '../models/word_input.dart';
import '../models/translation_result.dart';

abstract class ITranslationService {
  Future<TranslationResult> translate(WordInput input);
  Future<List<String>> getSupportedLanguages();
}
