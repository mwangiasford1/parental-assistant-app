// data/models/activity_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityModel {
  final String id;
  final String userId;
  final String type; // e.g., 'chore', 'good_behavior', 'custom', 'redeem'
  final String description;
  final int points;
  final DateTime timestamp;

  ActivityModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.description,
    required this.points,
    required this.timestamp,
  });

  factory ActivityModel.fromMap(Map<String, dynamic> map, String docId) => ActivityModel(
        id: docId,
        userId: map['userId'],
        type: map['type'],
        description: map['description'],
        points: map['points'],
        timestamp: (map['timestamp'] as Timestamp).toDate(),
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'type': type,
        'description': description,
        'points': points,
        'timestamp': timestamp,
      };
} 