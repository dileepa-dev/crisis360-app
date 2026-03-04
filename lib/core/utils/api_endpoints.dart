class ApiEndpoints {
  static _AuthEndpoints authEndpoints = _AuthEndpoints();
}

class _AuthEndpoints {
  final String saveToken = 'http://172.20.10.2:8080/user/save-token';
  final String getNotifications = 'http://172.20.10.2:8080/notifications';
  final String sendSafety = 'http://172.20.10.2:8080/safety/send-safety-confirmation';
  final String submitSafetyStatus = 'http://172.20.10.2:8080/safety/submit';
  final String sosRequest = 'http://172.20.10.2:8080/sos';
  final String loadMapPoints = 'http://172.20.10.2:8080/map/safety-points';
  final String loadSosPoints = 'http://172.20.10.2:8080/sos/sos-points';
}