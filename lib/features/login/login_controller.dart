import 'dart:convert';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

import '../../core/utils/api_endpoints.dart';

class LoginController {
  String? errorMessage;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> login(String email, String password) async {
    errorMessage = null;

    try {
      print("🟡 [LOGIN] Step 1: FirebaseAuth signIn start");

      final credential = await _auth
          .signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      )
          .timeout(const Duration(seconds: 20));

      final uid = credential.user?.uid;
      if (uid == null) {
        throw Exception("Login succeeded but uid is null");
      }

      print("🟢 [LOGIN] Step 1 OK: uid=$uid");
      print("🟡 [LOGIN] Step 2: Firestore users/$uid get start");

      final userDoc = await _firestore
          .collection('users')
          .doc(uid)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 15));

      if (!userDoc.exists) {
        throw Exception("User document not found in Firestore: users/$uid");
      }

      final data = userDoc.data();
      if (data == null) {
        throw Exception("User document has no data: users/$uid");
      }

      final province = _normalize(data['province']);
      final district = _normalize(data['district']);

      if (province == null || district == null) {
        throw Exception("Province or district is missing/invalid in users/$uid");
      }

      print("🟢 [LOGIN] Step 2 OK: province=$province district=$district");
      print("🟡 [LOGIN] Step 3: registerFcmToken start");

      await registerFcmToken(province, district)
          .timeout(const Duration(seconds: 15));

      print("🟢 [LOGIN] Step 3 OK: token registered");
    } on TimeoutException catch (e) {
      errorMessage = "Request timed out. Check internet connection.";
      print("🔴 [LOGIN] TIMEOUT: $e");
    } on FirebaseAuthException catch (e) {
      errorMessage = e.message ?? "FirebaseAuth error: ${e.code}";
      print("🔴 [LOGIN] FirebaseAuthException: code=${e.code} msg=${e.message}");
    } on FirebaseException catch (e) {
      errorMessage = e.message ?? "Firebase error: ${e.code}";
      print("🔴 [LOGIN] FirebaseException: code=${e.code} msg=${e.message}");
    } catch (e, st) {
      errorMessage = "Unexpected error: $e";
      print("🔴 [LOGIN] Unknown error: $e");
      print(st);
    }
  }

  Future<void> registerFcmToken(String province, String district) async {
    final normalizedProvince = _normalize(province);
    final normalizedDistrict = _normalize(district);

    if (normalizedProvince == null || normalizedDistrict == null) {
      throw Exception("Province or district is invalid while registering token");
    }

    final token = await FirebaseMessaging.instance.getToken();

    if (token == null || token.trim().isEmpty) {
      throw Exception("FCM token is null or empty");
    }

    print("🟡 [FCM] Saving token to backend");
    print("🟡 [FCM] province=$normalizedProvince district=$normalizedDistrict");

    final response = await http.post(
      Uri.parse(ApiEndpoints.authEndpoints.saveToken),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "token": token.trim(),
        "province": normalizedProvince,
        "district": normalizedDistrict,
      }),
    );

    print("🟡 [FCM] save-token response: ${response.statusCode}");
    print("🟡 [FCM] save-token body: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception("Failed to save token: ${response.statusCode} ${response.body}");
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
}