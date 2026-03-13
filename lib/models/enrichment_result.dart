/// Result of a Gemini enrichment call.
/// All fields nullable — Gemini may omit any of them.
///
/// Gemini prompt fields:
///   transcription            → IPA phonetic transcription
///   example_sentence         → natural example using the word
///   synonyms                 → 3–5 synonyms in the source language
///   usage_notes              → 1–2 sentence usage note (register, collocations)
///   did_you_mean             → spelling correction suggestion, or null
///   cefr_level               → estimated CEFR level (A1/A2/B1/B2/C1/C2)
///   example_sentence_native  → example_sentence translated to target lang
///   synonyms_native          → synonyms/equivalents in target lang
///   usage_notes_native       → usage_notes translated to target lang
class EnrichmentResult {
  final String? transcription;
  final String? exampleSentence;
  final List<String>? synonyms;
  final String? usageNotes;
  final String? didYouMean;
  final String? cefrLevel;
  final String? exampleSentenceNative;
  final List<String>? synonymsNative;
  final String? usageNotesNative;
  /// Structured grammar info: {type, pattern, related}.
  final Map<String, dynamic>? grammar;
  /// Synonyms with CEFR levels: [{word, level}].
  final List<Map<String, String>>? synonymsEnriched;
  /// Multiple example sentences.
  final List<String>? exampleSentences;
  /// Multiple usage notes.
  final List<String>? usageNotesList;

  const EnrichmentResult({
    this.transcription,
    this.exampleSentence,
    this.synonyms,
    this.usageNotes,
    this.didYouMean,
    this.cefrLevel,
    this.exampleSentenceNative,
    this.synonymsNative,
    this.usageNotesNative,
    this.grammar,
    this.synonymsEnriched,
    this.exampleSentences,
    this.usageNotesList,
  });

  Map<String, dynamic> toJson() => {
        'transcription':           transcription,
        'example_sentence':        exampleSentence,
        'synonyms':                synonyms,
        'usage_notes':             usageNotes,
        'did_you_mean':            didYouMean,
        'cefr_level':              cefrLevel,
        'example_sentence_native': exampleSentenceNative,
        'synonyms_native':         synonymsNative,
        'usage_notes_native':      usageNotesNative,
        'grammar':                 grammar,
        'synonyms_enriched':       synonymsEnriched,
        'example_sentences':       exampleSentences,
        'usage_notes_list':        usageNotesList,
      };

  factory EnrichmentResult.fromJson(Map<String, dynamic> json) =>
      EnrichmentResult(
        transcription:          json['transcription'] as String?,
        exampleSentence:        json['example_sentence'] as String?,
        synonyms:               (json['synonyms'] as List<dynamic>?)?.cast<String>(),
        usageNotes:             json['usage_notes'] as String?,
        didYouMean:             json['did_you_mean'] as String?,
        cefrLevel:              json['cefr_level'] as String?,
        exampleSentenceNative:  json['example_sentence_native'] as String?,
        synonymsNative:         (json['synonyms_native'] as List<dynamic>?)?.cast<String>(),
        usageNotesNative:       json['usage_notes_native'] as String?,
        grammar:                json['grammar'] != null
            ? Map<String, dynamic>.from(json['grammar'] as Map)
            : null,
        synonymsEnriched:       (json['synonyms_enriched'] as List<dynamic>?)
            ?.map((e) => Map<String, String>.from(e as Map))
            .toList(),
        exampleSentences:       (json['example_sentences'] as List<dynamic>?)?.cast<String>(),
        usageNotesList:         (json['usage_notes_list'] as List<dynamic>?)?.cast<String>(),
      );
}
