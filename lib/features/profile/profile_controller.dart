import 'dart:convert';

import 'package:crisis360app/core/utils/api_endpoints.dart';
import 'package:firebase_core/firebase_core.dart';
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

  final roles = ["ADMIN"];

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
        Uri.parse(ApiEndpoints.authEndpoints.sendSafety),
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

  Future<void> createAdminFirestoreUser({
    required String uid,
    required String name,
    required String email,
    required String province,
    required String district,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'name': name,
      'email': email,
      'province': province,
      'district': district,
      'createdAt': FieldValue.serverTimestamp(),
      'role': 'ADMIN',
    });
  }

  Future<void> createAdminUser({
    required String name,
    required String email,
    required String password,
    required String province,
    required String district,
  }) async {
    FirebaseApp? secondaryApp;

    try {
      isLoading.value = true;

      print("STEP 1: Initializing secondary app");
      secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      print("STEP 2: Creating auth user");
      final UserCredential userCredential =
      await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? newUser = userCredential.user;

      if (newUser == null) {
        throw Exception("Admin creation failed: user is null");
      }

      print("STEP 3: Auth user created with uid = ${newUser.uid}");

      print("STEP 4: Saving user to Firestore");
      await createAdminFirestoreUser(
        uid: newUser.uid,
        name: name,
        email: email,
        province: province,
        district: district,
      );

      print("STEP 5: Firestore save success");

      Get.snackbar(
        "Success",
        "Admin user created successfully",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      await secondaryAuth.signOut();
    } on FirebaseAuthException catch (e) {
      print("FIREBASE AUTH ERROR: ${e.code} - ${e.message}");
      Get.snackbar(
        "Error",
        e.message ?? "Failed to create admin user",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } on FirebaseException catch (e) {
      print("FIRESTORE ERROR: ${e.code} - ${e.message}");
      Get.snackbar(
        "Error",
        e.message ?? "Firestore write failed",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      print("GENERAL ERROR: $e");
      Get.snackbar(
        "Error",
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (secondaryApp != null) {
        await secondaryApp.delete();
      }
      isLoading.value = false;
    }
  }
}