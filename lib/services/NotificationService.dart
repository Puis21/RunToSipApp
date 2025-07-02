import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

// Create a FlutterLocalNotificationsPlugin instance here so it's accessible to the handler
final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

// Top level Func
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Show a notification when a background message is received

  ///CAUSED DOULBE NOTIFICATION KEEP IT HERE FOR NOW :)
/*  await _localNotifications.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    message.notification?.title,
    message.notification?.body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'new_runs_channel',
        'New Runs',
        importance: Importance.max,
        priority: Priority.high,
      ),
    ),
  );*/
}

class NotificationService {
  static final _firebaseMessaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {

    // Create the notification channel (for Android 8+)
    const androidChannel = AndroidNotificationChannel(
      'new_runs_channel',
      'New Runs',
      importance: Importance.max,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // Request permissions (Android-only for now)
    await _firebaseMessaging.requestPermission(
      alert: true, badge: true, sound: true,
    );

    // Setup local notifications (for foreground)
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings),
    );

    // Subscribe to topic (for all_users)
    try {
      await FirebaseMessaging.instance.subscribeToTopic('all_users');
    } catch (e) {
      print('Subscribe error: $e');
    }

    // Listener
    FirebaseMessaging.onMessage.listen(_showLocalNotification);

    // Register background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // For foreground notifications
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    ///STILL FOR IN APP NOTIFICATIONS
   /* await _localNotifications.show(
      0,
      message.notification?.title,
      message.notification?.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'new_runs_channel', // Channel ID
          'New Runs',         // Channel Name
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );*/
  }

}