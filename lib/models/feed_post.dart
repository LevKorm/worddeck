/// Top-level feed item shown in the Discovery Feed.
///
/// A [FeedPost] contains an ordered list of [FeedSlide]s.  It may represent:
///   - a word from the user's own deck ([FeedPostType.word])
///   - a side-by-side word comparison ([FeedPostType.compare])
///   - a thematic collection ([FeedPostType.theme])
library;

import 'feed_slide.dart';

// ── Post type ─────────────────────────────────────────────────────────────────

enum FeedPostType {
  word,
  compare,
  theme;

  static FeedPostType fromValue(String value) => FeedPostType.values
      .firstWhere((e) => e.name == value, orElse: () => FeedPostType.word);
}

// ── Suggest reason ────────────────────────────────────────────────────────────

enum SuggestReasonType {
  related,
  wordOfDay,
  essential,
  completeSet,
  commonlyConfused;

  static SuggestReasonType fromValue(String value) =>
      SuggestReasonType.values.firstWhere(
        (e) => e.name == value,
        orElse: () => SuggestReasonType.related,
      );
}

class SuggestReason {
  final SuggestReasonType type;

  /// Human-readable label, e.g. "Related to Serendipity".
  final String label;

  /// Emoji icon representing the reason category.
  final String icon;

  const SuggestReason({
    required this.type,
    required this.label,
    required this.icon,
  });

  factory SuggestReason.fromJson(Map<String, dynamic> json) => SuggestReason(
        type:  SuggestReasonType.fromValue(json['type'] as String),
        label: json['label'] as String,
        icon:  json['icon'] as String,
      );

  Map<String, dynamic> toJson() => {
        'type':  type.name,
        'label': label,
        'icon':  icon,
      };
}

// ── Feed post ─────────────────────────────────────────────────────────────────

class FeedPost {
  final String id;

  /// FK to the `cards` table.  Null for suggested / compare / theme posts.
  final String? cardId;

  final String userId;
  final FeedPostType postType;

  /// The primary word for this post.  Null for [FeedPostType.theme] posts.
  final String? word;
  final String? translation;
  final String? ipa;

  final List<FeedSlide> slides;
  final DateTime generatedAt;

  /// 'pending' | 'ready' | 'failed'
  final String status;

  /// Local UI state — toggled without a full reload.
  final bool liked;

  /// True when this post was system-generated (not from the user's own deck).
  final bool suggested;

  /// Non-null only when [suggested] is true.
  final SuggestReason? suggestReason;

  /// Future: post-level decoration / background data.
  final Map<String, dynamic>? decoration;

  const FeedPost({
    required this.id,
    this.cardId,
    required this.userId,
    required this.postType,
    this.word,
    this.translation,
    this.ipa,
    required this.slides,
    required this.generatedAt,
    this.status = 'pending',
    this.liked = false,
    this.suggested = false,
    this.suggestReason,
    this.decoration,
  });

  FeedPost copyWith({
    String? id,
    String? cardId,
    String? userId,
    FeedPostType? postType,
    String? word,
    String? translation,
    String? ipa,
    List<FeedSlide>? slides,
    DateTime? generatedAt,
    String? status,
    bool? liked,
    bool? suggested,
    SuggestReason? suggestReason,
    Map<String, dynamic>? decoration,
  }) =>
      FeedPost(
        id:            id            ?? this.id,
        cardId:        cardId        ?? this.cardId,
        userId:        userId        ?? this.userId,
        postType:      postType      ?? this.postType,
        word:          word          ?? this.word,
        translation:   translation   ?? this.translation,
        ipa:           ipa           ?? this.ipa,
        slides:        slides        ?? this.slides,
        generatedAt:   generatedAt   ?? this.generatedAt,
        status:        status        ?? this.status,
        liked:         liked         ?? this.liked,
        suggested:     suggested     ?? this.suggested,
        suggestReason: suggestReason ?? this.suggestReason,
        decoration:    decoration    ?? this.decoration,
      );

  factory FeedPost.fromJson(Map<String, dynamic> json) => FeedPost(
        id:          json['id'] as String,
        cardId:      json['card_id'] as String?,
        userId:      json['user_id'] as String,
        postType:    FeedPostType.fromValue(json['post_type'] as String? ?? 'word'),
        word:        json['word'] as String?,
        translation: json['translation'] as String?,
        ipa:         json['ipa'] as String?,
        slides:      (json['slides'] as List<dynamic>? ?? [])
                         .whereType<Map>()
                         .map((s) => FeedSlide.fromJson(
                               Map<String, dynamic>.from(s)))
                         .toList(),
        generatedAt: DateTime.parse(json['generated_at'] as String),
        status:      json['status'] as String? ?? 'pending',
        liked:       json['liked'] as bool? ?? false,
        suggested:   json['suggested'] as bool? ?? false,
        suggestReason: json['suggest_reason'] != null
            ? SuggestReason.fromJson(
                Map<String, dynamic>.from(json['suggest_reason'] as Map))
            : null,
        decoration:  json['decoration'] != null
            ? Map<String, dynamic>.from(json['decoration'] as Map)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id':           id,
        'card_id':      cardId,
        'user_id':      userId,
        'post_type':    postType.name,
        'word':         word,
        'translation':  translation,
        'ipa':          ipa,
        'slides':       slides.map((s) => s.toJson()).toList(),
        'generated_at': generatedAt.toIso8601String(),
        'status':       status,
        'liked':        liked,
        'suggested':    suggested,
        if (suggestReason != null) 'suggest_reason': suggestReason!.toJson(),
        if (decoration != null)    'decoration':     decoration,
      };
}
