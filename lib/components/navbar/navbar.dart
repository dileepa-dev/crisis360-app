import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'navigation_controller.dart';

class NavigationMenu extends StatelessWidget {
  const NavigationMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NavigationController());

    final items = [
      _NavItem(
        label: 'Map',
        icon: Icons.public_outlined,
        activeIcon: Icons.public,
        color: const Color(0xFF1976D2),
      ),
      _NavItem(
        label: 'SOS',
        icon: Icons.sos_outlined,
        activeIcon: Icons.sos,
        color: const Color(0xFFD32F2F),
      ),
      _NavItem(
        label: 'Alerts',
        icon: Icons.notifications_none,
        activeIcon: Icons.notifications_active,
        color: const Color(0xFFEF6C00),
      ),
      _NavItem(
        label: 'Profile',
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        color: const Color(0xFF00897B),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: Obx(
            () => IndexedStack(
          index: controller.selectedIndex.value,
          children: controller.screens,
        ),
      ),
      bottomNavigationBar: Obx(
            () => Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 18,
                offset: const Offset(0, -4),
              ),
            ],
            border: Border(
              top: BorderSide(
                color: Colors.grey.withOpacity(0.12),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: List.generate(items.length, (index) {
                final item = items[index];
                final isSelected = controller.selectedIndex.value == index;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => controller.changeIndex(index),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? item.color.withOpacity(0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSelected ? item.activeIcon : item.icon,
                            color: isSelected ? item.color : Colors.grey.shade600,
                            size: isSelected ? 26 : 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? item.color : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Color color;

  _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.color,
  });
}