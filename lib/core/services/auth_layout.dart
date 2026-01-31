import 'package:crisis360app/core/services/auth_service.dart';
import 'package:crisis360app/features/welcome/welcome.dart';
import 'package:flutter/material.dart';

class AuthLayout extends StatelessWidget {
  final Widget? pageIfNotConnected;

  const AuthLayout({
    super.key,
    this.pageIfNotConnected,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<FirebaseAuthService>(
      valueListenable: firebaseAuthService,
      builder: (context, authService, _) {
        return StreamBuilder(
          stream: authService.authStateChanges,
          builder: (context, snapshot) {
            // 1️⃣ Loading
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            // 2️⃣ User logged in
            if (snapshot.hasData) {
              return const Welcome();
            }

            // 3️⃣ User not logged in
            return pageIfNotConnected ?? const Welcome();
          },
        );
      },
    );
  }
}
