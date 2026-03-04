import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../modules/auth/auth_provider.dart';
import '../../modules/cards/card_provider.dart';
import '../../modules/notifications/notification_provider.dart';
import '../../providers/statistics_provider.dart';
import '../../providers/theme_provider.dart';

// ── State ──────────────────────────────────────────────────────────────────

class SettingsState {
  final String iSpeakLang;
  final String imLearningLang;
  final ThemeMode themeMode;
  final int dailyGoal;
  final bool pushEnabled;
  final int quietHoursFrom;
  final int quietHoursTo;
  final String frequency;

  const SettingsState({
    this.iSpeakLang     = AppConstants.defaultNativeLanguage,
    this.imLearningLang = AppConstants.defaultLearningLanguage,
    this.themeMode      = ThemeMode.system,
    this.dailyGoal      = 10,
    this.pushEnabled    = false,
    this.quietHoursFrom = 9,
    this.quietHoursTo   = 22,
    this.frequency      = 'medium',
  });

  SettingsState copyWith({
    String?    iSpeakLang,
    String?    imLearningLang,
    ThemeMode? themeMode,
    int?       dailyGoal,
    bool?      pushEnabled,
    int?       quietHoursFrom,
    int?       quietHoursTo,
    String?    frequency,
  }) =>
      SettingsState(
        iSpeakLang:     iSpeakLang     ?? this.iSpeakLang,
        imLearningLang: imLearningLang ?? this.imLearningLang,
        themeMode:      themeMode      ?? this.themeMode,
        dailyGoal:      dailyGoal      ?? this.dailyGoal,
        pushEnabled:    pushEnabled    ?? this.pushEnabled,
        quietHoursFrom: quietHoursFrom ?? this.quietHoursFrom,
        quietHoursTo:   quietHoursTo   ?? this.quietHoursTo,
        frequency:      frequency      ?? this.frequency,
      );
}

// ── Notifier ───────────────────────────────────────────────────────────────

class SettingsController extends StateNotifier<SettingsState> {
  final Ref _ref;

  SettingsController(this._ref) : super(const SettingsState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs       = await SharedPreferences.getInstance();
    final notifState  = _ref.read(notificationSettingsProvider);
    final sessionState = _ref.read(sessionStatsProvider);

    state = SettingsState(
      iSpeakLang:     prefs.getString('i_speak')      ?? AppConstants.defaultNativeLanguage,
      imLearningLang: prefs.getString('im_learning')  ?? AppConstants.defaultLearningLanguage,
      themeMode:      _ref.read(themeModeProvider),
      dailyGoal:      sessionState.dailyGoal,
      pushEnabled:    notifState.enabled,
      quietHoursFrom: notifState.minHour,
      quietHoursTo:   notifState.maxHour,
      frequency:      notifState.frequency,
    );
  }

  // ── Languages ─────────────────────────────────────────────────────────────

  Future<void> updateISpeakLang(String lang) async {
    state = state.copyWith(iSpeakLang: lang);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('i_speak', lang);
  }

  Future<void> updateImLearningLang(String lang) async {
    state = state.copyWith(imLearningLang: lang);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('im_learning', lang);
  }

  // ── Appearance ────────────────────────────────────────────────────────────

  Future<void> updateTheme(ThemeMode mode) async {
    await _ref.read(themeModeProvider.notifier).setMode(mode);
    state = state.copyWith(themeMode: mode);
  }

  // ── Learning ──────────────────────────────────────────────────────────────

  Future<void> updateDailyGoal(int goal) async {
    if (goal < 1) return;
    await _ref.read(sessionStatsProvider.notifier).setDailyGoal(goal);
    state = state.copyWith(dailyGoal: goal);
  }

  // ── Notifications ─────────────────────────────────────────────────────────

  Future<void> togglePush() async {
    final newEnabled = !state.pushEnabled;
    if (newEnabled) {
      final granted =
          await _ref.read(notificationServiceProvider).requestPermission();
      if (!granted) return;
      await _ref.read(notificationServiceProvider).initialize();
    }
    await _ref
        .read(notificationSettingsProvider.notifier)
        .setEnabled(newEnabled);
    state = state.copyWith(pushEnabled: newEnabled);
  }

  Future<void> updateQuietHours(int from, int to) async {
    await _ref
        .read(notificationSettingsProvider.notifier)
        .setQuietHours(from, to);
    state = state.copyWith(quietHoursFrom: from, quietHoursTo: to);
  }

  Future<void> updateFrequency(String freq) async {
    await _ref
        .read(notificationSettingsProvider.notifier)
        .setFrequency(freq);
    state = state.copyWith(frequency: freq);
  }

  // ── Data ──────────────────────────────────────────────────────────────────

  /// Export — platform file picker needed; stub for now.
  Future<void> exportDeck(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Import — platform file picker needed; stub for now.
  Future<void> importDeck(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Import coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> clearAllWords() async {
    final userId = _ref.read(currentUserProvider)?.userId;
    if (userId == null) return;
    await _ref.read(cardRepositoryProvider).clearAllCards(userId);
    await _ref.read(cardListProvider.notifier).loadCards(userId);
  }

  // ── Account ───────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _ref.read(authServiceProvider).signOut();
    // GoRouter redirect guard handles navigation to /login automatically
  }
}

// ── Provider ───────────────────────────────────────────────────────────────

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, SettingsState>(
  (ref) => SettingsController(ref),
);
