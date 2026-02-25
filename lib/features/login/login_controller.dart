import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crisis360app/core/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

import '../../core/utils/api_endpoints.dart';

class LoginController {

  String? errorMessage;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> login(String email, String password) async {
    try {

      // 🔹 1. Login
      UserCredential credential =
      (await firebaseAuthService.value
          .signInWithEmailAndPassword(email, password)) as UserCredential;

      String uid = credential.user!.uid;

      // 🔹 2. Get user province + district from Firestore
      DocumentSnapshot userDoc =
      await _firestore.collection('users').doc(uid).get();

      String province = userDoc['province'];
      String district = userDoc['district'];

      // 🔹 3. Register FCM token to backend
      await registerFcmToken(province, district);

    } on FirebaseAuthException catch (e) {
      errorMessage = e.message ?? "Error when logging!";
    } catch (e) {
      errorMessage = "Unexpected error occurred";
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