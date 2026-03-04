class WordInput {
  final String text;
  final String sourceLang;  // uppercase DeepL code, e.g. 'UK'
  final String targetLang;  // uppercase DeepL code, e.g. 'EN'

  const WordInput({
    required this.text,
    required this.sourceLang,
    required this.targetLang,
  });

  WordInput copyWith({String? text, String? sourceLang, String? targetLang}) =>
      WordInput(
        text: text ?? this.text,
        sourceLang: sourceLang ?? this.sourceLang,
        targetLang: targetLang ?? this.targetLang,
      );
}
