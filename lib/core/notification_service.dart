import 'dart:developer' as dev;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

// Must be top-level and annotated — runs when app is killed/background
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Notification-type FCM messages are shown automatically by the OS.
  // Nothing more needed here for background/killed state.
}

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _local = FlutterLocalNotificationsPlugin();

  static const _channelId = 'anon_responses';
  static const _channelName = 'New Responses';
  static const _sound = RawResourceAndroidNotificationSound('anonymous_notification');

  static Future<void> init() async {
    await Firebase.initializeApp();

    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    // Request permission — shows dialog on Android 13+ and iOS
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    dev.log('Notification permission: ${settings.authorizationStatus}');

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Init local notifications plugin
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _local.initialize(const InitializationSettings(android: androidInit));

    // Create high-importance channel with custom sound — must match channelId
    // sent in FCM message from backend.
    final channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Alerts when someone sends you an anonymous response',
      importance: Importance.max,       // MAX = shows as heads-up on screen
      sound: _sound,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Show local notification when app is in the FOREGROUND
    FirebaseMessaging.onMessage.listen((message) {
      final n = message.notification;
      if (n == null) return;
      dev.log('Foreground message: ${n.title} — ${n.body}');
      _local.show(
        n.hashCode,
        n.title,
        n.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            icon: '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
            sound: _sound,
            playSound: true,
            enableVibration: true,
            ticker: n.title ?? 'Anonymous',
            styleInformation: BigTextStyleInformation(n.body ?? ''),
          ),
        ),
      );
    });
  }

  static Future<void> registerToken() async {
    try {
      final token = await _messaging.getToken();
      dev.log('FCM token: $token');
      if (token != null) {
        await ApiService.post('/api/fcm-token', {'token': token});
        dev.log('FCM token registered with backend');
      }
      _messaging.onTokenRefresh.listen((newToken) async {
        try {
          await ApiService.post('/api/fcm-token', {'token': newToken});
        } catch (_) {}
      });
    } catch (e) {
      dev.log('FCM token registration failed: $e');
    }
  }

  static Future<void> clearToken() async {
    try {
      await _messaging.deleteToken();
      await ApiService.post('/api/fcm-token', {'token': null});
    } catch (_) {}
  }
}
