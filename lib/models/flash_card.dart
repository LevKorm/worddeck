/// FlashCard — mirrors the Supabase `cards` table exactly.
///
/// Schema (from supabase/migrations/001_initial_schema.sql):
///   id                       uuid PK default gen_random_uuid()
///   user_id                  uuid FK auth.users ON DELETE CASCADE
///   word                     text NOT NULL
///   translation              text
///   transcription            text
///   example_sentence         text
///   synonyms                 text[]
///   usage_notes              text
///   example_sentence_native  text
///   synonyms_native          text[]
///   usage_notes_native       text
///   status                   text CHECK IN ('pending','learning','mastered') DEFAULT 'pending'
///   ease_factor              float DEFAULT 2.5
///   interval_days            int   DEFAULT 0
///   repetitions              int   DEFAULT 0
///   next_review              timestamptz DEFAULT now()
///   created_at               timestamptz DEFAULT now()
///   parent_card_id           uuid FK cards(id) ON DELETE SET NULL  (nullable)
///   parent_word              text  (nullable — the word of the parent card)
///   word_lang                text  (nullable — lang code for `word`, e.g. 'EN')
///   translation_lang         text  (nullable — lang code for `translation`, e.g. 'UK')
///
/// Language convention:
///   `word` is ALWAYS in the learning language (the language the user is studying).
///   `translation` is ALWAYS in the native language (the language the user already knows).
///   Enrichment fields (example_sentence, synonyms, usage_notes, transcription) are
///   about the learning-language `word`. The `_native` variants are in the native language.
class FlashCard {
  final String id;
  final String userId;
  final String word;
  final String? translation;
  final String? transcription;
  final String? exampleSentence;
  final List<String>? synonyms;
  final String? usageNotes;
  final String? exampleSentenceNative;
  final List<String>? synonymsNative;
  final String? usageNotesNative;
  final String? parentCardId;
  final String? parentWord;
  final String? collectionId;
  final String? spaceId;
  final String? cefrLevel;
  /// Structured grammar info from Gemini: {type, pattern, related}.
  final Map<String, dynamic>? grammar;
  /// Synonyms with CEFR levels: [{word, level}].
  final List<Map<String, String>>? synonymsEnriched;
  /// Multiple example sentences (array).
  final List<String>? exampleSentences;
  /// Multiple usage notes (array).
  final List<String>? usageNotesList;
  /// Language code for `word` (learning language), e.g. 'EN'.
  final String? wordLang;
  /// Language code for `translation` (native language), e.g. 'UK'.
  final String? translationLang;
  final CardStatus status;
  // SM-2 fields (stored flat in the table, not as a nested object)
  final double easeFactor;
  final int intervalDays;
  final int repetitions;
  final DateTime nextReview;
  final DateTime createdAt;

  const FlashCard({
    required this.id,
    required this.userId,
    required this.word,
    this.translation,
    this.transcription,
    this.exampleSentence,
    this.synonyms,
    this.usageNotes,
    this.exampleSentenceNative,
    this.synonymsNative,
    this.usageNotesNative,
    this.parentCardId,
    this.parentWord,
    this.collectionId,
    this.spaceId,
    this.cefrLevel,
    this.grammar,
    this.synonymsEnriched,
    this.exampleSentences,
    this.usageNotesList,
    this.wordLang,
    this.translationLang,
    this.status = CardStatus.pending,
    this.easeFactor = 2.5,
    this.intervalDays = 0,
    this.repetitions = 0,
    required this.nextReview,
    required this.createdAt,
  });

  /// Convenience accessor — extracts SM-2 state as [SM2Data].
  // (imported lazily to avoid circular dep; callers can reconstruct)

  bool get isDue =>
      nextReview.isBefore(DateTime.now()) && status != CardStatus.mastered;

