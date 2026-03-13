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

  factory TranslationResult.fromJson(Map<String, dynamic> json) =>
      TranslationResult(
        original:    json['original']    as String,
        translation: json['translation'] as String,
        sourceLang:  json['source_lang'] as String,
        targetLang:  json['target_lang'] as String,
      );

  Map<String, dynamic> toJson() => {
        'original':    original,
        'translation': translation,
        'source_lang': sourceLang,
        'target_lang': targetLang,
      };
}
