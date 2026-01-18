import 'package:flutter/material.dart';

import 'features/welcome/welcome.dart';

void main() {
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
        // '/navbar': (context) => const NavigationMenu(),
        // '/login': (context) => const Login(),
        // '/dashboard': (context) => const Dashboard(),
        // '/profile': (context) => const Profile(),
        // '/products': (context) => const Products(),
        // '/suppliers': (context) => const Suppliers(),
        // '/add': (context) => const AddItems(),
      },
    );
  }
}