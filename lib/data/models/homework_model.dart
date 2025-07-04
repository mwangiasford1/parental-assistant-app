// data/models/homework_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeworkModel {
  final String id;
  final String userId;
  final String title;
  final DateTime dueDate;
  final bool isCompleted;
  final String? notes;

  HomeworkModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.dueDate,
    this.isCompleted = false,
    this.notes,
  });

  factory HomeworkModel.fromMap(Map<String, dynamic> map, String docId) => HomeworkModel(
        id: docId,
        userId: map['userId'],
        title: map['title'],
        dueDate: (map['dueDate'] as Timestamp).toDate(),
        isCompleted: map['isCompleted'] ?? false,
        notes: map['notes'],
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'title': title,
        'dueDate': dueDate,
        'isCompleted': isCompleted,
        'notes': notes,
      };
} 