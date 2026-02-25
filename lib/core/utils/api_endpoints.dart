class ApiEndpoints {
  static _AuthEndpoints authEndpoints = _AuthEndpoints();
}

class _AuthEndpoints {
  final String saveToken = 'http://172.20.10.2:8080/user/save-token';
  final String getNotifications = 'http://172.20.10.2:8080/notifications';
}