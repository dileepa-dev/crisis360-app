import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';

import '../../core/services/notification_service.dart';
import '../../core/services/pushNotificationService.dart';
import '../../core/utils/api_endpoints.dart';
import '../../models/SafetyPoint.dart';
import '../../models/SosPoint.dart';
import '../notifications/notification_controller.dart';

class DashboardController extends GetxController {
  final RxString userName = ''.obs;
  final RxString district = ''.obs;
  final RxString province = ''.obs;
  final RxBool isLoading = true.obs;
  final RxBool isRefreshing = false.obs;
  final RxString userRole = ''.obs;

  late GoogleMapController mapController;

  final Location _location = Location();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PushNotificationService pushService = PushNotificationService();

  Rx<LatLng?> currentLocation = Rx<LatLng?>(null);
  RxSet<Marker> markers = <Marker>{}.obs;

  NotificationsController? notificationsController;

  bool _isSavingToken = false;

  @override
  Future<void> onInit() async {
    super.onInit();
    await initializeDashboard();
  }

  Future<void> initializeDashboard() async {
    try {
      await fetchUserData();
      await _registerFcmTokenIfPossible();
      await initLocation();
      await loadSafetyPointsFromApi();
      await loadSosPointsFromApi();

      notificationsController = NotificationsController(
        district: district,
      );

      if (district.value.isNotEmpty) {
        await fetchNotifications(district.value);
      } else {
        print("[Dashboard] Notifications skipped: district is empty");
      }
    } catch (e) {
      print("[Dashboard] initializeDashboard error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshMapPoints() async {
    if (isRefreshing.value) return;

    try {
      isRefreshing.value = true;

      await initLocation();
      await loadSafetyPointsFromApi();
      await loadSosPointsFromApi();

      if (district.value.isNotEmpty) {
        await fetchNotifications(district.value);
      }

      Get.snackbar(
        "Success",
        "Map points refreshed successfully",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      print("[Dashboard] refreshMapPoints error: $e");
      Get.snackbar(
        "Error",
        "Failed to refresh map points",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
      );
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<void> fetchUserData() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        userName.value = 'Guest';
        userRole.value = 'USER';
        province.value = '';
        district.value = '';
        print("[Dashboard] No logged user found");
        return;
      }

      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists || doc.data() == null) {
        userName.value = 'User';
        userRole.value = 'USER';
        province.value = '';
        district.value = '';
        print("[Dashboard] User document not found");
        return;
      }

      final data = doc.data()!;

      userName.value = _normalize(data['name']) ?? 'User';
      userRole.value = _normalize(data['role']) ?? 'USER';
      province.value = _normalize(data['province']) ?? '';
      district.value = _normalize(data['district']) ?? '';

      print("[Dashboard] userName=${userName.value}");
      print("[Dashboard] role=${userRole.value}");
      print("[Dashboard] province=${province.value}");
      print("[Dashboard] district=${district.value}");

      if (district.value.isNotEmpty) {
        await pushService.initForUser(
          userId: user.uid,
          district: district.value,
        );
      } else {
        print("[Dashboard] pushService skipped: district is invalid");
      }
    } catch (e) {
      userName.value = 'Error';
      userRole.value = 'USER';
      province.value = '';
      district.value = '';
      print("[Dashboard] fetchUserData error: $e");
    }
  }

  Future<void> _registerFcmTokenIfPossible() async {
    if (_isSavingToken) return;
    _isSavingToken = true;

    try {
      final user = _auth.currentUser;
      if (user == null) {
        print("[Dashboard] save-token skipped: user is null");
        return;
      }

      final safeProvince = _normalize(province.value);
      final safeDistrict = _normalize(district.value);

      if (safeProvince == null || safeDistrict == null) {
        print("[Dashboard] save-token skipped: province/district invalid");
        print("[Dashboard] province=${province.value}, district=${district.value}");
        return;
      }

      final token = await NotificationService.instance.getAndroidFcmTokenOrNull();

      if (token == null || token.trim().isEmpty) {
        print("[Dashboard] save-token skipped: non-Android platform or FCM token unavailable");
        return;
      }

      final body = {
        "token": token.trim(),
        "province": safeProvince,
        "district": safeDistrict,
      };

      print("[Dashboard] Sending save-token request: $body");

      final response = await http.post(
        Uri.parse(ApiEndpoints.authEndpoints.saveToken),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      print("[Dashboard] save-token response code: ${response.statusCode}");
      print("[Dashboard] save-token response body: ${response.body}");

      if (response.statusCode != 200) {
        print("[Dashboard] save-token failed");
      }
    } catch (e) {
      print("[Dashboard] _registerFcmTokenIfPossible error: $e");
    } finally {
      _isSavingToken = false;
    }
  }

  String? _normalize(dynamic value) {
    if (value == null) return null;

    final text = value.toString().trim();

    if (text.isEmpty) return null;
    if (text.toLowerCase() == 'null') return null;
    if (text.toLowerCase() == 'undefined') return null;

    return text;
  }

  Future<void> initLocation() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) return;
      }

