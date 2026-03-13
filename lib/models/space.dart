import '../core/constants/app_constants.dart';

/// A Language Space — an isolated learning environment for one language pair.
///
/// Maps to the public.spaces Supabase table.
class Space {
  final String id;
  final String userId;
  final String nativeLanguage;
  final String learningLanguage;
  final int displayOrder;
  final DateTime createdAt;

  const Space({
    required this.id,
    required this.userId,
    required this.nativeLanguage,
    required this.learningLanguage,
    required this.displayOrder,
    required this.createdAt,
  });

  factory Space.fromJson(Map<String, dynamic> json) => Space(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        nativeLanguage: json['native_language'] as String,
        learningLanguage: json['learning_language'] as String,
        displayOrder: json['display_order'] as int? ?? 0,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'native_language': nativeLanguage,
        'learning_language': learningLanguage,
        'display_order': displayOrder,
        'created_at': createdAt.toIso8601String(),
      };

  Map<String, dynamic> toInsertJson() => {
        'user_id': userId,
        'native_language': nativeLanguage,
        'learning_language': learningLanguage,
        'display_order': displayOrder,
      };

  Space copyWith({
    String? nativeLanguage,
    String? learningLanguage,
    int? displayOrder,
  }) =>
      Space(
        id: id,
        userId: userId,
        nativeLanguage: nativeLanguage ?? this.nativeLanguage,
        learningLanguage: learningLanguage ?? this.learningLanguage,
        displayOrder: displayOrder ?? this.displayOrder,
        createdAt: createdAt,
      );

  /// Display name: "English Space"
  String get displayName => '${AppConstants.languageDisplayName(learningLanguage)} Space';

  /// Full label: "🇬🇧 English"
  String get label =>
      '${AppConstants.flagForCode(learningLanguage)} $displayName';

  /// Native language subtitle: "Ukrainian fluent"
  String get subtitle =>
      '${AppConstants.languageDisplayName(nativeLanguage)} fluent';

  /// Flag emoji for the learning language
  String get learningFlag => AppConstants.flagForCode(learningLanguage);

  /// Flag emoji for the native language
  String get nativeFlag => AppConstants.flagForCode(nativeLanguage);
}
