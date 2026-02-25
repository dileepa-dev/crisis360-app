import 'dart:async';
import 'package:crisis360app/core/utils/api_endpoints.dart';
import 'package:flutter/material.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationsController extends ChangeNotifier {
  final RxString district;
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = false;
  Timer? _timer;

  NotificationsController({required this.district}) {
    fetchNotifications();

    // Refresh notifications every 1 minute
    _timer = Timer.periodic(Duration(seconds: 10), (_) {
      fetchNotifications();
    });
  }

  Future<void> fetchNotifications() async {
    isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.authEndpoints.getNotifications}/$district'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        notifications = data.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        print("Failed to load notifications");
      }
    } catch (e) {
      print("Error fetching notifications: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Cancel the timer when the controller is disposed
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}