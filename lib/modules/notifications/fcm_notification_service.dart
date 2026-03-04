// ignore_for_file: prefer_const_constructors
import 'dart:math';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../contracts/i_notification_service.dart';

/// Firebase Cloud Messaging + flutter_local_notifications.
///
/// Mobile (iOS/Android) push flow:
///   1. initialize() — create Android channel, set up FCM listeners
///   2. requestPermission() — iOS permission dialog
///   3. getToken() → save to Supabase user_settings.push_subscription
///   4. Foreground FCM → showLocalNotification()
///   5. Notification tap → navigate to /review (handled via onNotificationTap)
///   6. Background handler must be registered as a top-level function in main.dart
///
/// NOTE: Firebase.initializeApp() must be called before constructing this service.
/// Initialization is deferred until the user enables notifications in Settings,
/// at which point NotificationService.initialize() is called.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background FCM message.
  // NOTE: Cannot show local notifications here on iOS in background.
}

class FcmNotificationService implements INotificationService {
  final FirebaseMessaging _fcm;
  final FlutterLocalNotificationsPlugin _localNotifications;

  static const _channelId   = 'worddeck_reminders';
  static const _channelName = 'Review Reminders';
  static const _channelDesc = 'Reminds you to review your flashcards';
  static const _notifId     = 1001;

  const FcmNotificationService({
    required FirebaseMessaging fcm,
    required FlutterLocalNotificationsPlugin localNotifications,
  })  : _fcm = fcm,
        _localNotifications = localNotifications;

  // ── initialize ────────────────────────────────────────────────────────────
  @override
  Future<void> initialize() async {
    // Android notification channel
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // flutter_local_notifications init
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Tap handler — navigation is handled by notification_provider
      },
    );

    // FCM foreground message handler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  // ── requestPermission ─────────────────────────────────────────────────────
  @override
  Future<bool> requestPermission() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  // ── scheduleReviewReminder ────────────────────────────────────────────────
  @override
  Future<void> scheduleReviewReminder(DateTime when, int cardsDue) async {
    final title = _pickTitle(cardsDue);
    final body  = _pickBody(cardsDue);

    await _localNotifications.show(
      _notifId,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: '/review',
    );
  }

  // ── cancelAll ─────────────────────────────────────────────────────────────
  @override
  Future<void> cancelAll() async {
    await _localNotifications.cancelAll();
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    _localNotifications.show(
      _notifId,
      notification.title ?? 'WordDeck',
      notification.body ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: message.data['url'] as String? ?? '/review',
    );
  }

  /// Get FCM token to save to Supabase user_settings.push_subscription.
  Future<String?> getToken() => _fcm.getToken();

  /// Re-register token on refresh (call from notification_provider).
  Stream<String> get onTokenRefresh => _fcm.onTokenRefresh;

  // ── Notification copy ─────────────────────────────────────────────────────

  static String _pickTitle(int cardsDue) {
    final titles = [
      'Time to review! 📚',
      'Your words are waiting ⏰',
      'Keep the momentum going 🔥',
      'Quick review session? 💡',
    ];
    return titles[Random().nextInt(titles.length)];
  }

  static String _pickBody(int cardsDue) {
    if (cardsDue <= 0) {
      return 'Open WordDeck to keep your streak alive!';
    }
    final bodies = [
      'You have $cardsDue word${cardsDue == 1 ? '' : 's'} waiting for review! Keep your streak going 🔥',
      '$cardsDue card${cardsDue == 1 ? '' : 's'} ${cardsDue == 1 ? 'is' : 'are'} about to expire. 2 min to save them! ⏰',
      'Don\'t break your streak! $cardsDue quick review${cardsDue == 1 ? '' : 's'} to go 📚',
      '$cardsDue word${cardsDue == 1 ? '' : 's'} ${cardsDue == 1 ? 'is' : 'are'} due — open WordDeck for a quick session ⚡',
    ];
    return bodies[Random().nextInt(bodies.length)];
  }
}
