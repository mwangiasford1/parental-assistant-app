// data/models/sos_alert_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class SOSAlertModel {
  final String id;
  final String userId;
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;
  final String status; // 'active' or 'resolved'
  final String? message;

  SOSAlertModel({
    required this.id,
    required this.userId,
    required this.timestamp,
    this.latitude,
    this.longitude,
    this.status = 'active',
    this.message,
  });

  factory SOSAlertModel.fromMap(Map<String, dynamic> map, String docId) => SOSAlertModel(
        id: docId,
        userId: map['userId'],
        timestamp: (map['timestamp'] as Timestamp).toDate(),
        latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
        longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
        status: map['status'] ?? 'active',
        message: map['message'],
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'timestamp': timestamp,
        'latitude': latitude,
        'longitude': longitude,
        'status': status,
        'message': message,
      };
} 