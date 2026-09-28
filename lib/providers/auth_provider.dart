import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/log_service.dart';

class AuthProvider extends ChangeNotifier {
  User? firebaseUser;
  AppUser? appUser;
  bool isLoading = false;
  String? error;

  bool get isAuthenticated => firebaseUser != null;
  bool get isAdmin => appUser?.role == 'admin';

  Future<void> _fetchOrRegisterDefaultUser() async {
    if (firebaseUser == null) return;
    try {
      appUser = await FirestoreService.fetchUser(firebaseUser!.uid);
    } catch (_) {
      // User signed up or exists in Auth but has no Firestore document.
      // Auto-create a default document to prevent crashes and ensure seamless routing.
      final email = firebaseUser!.email ?? '';
      final role =
          email.toLowerCase() == FirestoreService.adminEmail.toLowerCase()
              ? 'admin'
              : 'user';
      final newUser = AppUser(
        uid: firebaseUser!.uid,
        email: email,
        fullName: email.split('@').first,
        role: role,
      );
      await FirestoreService.saveUser(newUser);
      appUser = newUser;
    }
  }

  Future<void> initialize() async {
    firebaseUser = AuthService.currentUser;
    if (firebaseUser != null) {
      await _fetchOrRegisterDefaultUser();
    }
    notifyListeners();
  }

  /// Converts FirebaseAuthException codes into friendly, human-readable messages.
  String _friendlyAuthError(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'The email address is not valid. Please check and try again.';
        case 'user-disabled':
          return 'This account has been disabled. Contact support for help.';
        case 'user-not-found':
          return 'No account found with this email. Please sign up first.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'invalid-credential':
          return 'Email or password is incorrect. Please try again.';
        case 'email-already-in-use':
          return 'An account already exists with this email. Try logging in instead.';
        case 'weak-password':
          return 'Password is too weak. Use at least 6 characters.';
        case 'operation-not-allowed':
          return 'Email/password sign-in is not enabled. Contact support.';
        case 'admin-email-reserved':
          return 'Admin signup is disabled. Use the admin login credentials.';
        case 'too-many-requests':
          return 'Too many failed attempts. Please wait a moment and try again.';
        case 'network-request-failed':
          return 'Network error. Check your internet connection and try again.';
        default:
          return 'Authentication failed. Please try again.';
      }
    }
    final msg = e.toString();
    if (msg.contains('network')) {
      return 'Network error. Check your internet connection and try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final credential =
          await AuthService.signIn(email: email, password: password);
      firebaseUser = credential.user;
      if (firebaseUser != null) {
        await _fetchOrRegisterDefaultUser();
      }
      return true;
    } catch (e) {
      error = _friendlyAuthError(e);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final credential = await AuthService.signUp(
          name: name, email: email, password: password);
      firebaseUser = credential.user;
      if (firebaseUser != null) {
        await _fetchOrRegisterDefaultUser();
      }
      return true;
    } catch (e) {
      error = _friendlyAuthError(e);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Updates the current user's profile image and persists to Firestore.
  Future<void> updateProfileImage(String base64Image) async {
    if (appUser == null || firebaseUser == null) return;
    try {
      await FirestoreService.updateUserProfileImage(
          firebaseUser!.uid, base64Image);
      appUser = appUser!.copyWith(profileImage: base64Image);
      notifyListeners();
      LogService.info('AuthProvider', 'Profile image updated successfully');
    } catch (e) {
      LogService.error('AuthProvider', 'Failed to update profile image: $e');
    }
  }

  Future<void> signOut() async {
    await AuthService.signOut();
    firebaseUser = null;
    appUser = null;
    notifyListeners();
  }
}
