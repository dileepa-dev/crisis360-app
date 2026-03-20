import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static const AndroidNotificationChannel highImportanceChannel =
  AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'Used for important alerts.',
    importance: Importance.max,
  );

  bool _listenersInitialized = false;

  Future<void> initLocalNotifications() async {
    final androidPlugin =
    flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(highImportanceChannel);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) async {
        debugPrint("Local notification tapped");
      },
    );
  }

  Future<void> requestNotificationPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint("Permission: ${settings.authorizationStatus}");

    // Only continue token flow on Android
    if (!kIsWeb && Platform.isAndroid) {
      final token = await _messaging.getToken();
      debugPrint("ANDROID FCM TOKEN: $token");
    } else {
      debugPrint("Skipping FCM token fetch on non-Android platform");
    }
  }

  Future<String?> getAndroidFcmTokenOrNull() async {
    if (kIsWeb) return null;
    if (!Platform.isAndroid) return null;

    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint("Error getting Android FCM token: $e");
      return null;
    }
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
    if (_listenersInitialized) return;
    _listenersInitialized = true;

    final initialMessage = await _messaging.getInitialMessage();

    if (initialMessage != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleMessageRouting(initialMessage, fromUserTap: true);
      });
    }

    FirebaseMessaging.onMessage.listen((message) async {
      debugPrint("Foreground notification received");
      debugPrint("Message data: ${message.data}");

      await showLocalNotification(message);
      _handleSafetyMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint("Notification tapped from background");
      _handleMessageRouting(message, fromUserTap: true);
    });
  }

  void _handleMessageRouting(
      RemoteMessage message, {
        bool fromUserTap = false,
      }) {
    final String? type = message.data['type'];
    final String? title = message.data['title'] ?? message.notification?.title;

    final bool isSafety =
        type == "SAFETY_CHECK" ||
            title == "Safety Confirmation Required" ||
            title == "Safety Confirmation" ||
            title == "SAFETY_CHECK";

    if (isSafety) {
      _handleSafetyMessage(message);
    } else if (fromUserTap) {
      handleIncomingMessage(message);
    }
  }

  void _handleSafetyMessage(RemoteMessage message) {
    final String? title = message.data['title'] ?? message.notification?.title;
    final String? body = message.data['body'] ?? message.notification?.body;
    final String? type = message.data['type'];

    final bool shouldShowDialog =
        type == "SAFETY_CHECK" ||
            title == "Safety Confirmation Required" ||
            title == "Safety Confirmation" ||
            title == "SAFETY_CHECK";

    if (!shouldShowDialog) return;

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

  void handleIncomingMessage(RemoteMessage message) {
    final String title =
        message.notification?.title ??
            message.data['title'] ??
            "New Notification";

    final String body =
        message.notification?.body ??
            message.data['body'] ??
            "You have received a new message.";

    Future.delayed(const Duration(milliseconds: 300), () {
      if (Get.isDialogOpen ?? false) return;

      Get.defaultDialog(
        title: title,
        middleText: body,
        textConfirm: "OK",
        confirmTextColor: Colors.white,
        onConfirm: () => Get.back(),
      );
    });
  }
}