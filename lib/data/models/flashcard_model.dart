// data/models/flashcard_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FlashcardModel {
  final String id;
  final String userId;
  final String question;
  final String answer;
  final String? subject;
  final DateTime timestamp;

  FlashcardModel({
    required this.id,
    required this.userId,
    required this.question,
    required this.answer,
    this.subject,
    required this.timestamp,
  });

  factory FlashcardModel.fromMap(Map<String, dynamic> map, String docId) => FlashcardModel(
        id: docId,
        userId: map['userId'],
        question: map['question'],
        answer: map['answer'],
        subject: map['subject'],
        timestamp: (map['timestamp'] as Timestamp).toDate(),
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'question': question,
        'answer': answer,
        'subject': subject,
        'timestamp': timestamp,
      };
} 