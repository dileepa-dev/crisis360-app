import 'dart:io';

class ApiEndpoints {
  static final String baseUrl =
  Platform.isAndroid
      ? "http://10.0.2.2:8080"
      : "http://172.20.10.2:8080";

  static _AuthEndpoints authEndpoints = _AuthEndpoints();
}

class _AuthEndpoints {
  final String saveToken = '${ApiEndpoints.baseUrl}/user/save-token';
  final String getNotifications = '${ApiEndpoints.baseUrl}/notifications';
  final String sendSafety =
      '${ApiEndpoints.baseUrl}/safety/send-safety-confirmation';
  final String submitSafetyStatus = '${ApiEndpoints.baseUrl}/safety/submit';
  final String sosRequest = '${ApiEndpoints.baseUrl}/sos';
  final String loadMapPoints = '${ApiEndpoints.baseUrl}/map/safety-points';
  final String loadSosPoints = '${ApiEndpoints.baseUrl}/sos/sos-points';
}