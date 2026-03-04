/// FlashCard — mirrors the Supabase `cards` table exactly.
///
/// Schema (from supabase/migrations/001_initial_schema.sql):
///   id               uuid PK default gen_random_uuid()
///   user_id          uuid FK auth.users ON DELETE CASCADE
///   word             text NOT NULL
///   translation      text
///   transcription    text
///   example_sentence text
///   synonyms         text[]
///   usage_notes      text
///   status           text CHECK IN ('pending','learning','mastered') DEFAULT 'pending'
///   ease_factor      float DEFAULT 2.5
///   interval_days    int   DEFAULT 0
///   repetitions      int   DEFAULT 0
///   next_review      timestamptz DEFAULT now()
///   created_at       timestamptz DEFAULT now()
class FlashCard {
  final String id;
  final String userId;
  final String word;
  final String? translation;
  final String? transcription;
  final String? exampleSentence;
  final List<String>? synonyms;
  final String? usageNotes;
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
        status: status ?? this.status,
        easeFactor: easeFactor ?? this.easeFactor,
        intervalDays: intervalDays ?? this.intervalDays,
        repetitions: repetitions ?? this.repetitions,
        nextReview: nextReview ?? this.nextReview,
        createdAt: createdAt ?? this.createdAt,
      );

  factory FlashCard.fromJson(Map<String, dynamic> json) => FlashCard(
        id:              json['id'] as String,
        userId:          json['user_id'] as String,
        word:            json['word'] as String,
        translation:     json['translation'] as String?,
        transcription:   json['transcription'] as String?,
        exampleSentence: json['example_sentence'] as String?,
        synonyms:        (json['synonyms'] as List<dynamic>?)?.cast<String>(),
        usageNotes:      json['usage_notes'] as String?,
        status: CardStatus.fromValue(
            json['status'] as String? ?? 'pending'),
        easeFactor:  (json['ease_factor'] as num?)?.toDouble() ?? 2.5,
        intervalDays: json['interval_days'] as int? ?? 0,
        repetitions:  json['repetitions'] as int? ?? 0,
        nextReview: DateTime.parse(json['next_review'] as String),
        createdAt:  DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id':               id,
        'user_id':          userId,
        'word':             word,
        'translation':      translation,
        'transcription':    transcription,
        'example_sentence': exampleSentence,
        'synonyms':         synonyms,
        'usage_notes':      usageNotes,
        'status':           status.value,
        'ease_factor':      easeFactor,
        'interval_days':    intervalDays,
        'repetitions':      repetitions,
        'next_review':      nextReview.toIso8601String(),
        'created_at':       createdAt.toIso8601String(),
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
