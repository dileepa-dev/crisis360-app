class SosPoint {
  final String id;
  final String userId;
  final String riskLevel;
  final String status;
  final double latitude;
  final double longitude;
  final String timestamp;

  SosPoint({
    required this.id,
    required this.userId,
    required this.riskLevel,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  factory SosPoint.fromJson(Map<String, dynamic> json) {
    return SosPoint(
      id: (json['id'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      riskLevel: (json['riskLevel'] ?? 'UNKNOWN').toString(),
      status: (json['status'] ?? 'UNKNOWN').toString(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestamp: (json['timestamp'] ?? '').toString(),
    );
  }
}