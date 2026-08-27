import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final _localNotifications = FlutterLocalNotificationsPlugin();

const _androidChannel = AndroidNotificationChannel(
  'default_channel',
  'Notificações',
  description: 'Notificações do app',
  importance: Importance.high,
);

// Must be a top-level (or static) function: FCM runs it in a separate
// isolate that hasn't run our normal app startup, so Firebase needs its own
// init here too.
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
}

/// Sets up everything needed to actually see a push once it arrives:
/// permission prompt, notification channel, and a foreground handler (FCM
/// only auto-displays notifications when the app is backgrounded/killed).
/// Android-only and best-effort — Firebase isn't configured in every build
/// yet, so any failure here is swallowed rather than surfaced, and this must
/// never block app startup.
Future<void> initializePushNotifications() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }

    await _localNotifications.initialize(
      settings: const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    await FirebaseMessaging.instance.requestPermission();

    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;

      _localNotifications.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    });
  } catch (_) {
    // Firebase not configured yet — no permission prompt, no handlers.
  }
}
