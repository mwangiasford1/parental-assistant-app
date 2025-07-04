// data/models/event_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime? endTime;
  final List<String> participants;
  final String createdBy;
  final bool isRecurring;
  final String? recurrenceRule;

  EventModel({
    required this.id,
    required this.title,
    this.description,
    required this.startTime,
    this.endTime,
    this.participants = const [],
    required this.createdBy,
    this.isRecurring = false,
    this.recurrenceRule,
  });

  factory EventModel.fromMap(Map<String, dynamic> map, String docId) => EventModel(
        id: docId,
        title: map['title'],
        description: map['description'],
        startTime: (map['startTime'] as Timestamp).toDate(),
        endTime: map['endTime'] != null ? (map['endTime'] as Timestamp).toDate() : null,
        participants: (map['participants'] as List<dynamic>?)?.cast<String>() ?? [],
        createdBy: map['createdBy'],
        isRecurring: map['isRecurring'] ?? false,
        recurrenceRule: map['recurrenceRule'],
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'startTime': startTime,
        'endTime': endTime,
        'participants': participants,
        'createdBy': createdBy,
        'isRecurring': isRecurring,
        'recurrenceRule': recurrenceRule,
      };
} 