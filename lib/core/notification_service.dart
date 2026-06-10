import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

// Background message handler — must be top-level
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _local = FlutterLocalNotificationsPlugin();

  static const _channelId = 'anon_responses';
  static const _channelName = 'New Responses';

  static Future<void> init() async {
    await Firebase.initializeApp();

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    // Request permission (Android 13+ / iOS)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Set foreground notification presentation
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Init local notifications (for foreground display on Android)
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _local.initialize(initSettings);

    // Create notification channel
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Notifies you when someone sends an anonymous response',
      importance: Importance.high,
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Show local notification when app is in foreground
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      _local.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            icon: '@mipmap/ic_launcher',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    });
  }

  // Call after login — sends FCM token to backend
  static Future<void> registerToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await ApiService.post('/api/fcm-token', {'token': token});
      }
      _messaging.onTokenRefresh.listen((newToken) async {
        try {
          await ApiService.post('/api/fcm-token', {'token': newToken});
        } catch (_) {}
      });
    } catch (_) {
      // Silently fail — notifications are non-critical
    }
  }

  static Future<void> clearToken() async {
    try {
      await _messaging.deleteToken();
      await ApiService.post('/api/fcm-token', {'token': null});
    } catch (_) {}
  }
}
