import 'dart:convert';

import 'package:crisis360app/core/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../core/utils/api_endpoints.dart';

class SosController extends GetxController {
  final RxBool isSending = false.obs;
  final Rxn<Position> currentPosition = Rxn<Position>();
  final RxString userId = ''.obs;
  final RxString locationText = 'Fetching your location...'.obs;

  @override
  void onInit() {
    super.onInit();
    userId.value = FirebaseAuthService().currentUser?.uid ?? '';
  }

  Future<void> prepareSosPage() async {
    await fetchLocation(showSnackbarOnError: false);
  }

  Future<bool> fetchLocation({bool showSnackbarOnError = true}) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        locationText.value = 'Location service is disabled';
        if (showSnackbarOnError) {
          Get.snackbar(
            'Location Disabled',
            'Please enable location services.',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          locationText.value = 'Location permission denied';
          if (showSnackbarOnError) {
            Get.snackbar(
              'Permission Denied',
              'Location permission denied.',
              snackPosition: SnackPosition.BOTTOM,
            );
          }
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        locationText.value = 'Location permission permanently denied';
        if (showSnackbarOnError) {
          Get.snackbar(
            'Permission Denied',
            'Location permission is permanently denied. Please enable it in settings.',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
        return false;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      currentPosition.value = position;
      locationText.value =
      'Lat: ${position.latitude.toStringAsFixed(5)}, Lng: ${position.longitude.toStringAsFixed(5)}';

      return true;
    } catch (e) {
      locationText.value = 'Unable to fetch location';
      if (showSnackbarOnError) {
        Get.snackbar(
          'Error',
          'Failed to fetch location: $e',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      return false;
    }
  }

  Future<void> sendSos() async {
    if (isSending.value) return;

    if (userId.value.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'User is not logged in.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (currentPosition.value == null) {
      final gotLocation = await fetchLocation();
      if (!gotLocation) return;
    }

    isSending.value = true;

    try {
      final url = Uri.parse(ApiEndpoints.authEndpoints.sosRequest);

      final body = jsonEncode({
        "userId": userId.value,
        "latitude": currentPosition.value!.latitude,
        "longitude": currentPosition.value!.longitude,
      });

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.snackbar(
          "Success",
          "SOS sent successfully.",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green.shade600,
          colorText: Colors.white,
          margin: const EdgeInsets.all(12),
          duration: const Duration(seconds: 2),
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to send SOS. Status: ${response.statusCode}',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.shade600,
          colorText: Colors.white,
          margin: const EdgeInsets.all(12),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error sending SOS: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
      );
    } finally {
      isSending.value = false;
    }
  }
}