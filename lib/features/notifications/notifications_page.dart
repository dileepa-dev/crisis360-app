import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'notification_controller.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';

class NotificationsPage extends StatelessWidget {
  final RxString district;

  const NotificationsPage({super.key, required this.district});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<NotificationsController>(
      create: (_) => NotificationsController(district: district),
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: const Text("Emergency Notifications"),
          centerTitle: true,
          elevation: 0,
        ),
        body: Consumer<NotificationsController>(
          builder: (context, controller, _) {
            // 🔹 Show spinner while loading
            if (controller.isLoading && controller.notifications.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            // 🔹 Show message if no notifications
            if (controller.notifications.isEmpty) {
              return const Center(
                child: Text(
                  "No emergency notifications",
                  style: TextStyle(fontSize: 16),
                ),
              );
            }

            // 🔹 Show the list of notifications
            return RefreshIndicator(
              onRefresh: controller.fetchNotifications,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: controller.notifications.length,
                itemBuilder: (context, index) {
                  final notif = controller.notifications[index];

                  return GestureDetector(
                    onTap: () {
                      controller.showSafetyPopup(context, notif);
                    },
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: const CircleAvatar(
                          backgroundColor: Colors.red,
                          child: Icon(Icons.warning, color: Colors.white),
                        ),
                        title: Text(
                          notif['type'] ?? 'Emergency Alert',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          notif['timestamp'] ?? '',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}