      PermissionStatus permission = await _location.hasPermission();
      if (permission == PermissionStatus.denied) {
        permission = await _location.requestPermission();
        if (permission != PermissionStatus.granted) return;
      }

      final loc = await _location.getLocation();

      if (loc.latitude == null || loc.longitude == null) return;

      currentLocation.value = LatLng(loc.latitude!, loc.longitude!);

      markers.removeWhere((m) => m.markerId.value == 'me');

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

      markers.refresh();
    } catch (e) {
      print('[Dashboard] Location error: $e');
    }
  }

  Future<void> loadSafetyPointsFromApi() async {
    try {
      final uri = Uri.parse(ApiEndpoints.authEndpoints.loadMapPoints);
      final res = await http.get(uri);

      if (res.statusCode != 200) {
        print("[Dashboard] Failed to load safety points: ${res.statusCode} ${res.body}");
        return;
      }

      final List<dynamic> arr = jsonDecode(res.body);
      final points = arr.map((e) => SafetyPoint.fromJson(e)).toList();

      markers.removeWhere((m) => m.markerId.value != 'me');

      for (final p in points) {
        final hue = _riskHue(p.riskLevel);

        markers.add(
          Marker(
            markerId: MarkerId("SAFE_${p.id}"),
            position: LatLng(p.latitude, p.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(hue),
            infoWindow: InfoWindow(
              title: 'Risk: ${p.riskLevel}',
              snippet: 'Safety point',
            ),
          ),
        );
      }

      markers.refresh();
      print("[Dashboard] Loaded safety markers: ${points.length}");
    } catch (e) {
      print("[Dashboard] Error loading safety points: $e");
    }
  }

  Future<void> loadSosPointsFromApi() async {
    try {
      final uri = Uri.parse(ApiEndpoints.authEndpoints.loadSosPoints);
      final res = await http.get(uri);

      if (res.statusCode != 200) {
        print("[Dashboard] Failed to load SOS points: ${res.statusCode} ${res.body}");
        return;
      }

      final List<dynamic> arr = jsonDecode(res.body);
      final points = arr.map((e) => SosPoint.fromJson(e)).toList();

      for (final p in points) {
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
      print("[Dashboard] Loaded SOS markers: ${points.length}");
    } catch (e) {
      print("[Dashboard] Error loading SOS points: $e");
    }
  }

  Future<void> fetchNotifications(String districtName) async {
    try {
      if (districtName.trim().isEmpty) {
        print("[Dashboard] fetchNotifications skipped: district is empty");
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiEndpoints.authEndpoints.getNotifications}/$districtName'),
      );

      print("[Dashboard] District: $districtName");
      print("[Dashboard] Notifications status: ${response.statusCode}");
      print("[Dashboard] Notifications body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final notifications =
        data.map((e) => Map<String, dynamic>.from(e)).toList();

        print("[Dashboard] Notifications loaded successfully: ${notifications.length}");
      } else {
        print("[Dashboard] Failed to load notifications: ${response.statusCode}");
      }
    } catch (e) {
      print("[Dashboard] Error fetching notifications: $e");
    }
  }

  double _riskHue(String risk) {
    switch (risk.toUpperCase()) {
      case 'HIGH':
        return BitmapDescriptor.hueRed;
      case 'MEDIUM':
        return BitmapDescriptor.hueOrange;
      case 'LOW':
        return BitmapDescriptor.hueGreen;
      default:
        return BitmapDescriptor.hueAzure;
    }
  }

  Future<void> goToMyLocation() async {
    if (currentLocation.value == null) {
      await initLocation();
    }

    final location = currentLocation.value;
    if (location == null) return;

    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: location, zoom: 15),
      ),
    );
  }

  void zoomIn() {
    mapController.animateCamera(CameraUpdate.zoomIn());
  }

  void zoomOut() {
    mapController.animateCamera(CameraUpdate.zoomOut());
  }

  @override
  void onClose() {
    notificationsController?.dispose();
    super.onClose();
  }
}