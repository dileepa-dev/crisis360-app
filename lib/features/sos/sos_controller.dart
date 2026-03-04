import 'dart:convert';
import 'package:crisis360app/core/services/auth_service.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../core/utils/api_endpoints.dart';

class SosController extends GetxController {
  var isSending = false.obs;
  var currentPosition = Rxn<Position>();
  var userId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Load user ID on init
    userId.value = FirebaseAuthService().currentUser?.uid ?? '';
  }

  /// Get current location
  Future<bool> fetchLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar('Error', 'Location services are disabled.');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Get.snackbar('Error', 'Location permission denied.');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Get.snackbar(
          'Error',
          'Location permissions are permanently denied, please enable them in settings.');
      return false;
    }

    currentPosition.value =
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    return true;
  }

  /// Send SOS to backend
  Future<void> sendSos() async {
    if (currentPosition.value == null) {
      bool gotLocation = await fetchLocation();
      if (!gotLocation) return;
    }

    isSending.value = true;

    final url = Uri.parse(ApiEndpoints.authEndpoints.sosRequest);
    final body = jsonEncode({
      "userId": userId.value,
      "latitude": currentPosition.value!.latitude,
      "longitude": currentPosition.value!.longitude,
    });

    try {
      final response =
      await http.post(url, headers: {'Content-Type': 'application/json'}, body: body);

      if (response.statusCode == 200) {
        Get.snackbar('Success', 'SOS sent successfully!');
      } else {
        Get.snackbar('Error', 'Failed to send SOS. Status: ${response.statusCode}');
      }
    } catch (e) {
      Get.snackbar('Error', 'Error sending SOS: $e');
    } finally {
      isSending.value = false;
    }
  }
}
