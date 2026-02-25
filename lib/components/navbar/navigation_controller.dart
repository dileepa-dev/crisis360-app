import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crisis360app/features/dashboard/dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../../features/sos/sos_page.dart';
import '../../features/notifications/notifications_page.dart';
import '../../features/profile/profile_page.dart';

class NavigationController extends GetxController {
  final RxInt selectedIndex = 0.obs;
  final RxBool isLoading = true.obs;
  final RxString district = ''.obs;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void onInit() {
    super.onInit();
    loadUserDistrict();
  }

  void changeIndex(int index) {
    selectedIndex.value = index;
  }

  late final List<Widget> screens = [
    const Dashboard(),
    const SosPage(),
    NotificationsPage(district: district),
    const ProfilePage(),
  ];

  Future <void> loadUserDistrict() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        district.value = 'district';
        return;
      }

      final doc =
          await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists) {
        district.value = doc.data()?['district'] ?? 'district';
      } else {
        district.value = 'district';
      }
    } catch (e) {
      district.value = 'district';
    } finally {
      isLoading.value = false;
    }
  }
}