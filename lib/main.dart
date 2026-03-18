import 'package:crisis360app/features/register/register.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'components/navbar/navbar.dart';
import 'core/config/firebase_background_handler.dart';
import 'core/services/auth_service.dart';
import 'core/services/notification_service.dart';
import 'features/login/login.dart';
import 'features/welcome/welcome.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await NotificationService.instance.initLocalNotifications();
  await NotificationService.instance.requestNotificationPermission();

  final currentUser = FirebaseAuthService().currentUser;

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(Crisis360App(isLoggedIn: currentUser != null));
}

class Crisis360App extends StatefulWidget {
  const Crisis360App({super.key, required this.isLoggedIn});

  final bool isLoggedIn;

  @override
  State<Crisis360App> createState() => _Crisis360AppState();
}

class _Crisis360AppState extends State<Crisis360App> {
  @override
  void initState() {
    super.initState();
    NotificationService.instance.setupFCMListeners();
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Crisis360',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
      ),
      home: widget.isLoggedIn ? const NavigationMenu() : const Welcome(),
      routes: {
        '/navbar': (context) => const NavigationMenu(),
        '/login': (context) => const Login(),
        '/register': (context) => const RegisterPage(),
      },
    );
  }
}