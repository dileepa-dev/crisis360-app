
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../features/dashboard/dashboard.dart';

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
              top: BorderSide(
                color: Colors.black26,
                width: 1.0,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: NavigationBar(
            backgroundColor: const Color(0xFFFFFFFF),
            height: 80.0,
            elevation: 0.0,
            selectedIndex: controller.selectedIndex.value,
            onDestinationSelected: (index) => controller.selectedIndex.value = index,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.rocket_launch),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.shopping_cart),
                label: 'Products',
              ),
              NavigationDestination(
                icon: Icon(Icons.people),
                label: 'Suppliers',
              ),
              NavigationDestination(
                icon: Icon(Icons.supervised_user_circle_sharp),
                label: 'Users',
              ),
              NavigationDestination(
                icon: Icon(Icons.add_circle),
                label: 'Add',
              ),
            ],
          ),
        ),
      ),
      body: Obx(() => controller.screens[controller.selectedIndex.value]),
    );
  }
}

class NavigationController extends GetxController {
  final Rx<int> selectedIndex = 0.obs;

  final screens = [
    const Dashboard(),
    // const Products(),
    // const Suppliers(),
    // const UserManagementPage(),
    // const AddItems(),
  ];
}
