/// Result of a Gemini enrichment call.
/// All fields nullable — Gemini may omit any of them.
///
/// Gemini prompt fields (from Next.js app/api/enrich/route.ts):
///   transcription    → IPA phonetic transcription
///   example_sentence → natural example using the word
///   synonyms         → 3–5 synonyms in the source language
///   usage_notes      → 1–2 sentence usage note (register, collocations)
///   did_you_mean     → spelling correction suggestion, or null
class EnrichmentResult {
  final String? transcription;
  final String? exampleSentence;
  final List<String>? synonyms;
  final String? usageNotes;
  final String? didYouMean;

  const EnrichmentResult({
    this.transcription,
    this.exampleSentence,
    this.synonyms,
    this.usageNotes,
    this.didYouMean,
  });

  factory EnrichmentResult.fromJson(Map<String, dynamic> json) =>
      EnrichmentResult(
        transcription:   json['transcription'] as String?,
        exampleSentence: json['example_sentence'] as String?,
        synonyms:        (json['synonyms'] as List<dynamic>?)?.cast<String>(),
        usageNotes:      json['usage_notes'] as String?,
        didYouMean:      json['did_you_mean'] as String?,
      );
}
