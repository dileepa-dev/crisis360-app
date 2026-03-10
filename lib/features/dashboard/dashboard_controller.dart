import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';

import '../../core/services/pushNotificationService.dart';
import '../../core/utils/api_endpoints.dart';
import '../../models/SafetyPoint.dart';
import '../../models/SosPoint.dart';
import '../notifications/notification_controller.dart';

class DashboardController extends GetxController {
  final RxString userName = ''.obs;
  final RxString district = ''.obs;
  final RxBool isLoading = true.obs;
  final userRole = ''.obs;

  late GoogleMapController mapController;

  final Location _location = Location();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PushNotificationService pushService = PushNotificationService();


  Rx<LatLng?> currentLocation = Rx<LatLng?>(null);
  RxSet<Marker> markers = <Marker>{}.obs;
  late NotificationsController notificationsController;
  @override
  Future<void> onInit() async {
    super.onInit();
    initializeDashboard();
    await FirebaseMessaging.instance.requestPermission();
    final token = await FirebaseMessaging.instance.getToken();
    print("FCM TOKEN: $token");
  }

  Future<void> initializeDashboard() async {
    await fetchUserData();

    initLocation();
    await loadSafetyPointsFromApi();
    await loadSosPointsFromApi();

    notificationsController = NotificationsController(
      district: district,
    );

    notificationsController.fetchNotifications();
  }

  /// 👤 Fetch user name and role
  Future<void> fetchUserData() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        userName.value = 'Guest';
        userRole.value = 'USER';
        return;
      }

      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists) {
        district.value = doc.data()?['district'] ?? "district";
        userName.value = doc.data()?['name'] ?? 'User';
        userRole.value = doc.data()?['role'] ?? 'USER';

        /// 🔥 Initialize push notification
        await pushService.initForUser(
          userId: user.uid,
          district: district.value,
        );
      } else {
        userName.value = 'User';
        userRole.value = 'USER';
      }
    } catch (e) {
      userName.value = 'Error';
      userRole.value = 'USER';
    } finally {
      isLoading.value = false;
    }
  }

  /// 📍 INIT LOCATION (FIXED)
  Future<void> initLocation() async {
    try {
      // 1️⃣ Check service
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) return;
      }

      // 2️⃣ Check permission
      PermissionStatus permission = await _location.hasPermission();
      if (permission == PermissionStatus.denied) {
        permission = await _location.requestPermission();
        if (permission != PermissionStatus.granted) return;
      }

      // 3️⃣ Get location
      final loc = await _location.getLocation();

      if (loc.latitude == null || loc.longitude == null) return;

      currentLocation.value = LatLng(
        loc.latitude!,
        loc.longitude!,
      );

      // 4️⃣ Add user marker
      markers.add(
        Marker(
          markerId: const MarkerId('me'),
          position: currentLocation.value!,
          infoWindow: const InfoWindow(title: 'You are here'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
    } catch (e) {
      print('Location error: $e');
    }
  }

  Future<void> loadSafetyPointsFromApi() async {
    try {
      final uri = Uri.parse(ApiEndpoints.authEndpoints.loadMapPoints);
      final res = await http.get(uri);

      if (res.statusCode != 200) {
        print("Failed to load safety points: ${res.statusCode} ${res.body}");
        return;
      }

      final List<dynamic> arr = jsonDecode(res.body);
      final points = arr.map((e) => SafetyPoint.fromJson(e)).toList();

      // ✅ clear old markers
      markers.clear();

      for (final p in points) {
        final hue = _riskHue(p.riskLevel);

        markers.add(
          Marker(
            markerId: MarkerId(p.id),
            position: LatLng(p.latitude, p.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(hue),
            infoWindow: InfoWindow(title: 'Risk: ${p.riskLevel}'),
          ),
        );
      }

      markers.refresh();
      print("Loaded markers: ${markers.length}");

    } catch (e) {
      print("Error loading safety points: $e");
    }
  }

  Future<void> loadSosPointsFromApi() async {
    try {
      final uri = Uri.parse(ApiEndpoints.authEndpoints.loadSosPoints);

      final res = await http.get(uri);

      if (res.statusCode != 200) {
        print("Failed to load SOS points: ${res.statusCode} ${res.body}");
        return;
      }

      final List<dynamic> arr = jsonDecode(res.body);
      final points = arr.map((e) => SosPoint.fromJson(e)).toList();

      for (final p in points) {
        // Optional: only show ACTIVE SOS
        // if (p.status.toUpperCase() != "ACTIVE") continue;

        final hue = _riskHue(p.riskLevel);

        markers.add(
          Marker(
            markerId: MarkerId("SOS_${p.id}"),
            position: LatLng(p.latitude, p.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(hue),
            infoWindow: InfoWindow(
              title: "SOS: ${p.riskLevel} (${p.status})",
              snippet: "User: ${p.userId}",
            ),
          ),
        );
      }

      markers.refresh();
      print("Loaded SOS markers: ${points.length}");
    } catch (e) {
      print("Error loading SOS points: $e");
    }
  }

  double _riskHue(String risk) {
    switch (risk.toUpperCase()) {
      case 'HIGH':
        return BitmapDescriptor.hueRed;
      case 'MEDIUM':
        return BitmapDescriptor.hueYellow;
      case 'LOW':
        return BitmapDescriptor.hueGreen;
      default:
        return BitmapDescriptor.hueAzure;
    }
  }

  /// ➕ Zoom in
  void zoomIn() {
    mapController.animateCamera(CameraUpdate.zoomIn());
  }

  /// ➖ Zoom out
  void zoomOut() {
    mapController.animateCamera(CameraUpdate.zoomOut());
  }
}
