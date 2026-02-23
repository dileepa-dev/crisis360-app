import 'package:crisis360app/features/dashboard/dashboard.dart';
import 'package:crisis360app/features/register/register.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        // '/profile': (context) => const Profile(),
        // '/products': (context) => const Products(),
        // '/suppliers': (context) => const Suppliers(),
        // '/add': (context) => const AddItems(),
      },
    );
  }
}