import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel highImportanceChannel =
  AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'Used for important alerts.',
    importance: Importance.max,
  );

  Future<void> initLocalNotifications() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
    >()
        ?.createNotificationChannel(highImportanceChannel);

    const AndroidInitializationSettings androidInitializationSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInitializationSettings =
    DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
    InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(settings: initializationSettings);
  }

  Future<void> requestNotificationPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint("Permission: ${settings.authorizationStatus}");

    final token = await messaging.getToken();
    debugPrint("FCM TOKEN: $token");
  }

  Future<void> showLocalNotification(RemoteMessage message) async {
    final RemoteNotification? notification = message.notification;

    final String title =
        notification?.title ?? message.data['title'] ?? "New Notification";

    final String body =
        notification?.body ??
            message.data['body'] ??
            "You have received a new message.";

    await flutterLocalNotificationsPlugin.show(
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          highImportanceChannel.id,
          highImportanceChannel.name,
          channelDescription: highImportanceChannel.description,
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> setupFCMListeners() async {
    RemoteMessage? initialMessage =
    await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      debugPrint("App opened from terminated state");
      debugPrint("Initial message data: ${initialMessage.data}");

      Future.delayed(const Duration(milliseconds: 500), () {
        handleIncomingMessage(initialMessage);
      });
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint("Foreground notification received");
      debugPrint("Message ID: ${message.messageId}");
      debugPrint("Message data: ${message.data}");
      debugPrint("Message title: ${message.notification?.title}");
      debugPrint("Message body: ${message.notification?.body}");

      await showLocalNotification(message);
      handleSafetyMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("Notification tapped from background");
      debugPrint("Opened message data: ${message.data}");

      handleSafetyMessage(message);
      handleIncomingMessage(message);
    });
  }

  void handleSafetyMessage(RemoteMessage message) {
    final String? type = message.data['type'];
    final String? title = message.data['title'] ?? message.notification?.title;
    final String? body = message.data['body'] ?? message.notification?.body;

    debugPrint("handleSafetyMessage called");
    debugPrint("type: $type");
    debugPrint("title: $title");
    debugPrint("body: $body");

    final bool shouldShowDialog =
        type == "SAFETY_CHECK" ||
            title == "Safety Confirmation Required" ||
            title == "Safety Confirmation" ||
            title == "SAFETY_CHECK";

    if (shouldShowDialog) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (Get.isDialogOpen ?? false) return;

        Get.defaultDialog(
          title: title ?? "Safety Confirmation",
          middleText: body ?? "Are you safe?",
          textConfirm: "Yes",
          textCancel: "No",
          confirmTextColor: Colors.white,
          onConfirm: () {
            Get.back();
            debugPrint("User clicked YES");
          },
          onCancel: () {
            debugPrint("User clicked NO");
          },
        );
      });
    }
  }

  void handleIncomingMessage(RemoteMessage message) {
    final String title =
        message.notification?.title ??
            message.data['title'] ??
            "New Notification";

    final String body =
        message.notification?.body ??
            message.data['body'] ??
            "You have received a new message.";

    debugPrint("Showing dialog");
    debugPrint("Title: $title");
    debugPrint("Body: $body");

    Future.delayed(const Duration(milliseconds: 300), () {
      if (Get.isDialogOpen ?? false) return;

      Get.defaultDialog(
        title: title,
        middleText: body,
        textConfirm: "OK",
        confirmTextColor: Colors.white,
        onConfirm: () {
          Get.back();
        },
      );
    });
  }
}