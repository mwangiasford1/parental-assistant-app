// features/tasks/task_model.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum RecurrenceType { daily, weekly, custom }

class Task {
  final String id;
  final String title;
  final DateTime time;
  final RecurrenceType? recurrence;
  final Color? color;

  Task({
    required this.id,
    required this.title,
    required this.time,
    this.recurrence,
    this.color,
  });

  factory Task.fromMap(Map<String, dynamic> map) => Task(
        id: map['id'],
        title: map['title'],
        time: DateTime.parse(map['time']),
        recurrence: map['recurrence'] != null
            ? RecurrenceType.values.firstWhere(
                (e) => e.toString() == 'RecurrenceType.' + map['recurrence'],
                orElse: () => RecurrenceType.custom,
              )
            : null,
        color: map['color'] != null ? Color(map['color']) : null,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'time': time.toIso8601String(),
        'recurrence': recurrence?.name,
        'color': color?.value,
      };

  // Firestore helpers
  factory Task.fromFirestore(Map<String, dynamic> doc, String docId) => Task(
        id: docId,
        title: doc['title'],
        time: (doc['time'] as Timestamp).toDate(),
        recurrence: doc['recurrence'] != null
            ? RecurrenceType.values.firstWhere(
                (e) => e.name == doc['recurrence'],
                orElse: () => RecurrenceType.custom,
              )
            : null,
        color: doc['color'] != null ? Color(doc['color']) : null,
      );

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'time': time,
        'recurrence': recurrence?.name,
        'color': color?.value,
      };
}
