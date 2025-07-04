// data/models/password_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PasswordModel {
  final String id;
  final String userId;
  final String title;
  final String username;
  final String encryptedPassword;
  final String category;
  final String? website;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;
  final String? iconUrl;

  PasswordModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.username,
    required this.encryptedPassword,
    required this.category,
    this.website,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite = false,
    this.iconUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'username': username,
      'encryptedPassword': encryptedPassword,
      'category': category,
      'website': website,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isFavorite': isFavorite,
      'iconUrl': iconUrl,
    };
  }

  factory PasswordModel.fromMap(Map<String, dynamic> map, String documentId) {
    return PasswordModel(
      id: documentId,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      username: map['username'] ?? '',
      encryptedPassword: map['encryptedPassword'] ?? '',
      category: map['category'] ?? 'General',
      website: map['website'],
      notes: map['notes'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      isFavorite: map['isFavorite'] ?? false,
      iconUrl: map['iconUrl'],
    );
  }

  PasswordModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? username,
    String? encryptedPassword,
    String? category,
    String? website,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
    String? iconUrl,
  }) {
    return PasswordModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      username: username ?? this.username,
      encryptedPassword: encryptedPassword ?? this.encryptedPassword,
      category: category ?? this.category,
      website: website ?? this.website,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      iconUrl: iconUrl ?? this.iconUrl,
    );
  }
}

// Password categories for organization
class PasswordCategories {
  static const List<String> categories = [
    'General',
    'School',
    'Entertainment',
    'Social Media',
    'Gaming',
    'Shopping',
    'Banking',
    'Healthcare',
    'Utilities',
    'Work',
    'Other',
  ];

  static const Map<String, String> categoryIcons = {
    'General': '🔐',
    'School': '🎓',
    'Entertainment': '🎬',
    'Social Media': '📱',
    'Gaming': '🎮',
    'Shopping': '🛒',
    'Banking': '🏦',
    'Healthcare': '🏥',
    'Utilities': '⚡',
    'Work': '💼',
    'Other': '📁',
  };
} 