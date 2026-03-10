import 'package:crisis360app/features/register/register.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'components/navbar/navbar.dart';
import 'core/services/auth_service.dart';
import 'features/login/login.dart';
import 'features/welcome/welcome.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print("Background message received: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(
    _firebaseMessagingBackgroundHandler,
  );

  await requestNotificationPermission();
  await setupFCMListeners();

  final currentUser = FirebaseAuthService().currentUser;

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("NOTIFICATION RECEIVED");
    print(message.notification?.title);
    print(message.notification?.body);
  });

  runApp(Crisis360App(isLoggedIn: currentUser != null));
}

Future<void> requestNotificationPermission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false,
  );

  print("Permission: ${settings.authorizationStatus}");
}

Future<void> setupFCMListeners() async {
  // App opened from terminated state by tapping notification
  RemoteMessage? initialMessage =
  await FirebaseMessaging.instance.getInitialMessage();

  if (initialMessage != null) {
    handleSafetyMessage(initialMessage);
  }

  // Foreground
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    handleSafetyMessage(message);
  });

  // Background -> opened by tapping notification
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    handleSafetyMessage(message);
  });
}

void handleSafetyMessage(RemoteMessage message) {
  if (message.data['type'] == "SAFETY_CHECK") {
    Get.defaultDialog(
      title: "Safety Confirmation",
      middleText: "Are you safe?",
      textConfirm: "Yes",
      textCancel: "No",
      onConfirm: () {
        Get.back();
      },
      onCancel: () {},
    );
  }
}

class Crisis360App extends StatelessWidget {
  const Crisis360App({super.key, required this.isLoggedIn});

  final bool isLoggedIn;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Crisis360',
      theme: ThemeData(
        fontFamily: 'Roboto',
      ),
      home: isLoggedIn ? const NavigationMenu() : const Welcome(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/navbar': (context) => const NavigationMenu(),
        '/login': (context) => const Login(),
        '/register': (context) => const RegisterPage(),
      },
    );
  }
}