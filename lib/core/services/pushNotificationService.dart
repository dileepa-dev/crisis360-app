import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

class PushNotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initForUser({
    required String userId,
    required String district,
  }) async {
    await _requestPermission();
    await _saveInitialToken(userId);
    await _subscribeToDistrict(district);

    _messaging.onTokenRefresh.listen((newToken) async {
      await _sendTokenToBackend(userId, newToken);
    });
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _saveInitialToken(String userId) async {
    final token = await _messaging.getToken();
    if (token != null) {
      await _sendTokenToBackend(userId, token);
    }
  }

  Future<void> _sendTokenToBackend(String userId, String token) async {
    await http.post(
      Uri.parse('http://172.20.10.2:8080/user/save-token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'token': token,
      }),
    );
  }

  Future<void> _subscribeToDistrict(String district) async {
    final topic = 'district_${district.toLowerCase()}';
    await _messaging.subscribeToTopic(topic);
  }
}