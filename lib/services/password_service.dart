// services/password_service.dart
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/password_model.dart';

class PasswordService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'passwords';

  // Simple encryption key (in production, use proper key management)
  static const String _encryptionKey = 'parental_assistant_secure_key_2024';

  // Encrypt password using simple XOR encryption
  static String _encryptPassword(String password) {
    final keyBytes = utf8.encode(_encryptionKey);
    final passwordBytes = utf8.encode(password);
    final encryptedBytes = Uint8List(passwordBytes.length);
    
    for (int i = 0; i < passwordBytes.length; i++) {
      encryptedBytes[i] = passwordBytes[i] ^ keyBytes[i % keyBytes.length];
    }
    
    return base64.encode(encryptedBytes);
  }

  // Decrypt password
  static String _decryptPassword(String encryptedPassword) {
    final keyBytes = utf8.encode(_encryptionKey);
    final encryptedBytes = base64.decode(encryptedPassword);
    final decryptedBytes = Uint8List(encryptedBytes.length);
    
    for (int i = 0; i < encryptedBytes.length; i++) {
      decryptedBytes[i] = encryptedBytes[i] ^ keyBytes[i % keyBytes.length];
    }
    
    return utf8.decode(decryptedBytes);
  }

  // Generate a secure password
  static String generatePassword({
    int length = 16,
    bool includeUppercase = true,
    bool includeLowercase = true,
    bool includeNumbers = true,
    bool includeSymbols = true,
  }) {
    const String uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const String lowercase = 'abcdefghijklmnopqrstuvwxyz';
    const String numbers = '0123456789';
    const String symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

    String chars = '';
    if (includeUppercase) chars += uppercase;
    if (includeLowercase) chars += lowercase;
    if (includeNumbers) chars += numbers;
    if (includeSymbols) chars += symbols;

    if (chars.isEmpty) chars = lowercase + numbers;

    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  // Add a new password
  static Future<void> addPassword({
    required String userId,
    required String title,
    required String username,
    required String password,
    required String category,
    String? website,
    String? notes,
  }) async {
    final encryptedPassword = _encryptPassword(password);
    final now = DateTime.now();
    
    final passwordData = PasswordModel(
      id: '',
      userId: userId,
      title: title,
      username: username,
      encryptedPassword: encryptedPassword,
      category: category,
      website: website,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );

    await _firestore.collection(_collection).add(passwordData.toMap());
  }

  // Get all passwords for a user
  static Stream<List<PasswordModel>> getPasswords(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PasswordModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get passwords by category
  static Stream<List<PasswordModel>> getPasswordsByCategory(String userId, String category) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('category', isEqualTo: category)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PasswordModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get favorite passwords
  static Stream<List<PasswordModel>> getFavoritePasswords(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('isFavorite', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PasswordModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Update password
  static Future<void> updatePassword({
    required String passwordId,
    String? title,
    String? username,
    String? password,
    String? category,
    String? website,
    String? notes,
    bool? isFavorite,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': Timestamp.now(),
    };

    if (title != null) updates['title'] = title;
    if (username != null) updates['username'] = username;
    if (password != null) updates['encryptedPassword'] = _encryptPassword(password);
    if (category != null) updates['category'] = category;
    if (website != null) updates['website'] = website;
    if (notes != null) updates['notes'] = notes;
    if (isFavorite != null) updates['isFavorite'] = isFavorite;

    await _firestore.collection(_collection).doc(passwordId).update(updates);
  }

  // Delete password
  static Future<void> deletePassword(String passwordId) async {
    await _firestore.collection(_collection).doc(passwordId).delete();
  }

  // Toggle favorite status
  static Future<void> toggleFavorite(String passwordId, bool isFavorite) async {
    await _firestore.collection(_collection).doc(passwordId).update({
      'isFavorite': isFavorite,
      'updatedAt': Timestamp.now(),
    });
  }

  // Decrypt password for display
  static String decryptPassword(String encryptedPassword) {
    try {
      return _decryptPassword(encryptedPassword);
    } catch (e) {
      return 'Error decrypting password';
    }
  }

  // Export passwords as JSON (for backup)
  static Future<String> exportPasswords(String userId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .get();

    final passwords = snapshot.docs
        .map((doc) => PasswordModel.fromMap(doc.data(), doc.id))
        .toList();

    final exportData = {
      'exportDate': DateTime.now().toIso8601String(),
      'version': '1.0',
      'passwords': passwords.map((p) => p.toMap()).toList(),
    };

    return json.encode(exportData);
  }

  // Import passwords from JSON (for restore)
  static Future<void> importPasswords(String userId, String jsonData) async {
    try {
      final data = json.decode(jsonData);
      final passwords = data['passwords'] as List;

      for (final passwordData in passwords) {
        // Create new password with current user ID
        final password = PasswordModel.fromMap(passwordData, '');
        final newPassword = password.copyWith(
          userId: userId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firestore.collection(_collection).add(newPassword.toMap());
      }
    } catch (e) {
      throw Exception('Failed to import passwords: $e');
    }
  }

  // Search passwords
  static Stream<List<PasswordModel>> searchPasswords(String userId, String query) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('title')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PasswordModel.fromMap(doc.data(), doc.id))
            .where((password) =>
                password.title.toLowerCase().contains(query.toLowerCase()) ||
                password.username.toLowerCase().contains(query.toLowerCase()) ||
                (password.website?.toLowerCase().contains(query.toLowerCase()) ?? false))
            .toList());
  }

  // Get password strength score
  static int getPasswordStrength(String password) {
    int score = 0;
    
    if (password.length >= 8) score += 1;
    if (password.length >= 12) score += 1;
    if (RegExp(r'[A-Z]').hasMatch(password)) score += 1;
    if (RegExp(r'[a-z]').hasMatch(password)) score += 1;
    if (RegExp(r'[0-9]').hasMatch(password)) score += 1;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) score += 1;
    
    return score;
  }

  // Get password strength description
  static String getPasswordStrengthDescription(int score) {
    switch (score) {
      case 0:
      case 1:
        return 'Very Weak';
      case 2:
        return 'Weak';
      case 3:
        return 'Fair';
      case 4:
        return 'Good';
      case 5:
        return 'Strong';
      case 6:
        return 'Very Strong';
      default:
        return 'Unknown';
    }
  }
} 