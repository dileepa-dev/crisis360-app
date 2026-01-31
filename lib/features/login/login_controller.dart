import 'dart:convert';
import 'package:crisis360app/core/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/utils/api_endpoints.dart';

class LoginController {
  String? errorMessage;

  Future<void> login(String username, String password) async {
    try {
      await firebaseAuthService.value.signInWithEmailAndPassword(username, password);
    } on FirebaseAuthException catch (e) {
      errorMessage = e.message ?? "Error when logging!";
    }
  }
}