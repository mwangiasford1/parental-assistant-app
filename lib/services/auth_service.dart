// services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/user_model.dart';
import 'log_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Get current user ID
  static String? get currentUserId => _auth.currentUser?.uid;

  // Stream of auth state changes
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  static Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Create user with email and password
  static Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Sign out
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  // Send password reset email
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      LogService.d('Attempting to send password reset email to: $email');

      // First, check if the user exists in Firestore
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        LogService.d('No user found in Firestore with email: $email');
        throw Exception(
          'No account found with this email address. Please check the email or create a new account.',
        );
      }

      LogService.d('User found in Firestore, proceeding with password reset');
      await _auth.sendPasswordResetEmail(email: email);
      LogService.d('Password reset email sent successfully to: $email');
    } catch (e) {
      LogService.e('Error sending password reset email', e);
      // Provide more specific error messages
      if (e.toString().contains('user-not-found')) {
        throw Exception(
          'No account found with this email address. Please check the email or create a new account.',
        );
      } else if (e.toString().contains('invalid-email')) {
        throw Exception('Please enter a valid email address.');
      } else if (e.toString().contains('too-many-requests')) {
        throw Exception(
          'Too many password reset attempts. Please try again later.',
        );
      } else if (e.toString().contains(
        'No account found with this email address',
      )) {
        // Re-throw our custom exception
        rethrow;
      } else {
        throw Exception(
          'Failed to send password reset email. Please try again or contact support. Error: ${e.toString()}',
        );
      }
    }
  }

  // Get user profile from Firestore
  static Future<UserModel?> getUserProfile(String uid) async {
    try {
      LogService.d('[AuthService] Fetching user profile for uid: $uid');
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        LogService.d('[AuthService] User profile found for uid: $uid');
        return UserModel.fromJson(doc.data()!);
      } else {
        LogService.d(
          '[AuthService] User profile NOT found for uid: $uid. Attempting to auto-create.',
        );
        // Auto-create profile if missing
        final user = _auth.currentUser;
        if (user != null) {
          final name = user.displayName ?? 'New User';
          final email = user.email ?? '';
          final role = 'parent'; // Default role, adjust as needed
          LogService.d(
            '[AuthService] Creating user profile for $uid: name=$name, email=$email, role=$role',
          );
          await createUserProfile(
            uid: uid,
            name: name,
            email: email,
            role: role,
          );
          // Fetch the newly created profile
          final newDoc = await _firestore.collection('users').doc(uid).get();
          if (newDoc.exists) {
            LogService.d(
              '[AuthService] Successfully auto-created user profile for uid: $uid',
            );
            return UserModel.fromJson(newDoc.data()!);
          } else {
            LogService.e(
              '[AuthService] Failed to auto-create user profile for uid: $uid',
            );
          }
        } else {
          LogService.e(
            '[AuthService] No current user found in FirebaseAuth when trying to auto-create profile.',
          );
        }
      }
      return null;
    } catch (e) {
      LogService.e('[AuthService] Error getting user profile for uid $uid', e);
      return null;
    }
  }

  // Get user profile by email from Firestore
  static Future<UserModel?> getUserProfileByEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return UserModel.fromJson(querySnapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      LogService.e('Error getting user profile by email', e);
      return null;
    }
  }

  // Create or update user profile in Firestore
  static Future<void> createUserProfile({
    required String uid,
    required String name,
    required String email,
    required String role,
    String? profileImageUrl,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'profileImageUrl': profileImageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Update user profile
  static Future<void> updateUserProfile(
    String uid,
    Map<String, dynamic> updates,
  ) async {
    await _firestore.collection('users').doc(uid).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Check if user is authenticated
  static bool get isAuthenticated => _auth.currentUser != null;

  // Get current user's role
  static Future<String?> getCurrentUserRole() async {
    final uid = currentUserId;
    if (uid == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data()?['role'] as String?;
      }
      return null;
    } catch (e) {
      LogService.e('Error getting user role', e);
      return null;
    }
  }

  // Check if current user is a parent
  static Future<bool> isParent() async {
    final role = await getCurrentUserRole();
    return role == 'parent';
  }

  // Check if current user is a child
  static Future<bool> isChild() async {
    final role = await getCurrentUserRole();
    return role == 'child';
  }

  // Check if current user is a nanny
  static Future<bool> isNanny() async {
    final role = await getCurrentUserRole();
    return role == 'nanny';
  }

  // Get user's display name
  static String? get displayName => _auth.currentUser?.displayName;

  // Get user's email
  static String? get email => _auth.currentUser?.email;

  // Get user's photo URL
  static String? get photoURL => _auth.currentUser?.photoURL;

  // Update user's display name
  static Future<void> updateDisplayName(String displayName) async {
    await _auth.currentUser?.updateDisplayName(displayName);
  }

  // Update user's email
  static Future<void> updateEmail(String email) async {
    await _auth.currentUser?.updateEmail(email);
  }

  // Update user's photo URL
  static Future<void> updatePhotoURL(String photoURL) async {
    await _auth.currentUser?.updatePhotoURL(photoURL);
  }

  // Delete user account
  static Future<void> deleteAccount() async {
    final uid = currentUserId;
    if (uid != null) {
      // Delete user data from Firestore
      await _firestore.collection('users').doc(uid).delete();
      // Delete user account from Firebase Auth
      await _auth.currentUser?.delete();
    }
  }
}
