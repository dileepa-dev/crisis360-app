import 'dart:convert';

import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ProfileController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  var userName = ''.obs;
  var email = ''.obs;
  var role = ''.obs;
  var isLoading = true.obs;
  final selectedProvince = ''.obs;
  final selectedDistrict = ''.obs;

  final provinces = [
    "Western",
    "Central",
    "Southern",
    "Northern",
    "Eastern",
    "North Western",
    "North Central",
    "Uva",
    "Sabaragamuwa"
  ];

  final Map<String, List<String>> districtsByProvince = {
    "Western": ["Colombo", "Gampaha", "Kalutara"],
    "Central": ["Kandy", "Matale", "Nuwara Eliya"],
    "Southern": ["Galle", "Matara", "Hambantota"],
    "Northern": ["Jaffna", "Kilinochchi", "Mannar", "Vavuniya", "Mullaitivu"],
    "Eastern": ["Trincomalee", "Batticaloa", "Ampara"],
    "North Western": ["Kurunegala", "Puttalam"],
    "North Central": ["Anuradhapura", "Polonnaruwa"],
    "Uva": ["Badulla", "Monaragala"],
    "Sabaragamuwa": ["Ratnapura", "Kegalle"],
  };

  @override
  void onInit() {
    super.onInit();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        return;
      }

      email.value = user.email ?? '';

      final doc =
      await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists) {
        userName.value = doc.data()?['name'] ?? 'User';
        role.value = doc.data()?['role'] ?? 'USER';
      } else {
        userName.value = 'User';
        role.value = 'USER';
      }
    } catch (e) {
      userName.value = 'Error';
      role.value = 'USER';
    } finally {
      isLoading.value = false;
    }
  }

  bool get isAdmin => role.value == "ADMIN";
  bool get isSuperAdmin => role.value == "SUPER_ADMIN";

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Get.deleteAll();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  Future<void> sendSafetyNotification(String province, String district,) async {
    try {
      isLoading.value = true;

      final response = await http.post(
        Uri.parse("http://172.20.10.2:8080/send-safety"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "province": province,
          "district": district,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to send notification");
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to send safety notification");
    } finally {
      isLoading.value = false;
    }
  }
}