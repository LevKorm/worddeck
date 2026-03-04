import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  AppConstants._();

  // ── Supabase ─────────────────────────────────────────────────────────────
  static String get supabaseUrl => dotenv.env['SUPABASE_URL']!;
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY']!;

  // ── HTTP timeouts ────────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // ── SM-2 ─────────────────────────────────────────────────────────────────
  static const double sm2DefaultEaseFactor = 2.5;
  static const double sm2MinEaseFactor = 1.3;

  // ── Language defaults (matches Supabase schema defaults) ─────────────────
  static const String defaultNativeLanguage = 'UK';
  static const String defaultLearningLanguage = 'EN';

  // ── Notification throttle (max 1 notif per N hours) ──────────────────────
  static const Map<String, int> notifFrequencyHours = {
    'low': 24,
    'medium': 12,
    'high': 6,
  };

  // ── Supported language codes (DeepL, 25 languages) ───────────────────────
  static const List<String> supportedLanguageCodes = [
    'UK', 'EN', 'DE', 'FR', 'ES', 'IT', 'PT', 'PL', 'NL',
    'JA', 'ZH', 'KO', 'RU', 'TR', 'AR', 'CS', 'DA', 'FI',
    'EL', 'HU', 'ID', 'NB', 'RO', 'SK', 'SV',
  ];

  static const Map<String, String> languageNames = {
    'UK': 'Ukrainian', 'EN': 'English',  'DE': 'German',
    'FR': 'French',    'ES': 'Spanish',  'IT': 'Italian',
    'PT': 'Portuguese','PL': 'Polish',   'NL': 'Dutch',
    'JA': 'Japanese',  'ZH': 'Chinese',  'KO': 'Korean',
    'RU': 'Russian',   'TR': 'Turkish',  'AR': 'Arabic',
    'CS': 'Czech',     'DA': 'Danish',   'FI': 'Finnish',
    'EL': 'Greek',     'HU': 'Hungarian','ID': 'Indonesian',
    'NB': 'Norwegian', 'RO': 'Romanian', 'SK': 'Slovak',
    'SV': 'Swedish',
  };

  static const Map<String, String> languageFlags = {
    'UK': '🇺🇦', 'EN': '🇬🇧', 'DE': '🇩🇪', 'FR': '🇫🇷', 'ES': '🇪🇸',
    'IT': '🇮🇹', 'PT': '🇵🇹', 'PL': '🇵🇱', 'NL': '🇳🇱', 'JA': '🇯🇵',
    'ZH': '🇨🇳', 'KO': '🇰🇷', 'RU': '🇷🇺', 'TR': '🇹🇷', 'AR': '🇸🇦',
    'CS': '🇨🇿', 'DA': '🇩🇰', 'FI': '🇫🇮', 'EL': '🇬🇷', 'HU': '🇭🇺',
    'ID': '🇮🇩', 'NB': '🇳🇴', 'RO': '🇷🇴', 'SK': '🇸🇰', 'SV': '🇸🇪',
  };
}
