
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance =
  NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Web needs additional push notification configuration.
    if (kIsWeb) {
      debugPrint(
        'Web push notifications require additional configuration.',
      );
      return;
    }

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint(
      'Notification permission: ${settings.authorizationStatus}',
    );

    await saveDeviceToken();

    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      await _saveTokenToFirestore(token);
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
        'Foreground notification: ${message.notification?.title}',
      );
      debugPrint(
        'Notification body: ${message.notification?.body}',
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen(
          (RemoteMessage message) {
        debugPrint('Notification opened: ${message.data}');
      },
    );

    final initialMessage = await _messaging.getInitialMessage();

    if (initialMessage != null) {
      debugPrint(
        'App opened from notification: ${initialMessage.data}',
      );
    }
  }

  Future<void> saveDeviceToken() async {
    if (kIsWeb) return;

    final token = await _messaging.getToken();

    if (token != null) {
      await _saveTokenToFirestore(token);
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      debugPrint('No signed-in user; FCM token not saved.');
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'fcmTokens': FieldValue.arrayUnion([token]),
        },
        SetOptions(merge: true),
      );

      debugPrint('FCM token saved for current user.');
    } catch (error) {
      debugPrint('Could not save FCM token: $error');
    }
  }
}
