import 'dart:convert';
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

      final credential = await FirebaseAuth.instance
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

      final userDoc = await FirebaseFirestore.instance
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

      final province = (data['province'] ?? '').toString();
      final district = (data['district'] ?? '').toString();

      if (province.isEmpty || district.isEmpty) {
        throw Exception("province/district missing in users/$uid");
      }

      print("🟢 [LOGIN] Step 2 OK: province=$province district=$district");
      print("🟡 [LOGIN] Step 3: registerFcmToken start");

      await registerFcmToken(province, district)
          .timeout(const Duration(seconds: 15));

      print("🟢 [LOGIN] Step 3 OK: token registered");
    // } on TimeoutException catch (e) {
    //   errorMessage = "Request timed out. Check emulator internet / Firebase.";
    //   print("🔴 [LOGIN] TIMEOUT: $e");
    } on FirebaseAuthException catch (e) {
      errorMessage = e.message ?? "FirebaseAuth error: ${e.code}";
      print("🔴 [LOGIN] FirebaseAuthException: code=${e.code} msg=${e.message}");
    } on FirebaseException catch (e) {
      // Firestore errors come here too
      errorMessage = e.message ?? "Firebase error: ${e.code}";
      print("🔴 [LOGIN] FirebaseException: code=${e.code} msg=${e.message}");
    } catch (e, st) {
      errorMessage = "Unexpected error: $e";
      print("🔴 [LOGIN] Unknown error: $e");
      print(st);
    }
  }

  Future<void> registerFcmToken(
      String province,
      String district,
      ) async {

    String? token = await FirebaseMessaging.instance.getToken();

    if (token == null) return;

    await http.post(
      Uri.parse(ApiEndpoints.authEndpoints.saveToken),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "token": token,
        "province": province,
        "district": district,
      }),
    );
  }
}