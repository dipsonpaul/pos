import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import 'hive_service.dart';

/// Authentication service for handling login, registration, and user management
class AuthService {
  static final firebase_auth.FirebaseAuth _auth =
      firebase_auth.FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current Firebase user
  static firebase_auth.User? get currentFirebaseUser => _auth.currentUser;

  /// Get current app user from local storage
  static User? get currentUser => HiveService.getCurrentUser();

  /// Stream of authentication state changes
  static Stream<firebase_auth.User?> get authStateChanges =>
      _auth.authStateChanges();

  /// Check if user is logged in
  static bool get isLoggedIn =>
      currentFirebaseUser != null && currentUser != null;

  /// Sign in with email and password
  static Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final firebase_auth.UserCredential result = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      if (result.user != null) {
        debugPrint('🔑 Firebase Auth UID: ${result.user!.uid}');
        debugPrint('📧 Email: ${result.user!.email}');

        // Try to get document by Firebase Auth UID first
        var userDoc =
            await _firestore.collection('users').doc(result.user!.uid).get();

        // If not found, query by email instead
        if (!userDoc.exists) {
          debugPrint('⚠️ Document not found by UID, querying by email...');
          final querySnapshot =
              await _firestore
                  .collection('users')
                  .where('email', isEqualTo: result.user!.email)
                  .limit(1)
                  .get();

          if (querySnapshot.docs.isNotEmpty) {
            userDoc = querySnapshot.docs.first;
            debugPrint('✅ Found user by email query');
          }
        }

        debugPrint('📄 Document exists: ${userDoc.exists}');

        Map<String, dynamic> data;
        if (userDoc.exists && userDoc.data() != null) {
          data = {
            ...userDoc.data()!,
            'id': result.user!.uid, // Use Firebase Auth UID
          };

          debugPrint('👤 User role: ${data['role']}');
          debugPrint('✅ User active: ${data['isActive']}');
        } else {
          // User document not found - sign out and throw error
          await _auth.signOut();
          throw firebase_auth.FirebaseAuthException(
            code: 'user-data-not-found',
            message: 'User profile not found. Please contact administrator.',
          );
        }

        final appUser = User.fromJson(data);

        // Check if user is active
        if (!appUser.isActive) {
          await _auth.signOut();
          throw firebase_auth.FirebaseAuthException(
            code: 'user-disabled',
            message:
                'Your account has been disabled. Please contact administrator.',
          );
        }

        // Save to local storage
        await HiveService.addUser(appUser);
        await HiveService.setCurrentUser(appUser.id);

        debugPrint(
          '✅ Login successful for: ${appUser.name} (${appUser.role.name})',
        );
        return appUser;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Sign in error: $e');
      rethrow;
    }
  }

  /// Register new user
  static Future<User?> registerWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? phone,
    double? allowedLatitude,
    double? allowedLongitude,
    double? locationRadius,
    bool setAsCurrent = false,
    BuildContext? context, // add context if you want to pop
  }) async {
    try {
      final firebase_auth.UserCredential result = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      if (result.user != null) {
        final now = DateTime.now();
        final data = {
          'name': name,
          'email': email,
          'phone': phone ?? '',
          'role': role.name,
          'isActive': true,
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        };

        if (allowedLatitude != null) data['allowedLatitude'] = allowedLatitude;
        if (allowedLongitude != null)
          data['allowedLongitude'] = allowedLongitude;
        if (locationRadius != null) data['locationRadius'] = locationRadius;

        await _firestore.collection('users').doc(result.user!.uid).set(data);

        final appUser = User.fromJson({...data, 'id': result.user!.uid});
        await HiveService.addUser(appUser);

        // ✅ Instead of signing out, just pop the screen
        if (context != null) {
          Navigator.pop(context, appUser);
        }

        return appUser;
      }
      return null;
    } catch (e) {
      debugPrint('Registration error: $e');
      rethrow;
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      await HiveService.clearCurrentUser();
    } catch (e) {
      debugPrint('Sign out error: $e');
      rethrow;
    }
  }

  /// Update user profile
  static Future<void> updateUserProfile({
    String? name,
    String? email,
    UserRole? role,
  }) async {
    try {
      final currentUser = AuthService.currentUser;
      if (currentUser == null) return;

      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (email != null) updateData['email'] = email;
      if (role != null) updateData['role'] = role.name;

      if (updateData.isNotEmpty) {
        // Update Firestore
        await _firestore
            .collection('users')
            .doc(currentUser.id)
            .update(updateData);

        // Update local storage
        final updatedUser = currentUser.copyWith(
          name: name ?? currentUser.name,
          email: email ?? currentUser.email,
          role: role ?? currentUser.role,
        );
        await HiveService.updateUser(updatedUser);
      }
    } catch (e) {
      debugPrint('Update profile error: $e');
      rethrow;
    }
  }

  /// Check if user has admin privileges
  static bool isAdmin() {
    return currentUser?.role == UserRole.admin;
  }

  /// Check if user has staff privileges
  static bool isStaff() {
    return currentUser?.role == UserRole.staff;
  }

  /// Get user role as string
  static String getUserRoleString() {
    return currentUser?.role.name.toUpperCase() ?? 'UNKNOWN';
  }

  /// Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Validate password strength
  static bool isValidPassword(String password) {
    // At least 6 characters
    return password.length >= 6;
  }

  /// Get authentication error message
  /// Get authentication error message

  static String getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'invalid-role':
        return 'You do not have permission to login with the selected role.';
      case 'user-data-not-found':
        return 'User profile not found. Please contact administrator.';
      default:
        // Handle Firebase exception format
        if (errorCode.contains('invalid-role') ||
            errorCode.contains('permission')) {
          return 'You do not have permission to login with the selected role.';
        }
        if (errorCode.contains('user-data-not-found')) {
          return 'User profile not found. Please contact administrator.';
        }
        return 'An error occurred. Please try again.';
    }
  }
}
