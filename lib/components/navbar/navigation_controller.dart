import 'package:crisis360app/features/dashboard/dashboard.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../../features/sos/sos_page.dart';
import '../../features/notifications/notifications_page.dart';
import '../../features/profile/profile_page.dart';

class NavigationController extends GetxController {
  final RxInt selectedIndex = 0.obs;

  void changeIndex(int index) {
    selectedIndex.value = index;
  }

  final List<Widget> screens = const [
    Dashboard(),
    SosPage(),
    NotificationsPage(),
    ProfilePage(),
  ];
}