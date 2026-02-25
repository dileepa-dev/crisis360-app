import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'navigation_controller.dart';

class NavigationMenu extends StatelessWidget {

  const NavigationMenu({super.key});


  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NavigationController());

    return Scaffold(
      bottomNavigationBar: Obx(
            () => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(
              top: BorderSide(color: Colors.black26, width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                blurRadius: 5,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: NavigationBar(
            height: 80,
            backgroundColor: Colors.white,
            elevation: 0,
            selectedIndex: controller.selectedIndex.value,
            onDestinationSelected: controller.changeIndex,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.public),
                label: 'Map',
              ),
              NavigationDestination(
                icon: Icon(Icons.sos),
                label: 'SOS',
              ),
              NavigationDestination(
                icon: Icon(Icons.notifications_active),
                label: 'Notifications',
              ),
              NavigationDestination(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),

      /// ✅ FIX IS HERE
      body: Obx(
            () => IndexedStack(
          index: controller.selectedIndex.value,
          children: controller.screens,
        ),
      ),
    );
  }
}

// class NavigationController extends GetxController {
//   final RxInt selectedIndex = 0.obs;
//   @override
//   void onInit() {
//     selectedIndex.value = 0; // ensure dashboard is selected by default
//     super.onInit();
//   }
//   void changeIndex(int index) {
//     selectedIndex.value = index;
//   }
//
//   final List<Widget> screens = const [
//     Dashboard(),
//     SosPage(),
//     NotificationsPage(),
//     ProfilePage(),
//   ];
// }