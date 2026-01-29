import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/utils/api_endpoints.dart';

class LoginController {
  String? status;
  String? message;
  int? statusCode;
  String? error;

  Future<void> login(String username, String password) async {
    final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.authEndpoints.loginEmail}';
    final response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'username': username,
        'password': password,
      }),
    );

    final Map<String, dynamic> responseBody = jsonDecode(response.body);

    if (kDebugMode) {
      print('Username: $username');
      print('Password: $password');
      print('Response body: $responseBody');
    }

    status = responseBody['status'];
    message = responseBody['message'];
    final payload = responseBody['payload'];
    statusCode = payload['statusCode'];
    error = payload['error'];

    if (kDebugMode) {
      print('Status: $status');
      print('Message: $message');
      print('Status Code: $statusCode');
      print('Error: $error');
    }

    if (status == 'S0000' && statusCode == 200) {
      if (kDebugMode) {
        print('Login success: $message');
      }
    } else {
      throw Exception('Failed to log in: $error');
    }
  }
}