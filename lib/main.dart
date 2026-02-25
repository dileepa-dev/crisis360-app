import 'package:crisis360app/features/register/register.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';

import 'components/navbar/navbar.dart';
import 'core/services/auth_service.dart';
import 'features/login/login.dart';
import 'features/welcome/welcome.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Setup FCM listeners
  setupFCMListeners();
  // Check if user is already logged in
  final currentUser = FirebaseAuthService().currentUser;
  // Lock orientation to portrait only
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(Crisis360App(isLoggedIn: currentUser != null));
  });
}
void setupFCMListeners() {
  // 🔥 FOREGROUND
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
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
  });

  // 🔥 When user taps notification (Background / Closed)
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    if (message.data['type'] == "SAFETY_CHECK") {
      Get.defaultDialog(
        title: "Safety Confirmation",
        middleText: "Are you safe?",
        textConfirm: "Yes",
        textCancel: "No",
      );
    }
  });
}

class Crisis360App extends StatelessWidget {
  
  const Crisis360App({super.key, required this.isLoggedIn});
  final bool isLoggedIn;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Smart Stock',
      theme: ThemeData(
        fontFamily: 'Roboto',
      ),
      home: isLoggedIn ? const NavigationMenu() : const Welcome(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/navbar': (context) => const NavigationMenu(),
        '/login': (context) => const Login(),
        '/register':(context) => const RegisterPage(),
        // '/dashboard': (context) => const Dashboard(),
      },
    );
  }
}