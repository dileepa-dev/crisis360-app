import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

class DashboardController {
  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
          (route) => false,
    );
  }
}