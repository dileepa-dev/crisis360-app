import 'package:crisis360app/features/dashboard/dashboard_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

class ProfileController extends GetxController {
  final DashboardController dashboardController = Get.find<DashboardController>();

  String get userName => dashboardController.userName.value;
  String get email => FirebaseAuth.instance.currentUser?.email ?? '';

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }
}
