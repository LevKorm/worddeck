/// Represents a single slide within a [FeedPost].
///
/// Each slide has a [type] that determines how it is rendered, an [order] for
/// sequencing, bilingual content maps, optional type-specific [extra] data,
/// and an optional [decoration] for future vector-graphic overlays.
library;

enum FeedSlideType {
  hero,
  etymology,
  sentences,
  funFact,
  synonymCloud,
  miniStory,
  wordFamily,
  collocations,
  grammar,
  commonMistakes,
  formalityScale,
  idioms,
  compareHero,
  compareGrid,
  themeHero,
  video;

  static FeedSlideType fromValue(String value) => FeedSlideType.values
      .firstWhere((e) => e.name == value, orElse: () => FeedSlideType.hero);
}

class FeedSlide {
  /// Slide layout / content type.
  final FeedSlideType type;

  /// Zero-based position within the parent post's slide list.
  final int order;

  /// Content rendered in the learning language (e.g. English definition,
  /// example sentence in EN, etc.).
  final Map<String, dynamic> contentLearning;

  /// Content rendered in the user's native language.
  final Map<String, dynamic> contentNative;

  /// Type-specific structured data (e.g. sentences list for [FeedSlideType.sentences],
  /// synonym word entries for [FeedSlideType.synonymCloud]).
  final Map<String, dynamic>? extra;

  /// Future: vector-graphic overlay data.  Null until the design system
  /// defines the schema.
  final Map<String, dynamic>? decoration;

  const FeedSlide({
    required this.type,
    required this.order,
    required this.contentLearning,
    required this.contentNative,
    this.extra,
    this.decoration,
  });

  factory FeedSlide.fromJson(Map<String, dynamic> json) => FeedSlide(
        type:  FeedSlideType.fromValue(json['type']?.toString() ?? 'hero'),
        order: json['order'] is int
            ? json['order'] as int
            : int.tryParse(json['order']?.toString() ?? '0') ?? 0,
        contentLearning: json['content_learning'] is Map
            ? Map<String, dynamic>.from(json['content_learning'] as Map)
            : const {},
        contentNative: json['content_native'] is Map
            ? Map<String, dynamic>.from(json['content_native'] as Map)
            : const {},
        extra: json['extra'] is Map
            ? Map<String, dynamic>.from(json['extra'] as Map)
            : null,
        decoration: json['decoration'] is Map
            ? Map<String, dynamic>.from(json['decoration'] as Map)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'type':             type.name,
        'order':            order,
        'content_learning': contentLearning,
        'content_native':   contentNative,
        if (extra != null)      'extra':      extra,
        if (decoration != null) 'decoration': decoration,
      };
}
