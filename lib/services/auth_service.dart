import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import 'firestore_service.dart';
import 'log_service.dart';

class AuthService {
  AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;

  static Future<UserCredential> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.toLowerCase();
    if (normalizedEmail == FirestoreService.adminEmail.toLowerCase()) {
      LogService.warning('AuthService', 'Attempted to sign up with reserved admin email');
      throw FirebaseAuthException(
        code: 'admin-email-reserved',
        message:
            'Admin signup is disabled. Use the admin login credentials instead.',
      );
    }

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final role = 'user';

    final user = AppUser(
      uid: credential.user!.uid,
      email: email,
      fullName: name,
      role: role,
    );

    await FirestoreService.saveUser(user);
    LogService.info('AuthService', 'New user signed up: ${user.uid}');
    return credential;
  }

  static Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      LogService.info('AuthService', 'User signed in: ${credential.user?.uid}');
      return credential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' &&
          email.toLowerCase() == FirestoreService.adminEmail.toLowerCase() &&
          password == FirestoreService.adminPassword) {
        LogService.info('AuthService', 'Auto-creating admin account on first login');
        return await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
      LogService.error('AuthService', 'Sign in failed', error: e);
      rethrow;
    }
  }

  static Future<void> signOut() async {
    await _auth.signOut();
    LogService.info('AuthService', 'User signed out');
  }
}
