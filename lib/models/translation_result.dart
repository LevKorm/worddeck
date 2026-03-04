class TranslationResult {
  final String original;
  final String translation;
  final String sourceLang;
  final String targetLang;

  const TranslationResult({
    required this.original,
    required this.translation,
    required this.sourceLang,
    required this.targetLang,
  });
}
