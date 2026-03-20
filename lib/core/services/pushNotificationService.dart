import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../utils/api_endpoints.dart';

class PushNotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Stream<String>? _tokenRefreshStream;

  Future<void> initForUser({
    required String userId,
    required String district,
  }) async {
    if (kIsWeb || !Platform.isAndroid) {
      print("[PushService] Skipping push init on non-Android platform");
      return;
    }

    final safeUserId = _normalize(userId);
    final safeDistrict = _normalize(district);

    if (safeUserId == null) {
      print("[PushService] init skipped: userId is invalid");
      return;
    }

    if (safeDistrict == null) {
      print("[PushService] init skipped: district is invalid");
      return;
    }

    try {
      await _requestPermission();
      await _saveInitialToken(safeUserId);
      await _subscribeToDistrict(safeDistrict);

      _tokenRefreshStream ??= _messaging.onTokenRefresh;
      _tokenRefreshStream!.listen((newToken) async {
        try {
          print("[PushService] Token refreshed: $newToken");
          await _sendTokenToBackend(safeUserId, newToken);
        } catch (e) {
          print("[PushService] onTokenRefresh error: $e");
        }
      });
    } catch (e) {
      print("[PushService] initForUser error: $e");
    }
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print("[PushService] Permission: ${settings.authorizationStatus}");
  }

  Future<void> _saveInitialToken(String userId) async {
    final token = await _messaging.getToken();

    if (token == null || token.trim().isEmpty) {
      print("[PushService] Initial token is null or empty");
      return;
    }

    print("[PushService] Initial token: $token");
    await _sendTokenToBackend(userId, token.trim());
  }

  Future<void> _sendTokenToBackend(String userId, String token) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.authEndpoints.saveToken),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'token': token,
      }),
    );

    print("[PushService] save-token status: ${response.statusCode}");
    print("[PushService] save-token body: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception(
        "Failed to save token: ${response.statusCode} ${response.body}",
      );
    }
  }

  Future<void> _subscribeToDistrict(String district) async {
    final topic = 'district_${district.toLowerCase().replaceAll(' ', '_')}';

    await _messaging.subscribeToTopic(topic);
    print("[PushService] Subscribed to topic: $topic");
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