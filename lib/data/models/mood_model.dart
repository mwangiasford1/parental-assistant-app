// data/models/mood_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class MoodModel {
  final String id;
  final String userId;
  final String mood; // emoji or string
  final String? note;
  final DateTime timestamp;

  MoodModel({
    required this.id,
    required this.userId,
    required this.mood,
    this.note,
    required this.timestamp,
  });

  factory MoodModel.fromMap(Map<String, dynamic> map, String docId) => MoodModel(
        id: docId,
        userId: map['userId'],
        mood: map['mood'],
        note: map['note'],
        timestamp: (map['timestamp'] as Timestamp).toDate(),
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'mood': mood,
        'note': note,
        'timestamp': timestamp,
      };
} 