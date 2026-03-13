/// UserProfile — mirrors the Supabase `user_settings` table.
///
/// Schema (from supabase/migrations/001_initial_schema.sql + 002):
///   user_id          uuid PK FK auth.users ON DELETE CASCADE
///   native_language  text NOT NULL DEFAULT 'UK'
///   learning_language text NOT NULL DEFAULT 'EN'
///   notif_enabled    boolean NOT NULL DEFAULT false
///   notif_min_hour   int NOT NULL DEFAULT 9
///   notif_max_hour   int NOT NULL DEFAULT 22
///   notif_frequency  text DEFAULT 'medium' CHECK IN ('low','medium','high')
///   push_subscription jsonb  (stores {token: '...'} for FCM)
///   created_at       timestamptz NOT NULL DEFAULT now()
///   notif_last_sent  timestamptz
class UserProfile {
  final String userId;
  final String nativeLanguage;
  final String learningLanguage;
  final bool notifEnabled;
  final int notifMinHour;
  final int notifMaxHour;
  final String notifFrequency;
  final Map<String, dynamic>? pushSubscription;
  final DateTime createdAt;
  final DateTime? notifLastSent;

  const UserProfile({
    required this.userId,
    this.nativeLanguage = 'UK',
    this.learningLanguage = 'EN',
    this.notifEnabled = false,
    this.notifMinHour = 9,
    this.notifMaxHour = 22,
    this.notifFrequency = 'medium',
    this.pushSubscription,
    required this.createdAt,
    this.notifLastSent,
  });

  factory UserProfile.defaults(String userId) => UserProfile(
        userId: userId,
        createdAt: DateTime.now(),
      );

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        userId:           json['user_id'] as String,
        nativeLanguage:   json['native_language'] as String? ?? 'UK',
        learningLanguage: json['learning_language'] as String? ?? 'EN',
        notifEnabled:     json['notif_enabled'] as bool? ?? false,
        notifMinHour:     json['notif_min_hour'] as int? ?? 9,
        notifMaxHour:     json['notif_max_hour'] as int? ?? 22,
        notifFrequency:   json['notif_frequency'] as String? ?? 'medium',
        pushSubscription: json['push_subscription'] as Map<String, dynamic>?,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
        notifLastSent: json['notif_last_sent'] != null
            ? DateTime.tryParse(json['notif_last_sent'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'user_id':           userId,
        'native_language':   nativeLanguage,
        'learning_language': learningLanguage,
        'notif_enabled':     notifEnabled,
        'notif_min_hour':    notifMinHour,
        'notif_max_hour':    notifMaxHour,
        'notif_frequency':   notifFrequency,
        'push_subscription': pushSubscription,
        'created_at':        createdAt.toIso8601String(),
        'notif_last_sent':   notifLastSent?.toIso8601String(),
      };

  UserProfile copyWith({
    String? nativeLanguage,
    String? learningLanguage,
    bool? notifEnabled,
    int? notifMinHour,
    int? notifMaxHour,
    String? notifFrequency,
    Map<String, dynamic>? pushSubscription,
    DateTime? notifLastSent,
  }) =>
      UserProfile(
        userId:           userId,
        nativeLanguage:   nativeLanguage ?? this.nativeLanguage,
        learningLanguage: learningLanguage ?? this.learningLanguage,
        notifEnabled:     notifEnabled ?? this.notifEnabled,
        notifMinHour:     notifMinHour ?? this.notifMinHour,
        notifMaxHour:     notifMaxHour ?? this.notifMaxHour,
        notifFrequency:   notifFrequency ?? this.notifFrequency,
        pushSubscription: pushSubscription ?? this.pushSubscription,
        createdAt:        createdAt,
        notifLastSent:    notifLastSent ?? this.notifLastSent,
      );
}
