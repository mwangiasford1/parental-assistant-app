// data/models/geofence_model.dart

class GeofenceModel {
  final String id;
  final String userId;
  final String label;
  final double latitude;
  final double longitude;
  final double radius;
  final bool enabled;

  GeofenceModel({
    required this.id,
    required this.userId,
    required this.label,
    required this.latitude,
    required this.longitude,
    required this.radius,
    this.enabled = true,
  });

  factory GeofenceModel.fromMap(Map<String, dynamic> map, String docId) => GeofenceModel(
        id: docId,
        userId: map['userId'],
        label: map['label'],
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
        radius: (map['radius'] as num).toDouble(),
        enabled: map['enabled'] ?? true,
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'label': label,
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
        'enabled': enabled,
      };
} 