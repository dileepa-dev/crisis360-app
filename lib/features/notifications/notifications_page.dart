import 'package:flutter/material.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:provider/provider.dart';
import 'notification_controller.dart';

class NotificationsPage extends StatelessWidget {
  final RxString district;

  const NotificationsPage({super.key, required this.district});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<NotificationsController>(
      create: (_) => NotificationsController(district: district),
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        body: SafeArea(
          top: false,
          child: Consumer<NotificationsController>(
            builder: (context, controller, _) {
              return Stack(
                children: [
                  Column(
                    children: [
                      _buildHeader(controller),
                      Expanded(
                        child: controller.isLoading && controller.notifications.isEmpty
                            ? const Center(
                          child: CircularProgressIndicator(),
                        )
                            : RefreshIndicator(
                          onRefresh: controller.fetchNotifications,
                          child: controller.notifications.isEmpty
                              ? _buildEmptyState(controller)
                              : _buildNotificationList(controller, context),
                        ),
                      ),
                    ],
                  ),

                  if (controller.isRefreshingOverlay)
                    Container(
                      color: Colors.black.withOpacity(0.18),
                      child: const Center(
                        child: Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(22)),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 20,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 14),
                                Text(
                                  "Refreshing notifications...",
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(NotificationsController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFF36F63), // main
            Color(0xFFFFB74D) // light
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(30),
        ),
      ),
      child: Consumer<NotificationsController>(
        builder: (context, c, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.notifications_active, color: Colors.white, size: 28),
                        SizedBox(width: 10),
                        Text(
                          "Emergency Alerts",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: "Refresh",
                    onPressed: c.isLoading ? null : c.refreshNotificationsManually,
                    icon: c.isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(Icons.refresh, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                district.value.isEmpty
                    ? "Stay updated with real-time emergency notifications."
                    : "Live alerts for ${district.value}. Tap any alert to submit your safety confirmation.",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.92),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _HeaderStatCard(
                      icon: Icons.campaign_outlined,
                      title: "Alerts",
                      value: "${c.notifications.length}",
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _HeaderStatCard(
                      icon: Icons.location_on_outlined,
                      title: "District",
                      value: district.value.isEmpty ? "N/A" : district.value,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(NotificationsController controller) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.grey.withOpacity(0.10),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  size: 42,
                  color: Color(0xFFFF9800),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                "No emergency notifications",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "You don’t have any active alerts right now. Pull down or tap refresh to check again.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: controller.refreshNotificationsManually,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFF9800),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text("Refresh Notifications"),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationList(
      NotificationsController controller,
      BuildContext context,
      ) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFFF3F3),
                Color(0xFFFFFAFA),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.red.withOpacity(0.12),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF9800)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Tap any notification to open the safety confirmation form.",
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(controller.notifications.length, (index) {
          final notif = controller.notifications[index];

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => controller.showSafetyPopup(context, notif),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.10),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF9800),Color(0xFFF1725F)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (notif['type'] ?? 'Emergency Alert').toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              (notif['message'] ?? 'Tap to view and submit safety confirmation.')
                                  .toString(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    controller.formatNotificationDate(notif['timestamp']),
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: Colors.grey.shade500,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _HeaderStatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _HeaderStatCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.14),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}