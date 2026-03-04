import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../contracts/i_notification_service.dart';
import 'fcm_notification_service.dart';

// ── Prefs keys ────────────────────────────────────────────────────────────────
const _kNotifEnabled    = 'notif_enabled';
const _kNotifMinHour    = 'notif_min_hour';
const _kNotifMaxHour    = 'notif_max_hour';
const _kNotifFrequency  = 'notif_frequency';

// ── Service provider ──────────────────────────────────────────────────────────

/// NOTE: FcmNotificationService requires Firebase to be initialized.
/// Only create this provider after Firebase.initializeApp() succeeds.
final notificationServiceProvider = Provider<INotificationService>((ref) {
  return FcmNotificationService(
    fcm: FirebaseMessaging.instance,
    localNotifications: FlutterLocalNotificationsPlugin(),
  );
});

// ── Notification settings state ───────────────────────────────────────────────

class NotificationSettings {
  final bool enabled;
  final int minHour;     // quiet hours start (default 9)
  final int maxHour;     // quiet hours end   (default 22)
  final String frequency; // 'low' | 'medium' | 'high'

  const NotificationSettings({
    this.enabled    = false,
    this.minHour    = 9,
    this.maxHour    = 22,
    this.frequency  = 'medium',
  });

  NotificationSettings copyWith({
    bool? enabled,
    int? minHour,
    int? maxHour,
    String? frequency,
  }) =>
      NotificationSettings(
        enabled:   enabled   ?? this.enabled,
        minHour:   minHour   ?? this.minHour,
        maxHour:   maxHour   ?? this.maxHour,
        frequency: frequency ?? this.frequency,
      );
}

class NotificationSettingsNotifier
    extends StateNotifier<NotificationSettings> {
  NotificationSettingsNotifier() : super(const NotificationSettings());

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = NotificationSettings(
      enabled:   prefs.getBool(_kNotifEnabled)    ?? false,
      minHour:   prefs.getInt(_kNotifMinHour)     ?? 9,
      maxHour:   prefs.getInt(_kNotifMaxHour)     ?? 22,
      frequency: prefs.getString(_kNotifFrequency)?? 'medium',
    );
  }

  Future<void> setEnabled(bool enabled) async {
    state = state.copyWith(enabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifEnabled, enabled);
  }

  Future<void> setQuietHours(int min, int max) async {
    state = state.copyWith(minHour: min, maxHour: max);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kNotifMinHour, min);
    await prefs.setInt(_kNotifMaxHour, max);
  }

  Future<void> setFrequency(String frequency) async {
    state = state.copyWith(frequency: frequency);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kNotifFrequency, frequency);
  }
}

final notificationSettingsProvider = StateNotifierProvider<
    NotificationSettingsNotifier, NotificationSettings>(
  (ref) => NotificationSettingsNotifier()..load(),
);
