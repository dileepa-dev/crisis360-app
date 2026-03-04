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
          appBar: AppBar(
            // toolbarHeight: 40,
            automaticallyImplyLeading: false,
            elevation: 0,
            centerTitle: true,
            backgroundColor: Colors.blue,
            title: Obx(
                  () => Text(
                'Hello, ${controller.userName.value}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// 🗺️ Google Map with border + controls
                  Expanded(
                    child: Obx(() {
                      final location = controller.currentLocation.value;

                      if (location == null) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      return Container(
                        child: ClipRRect(
                          child: Stack(
                            children: [
                              GoogleMap(
                                initialCameraPosition: CameraPosition(
                                  target: location, // ✅ no !
                                  zoom: 14,
                                ),
                                myLocationEnabled: true,
                                myLocationButtonEnabled: false,
                                zoomControlsEnabled: false,
                                compassEnabled: true,
                                buildingsEnabled: true,
                                markers: controller.markers.value,
                                onMapCreated: (GoogleMapController mapController) {
                                  controller.mapController = mapController;
                                },
                              ),

                              Positioned(
                                right: 12,
                                bottom: 12,
                                child: Column(
                                  children: [
                                    FloatingActionButton(
                                      heroTag: 'zoom_in',
                                      mini: true,
                                      onPressed: controller.zoomIn,
                                      child: const Icon(Icons.add),
                                    ),
                                    const SizedBox(height: 8),
                                    FloatingActionButton(
                                      heroTag: 'zoom_out',
                                      mini: true,
                                      onPressed: controller.zoomOut,
                                      child: const Icon(Icons.remove),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        )
    );
  }
}