  FlashCard copyWith({
    String? id,
    String? userId,
    String? word,
    String? translation,
    String? transcription,
    String? exampleSentence,
    List<String>? synonyms,
    String? usageNotes,
    String? exampleSentenceNative,
    List<String>? synonymsNative,
    String? usageNotesNative,
    String? parentCardId,
    String? parentWord,
    String? collectionId,
    bool clearCollectionId = false,
    String? spaceId,
    String? cefrLevel,
    Map<String, dynamic>? grammar,
    List<Map<String, String>>? synonymsEnriched,
    List<String>? exampleSentences,
    List<String>? usageNotesList,
    String? wordLang,
    String? translationLang,
    CardStatus? status,
    double? easeFactor,
    int? intervalDays,
    int? repetitions,
    DateTime? nextReview,
    DateTime? createdAt,
  }) =>
      FlashCard(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        word: word ?? this.word,
        translation: translation ?? this.translation,
        transcription: transcription ?? this.transcription,
        exampleSentence: exampleSentence ?? this.exampleSentence,
        synonyms: synonyms ?? this.synonyms,
        usageNotes: usageNotes ?? this.usageNotes,
        exampleSentenceNative: exampleSentenceNative ?? this.exampleSentenceNative,
        synonymsNative: synonymsNative ?? this.synonymsNative,
        usageNotesNative: usageNotesNative ?? this.usageNotesNative,
        parentCardId: parentCardId ?? this.parentCardId,
        parentWord: parentWord ?? this.parentWord,
        collectionId: clearCollectionId ? null : collectionId ?? this.collectionId,
        spaceId: spaceId ?? this.spaceId,
        cefrLevel: cefrLevel ?? this.cefrLevel,
        grammar: grammar ?? this.grammar,
        synonymsEnriched: synonymsEnriched ?? this.synonymsEnriched,
        exampleSentences: exampleSentences ?? this.exampleSentences,
        usageNotesList: usageNotesList ?? this.usageNotesList,
        wordLang: wordLang ?? this.wordLang,
        translationLang: translationLang ?? this.translationLang,
        status: status ?? this.status,
        easeFactor: easeFactor ?? this.easeFactor,
        intervalDays: intervalDays ?? this.intervalDays,
        repetitions: repetitions ?? this.repetitions,
        nextReview: nextReview ?? this.nextReview,
        createdAt: createdAt ?? this.createdAt,
      );

  factory FlashCard.fromJson(Map<String, dynamic> json) => FlashCard(
        id:                     json['id'] as String,
        userId:                 json['user_id'] as String,
        word:                   json['word'] as String,
        translation:            json['translation'] as String?,
        transcription:          json['transcription'] as String?,
        exampleSentence:        json['example_sentence'] as String?,
        synonyms:               (json['synonyms'] as List<dynamic>?)?.cast<String>(),
        usageNotes:             json['usage_notes'] as String?,
        exampleSentenceNative:  json['example_sentence_native'] as String?,
        synonymsNative:         (json['synonyms_native'] as List<dynamic>?)?.cast<String>(),
        usageNotesNative:       json['usage_notes_native'] as String?,
        parentCardId:           json['parent_card_id'] as String?,
        parentWord:             json['parent_word'] as String?,
        collectionId:           json['collection_id'] as String?,
        spaceId:                json['space_id'] as String?,
        cefrLevel:              json['cefr_level'] as String?,
        grammar:                json['grammar'] != null
            ? Map<String, dynamic>.from(json['grammar'] as Map)
            : null,
        synonymsEnriched:       (json['synonyms_enriched'] as List<dynamic>?)
            ?.map((e) => Map<String, String>.from(e as Map))
            .toList(),
        exampleSentences:       (json['example_sentences'] as List<dynamic>?)?.cast<String>(),
        usageNotesList:         (json['usage_notes_list'] as List<dynamic>?)?.cast<String>(),
        wordLang:               json['word_lang'] as String?,
        translationLang:        json['translation_lang'] as String?,
        status: CardStatus.fromValue(
            json['status'] as String? ?? 'pending'),
        easeFactor:   (json['ease_factor'] as num?)?.toDouble() ?? 2.5,
        intervalDays: json['interval_days'] as int? ?? 0,
        repetitions:  json['repetitions'] as int? ?? 0,
        nextReview: DateTime.tryParse(json['next_review'] as String? ?? '') ?? DateTime.now(),
        createdAt:  DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id':                      id,
        'user_id':                 userId,
        'word':                    word,
        'translation':             translation,
        'transcription':           transcription,
        'example_sentence':        exampleSentence,
        'synonyms':                synonyms,
        'usage_notes':             usageNotes,
        'example_sentence_native': exampleSentenceNative,
        'synonyms_native':         synonymsNative,
        'usage_notes_native':      usageNotesNative,
        'parent_card_id':          parentCardId,
        'parent_word':             parentWord,
        'collection_id':           collectionId,
        'space_id':                spaceId,
        'cefr_level':              cefrLevel,
        'grammar':                 grammar,
        'synonyms_enriched':       synonymsEnriched,
        'example_sentences':       exampleSentences,
        'usage_notes_list':        usageNotesList,
        'word_lang':               wordLang,
        'translation_lang':        translationLang,
        'status':                  status.value,
        'ease_factor':             easeFactor,
        'interval_days':           intervalDays,
        'repetitions':             repetitions,
        'next_review':             nextReview.toIso8601String(),
        'created_at':              createdAt.toIso8601String(),
      };

  /// JSON for INSERT (omits id and created_at — Supabase generates them).
  Map<String, dynamic> toInsertJson() {
    final m = toJson()..remove('id')..remove('created_at');
    return m;
  }
}

enum CardStatus {
  pending('pending'),
  learning('learning'),
  mastered('mastered');

  final String value;
  const CardStatus(this.value);

  static CardStatus fromValue(String v) => CardStatus.values
      .firstWhere((e) => e.value == v, orElse: () => CardStatus.pending);
}
