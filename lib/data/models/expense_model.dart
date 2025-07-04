// data/models/expense_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String id;
  final String userId;
  final double amount;
  final String category;
  final String description;
  final DateTime date;
  final String type; // 'income' or 'expense'

  ExpenseModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    required this.type,
  });

  factory ExpenseModel.fromMap(Map<String, dynamic> map, String docId) => ExpenseModel(
        id: docId,
        userId: map['userId'],
        amount: (map['amount'] as num).toDouble(),
        category: map['category'],
        description: map['description'],
        date: (map['date'] as Timestamp).toDate(),
        type: map['type'],
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'amount': amount,
        'category': category,
        'description': description,
        'date': date,
        'type': type,
      };
} 