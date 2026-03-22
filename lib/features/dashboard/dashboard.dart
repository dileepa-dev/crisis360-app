import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dashboard_controller.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DashboardController());

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FB),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          backgroundColor: Colors.blue,
          centerTitle: false,
          title: Obx(
                () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${controller.userName.value}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                Text(
                  controller.district.value.isEmpty
                      ? 'Stay safe'
                      : '${controller.district.value}, ${controller.province.value}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Obx(
                  () => IconButton(
                tooltip: 'Refresh points',
                onPressed: controller.isRefreshing.value
                    ? null
                    : controller.refreshMapPoints,
                icon: controller.isRefreshing.value
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
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: Obx(() {
            final location = controller.currentLocation.value;

            return Column(
              children: [
                _buildTopStatusCard(controller),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: location == null
                        ? const Center(child: CircularProgressIndicator())
                        : Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            // ✅ Modern subtle border
                            border: Border.all(
                              color: const Color(0xFF1E85E0).withOpacity(0.65),
                              width: 1.7,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: location,
                                zoom: 14,
                              ),
                              myLocationEnabled: true,
                              myLocationButtonEnabled: false,
                              zoomControlsEnabled: false,
                              compassEnabled: true,
                              buildingsEnabled: true,
                              mapToolbarEnabled: false,
                              markers: controller.markers.toSet(),
                              onMapCreated:
                                  (GoogleMapController mapController) {
                                controller.mapController = mapController;
                              },
                            ),
                          ),
                        ),

                        /// top legend
                        Positioned(
                          top: 14,
                          left: 14,
                          right: 90,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Wrap(
                              spacing: 15,
                              runSpacing: 5,
                              children: const [
                                _LegendItem(
                                  color: Colors.red,
                                  label: 'High',
                                ),
                                _LegendItem(
                                  color: Colors.orange,
                                  label: 'Medium',
                                ),
                                _LegendItem(
                                  color: Colors.green,
                                  label: 'Low',
                                ),
                                _LegendItem(
                                  color: Colors.blue,
                                  label: 'You',
                                ),
                              ],
                            ),
                          ),
                        ),

                        /// map buttons
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: Column(
                            children: [
                              _MapActionButton(
                                heroTag: 'refresh_points',
                                icon: Icons.refresh,
                                onTap: controller.refreshMapPoints,
                              ),
                              const SizedBox(height: 8),
                              _MapActionButton(
                                heroTag: 'my_location',
                                icon: Icons.my_location,
                                onTap: controller.goToMyLocation,
                              ),
                              const SizedBox(height: 8),
                              _MapActionButton(
                                heroTag: 'zoom_in',
                                icon: Icons.add,
                                onTap: controller.zoomIn,
                              ),
                              const SizedBox(height: 8),
                              _MapActionButton(
                                heroTag: 'zoom_out',
                                icon: Icons.remove,
                                onTap: controller.zoomOut,
                              ),
                            ],
                          ),
                        ),

                        /// loading overlay
                        Obx(() {
                          if (!controller.isRefreshing.value) {
                            return const SizedBox.shrink();
                          }

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Center(
                              child: Card(
                                elevation: 8,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(height: 12),
                                      Text("Refreshing map points..."),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTopStatusCard(DashboardController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Obx(
              () => Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Crisis360 Live Map",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Safety + SOS markers in your area",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  "${controller.markers.length} markers",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapActionButton extends StatelessWidget {
  final String heroTag;
  final IconData icon;
  final VoidCallback onTap;

  const _MapActionButton({
    required this.heroTag,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFA8CFF8),
      borderRadius: BorderRadius.circular(12),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            size: 18,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}