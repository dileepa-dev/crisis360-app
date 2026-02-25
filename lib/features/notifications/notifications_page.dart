import 'package:flutter/material.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:provider/provider.dart';
import 'notification_controller.dart';

class NotificationsPage extends StatelessWidget {
  final RxString district;

  const NotificationsPage({super.key, required this.district});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NotificationsController(district: district),
      child: Scaffold(
        appBar: AppBar(title: const Text("Notifications")),
        body: Consumer<NotificationsController>(
          builder: (context, controller, _) {
            if (controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.notifications.isEmpty) {
              return const Center(child: Text("No notifications found."));
            }

            return ListView.builder(
              itemCount: controller.notifications.length,
              itemBuilder: (context, index) {
                final notif = controller.notifications[index];
                return ListTile(
                  title: Text(notif['type'] ?? 'Notification'),
                  subtitle: Text(notif['timestamp'] ?? ''),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
