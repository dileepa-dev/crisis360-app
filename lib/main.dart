import 'package:crisis360app/features/register/register.dart';
import 'package:flutter/material.dart';

import 'components/navbar/navbar.dart';
import 'features/login/login.dart';
import 'features/welcome/welcome.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const Crisis360App());
}

class Crisis360App extends StatelessWidget {
  const Crisis360App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Stock',
      theme: ThemeData(
        fontFamily: 'Roboto',
      ),
      home: const Welcome(),
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