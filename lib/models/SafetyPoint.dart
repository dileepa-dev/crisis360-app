class SafetyPoint {
  final String id;
  final double latitude;
  final double longitude;
  final String riskLevel;

  SafetyPoint({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.riskLevel,
  });

  factory SafetyPoint.fromJson(Map<String, dynamic> json) {
    return SafetyPoint(
      id: (json['id'] ?? '').toString(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      riskLevel: (json['riskLevel'] ?? 'UNKNOWN').toString(),
    );
  }
}