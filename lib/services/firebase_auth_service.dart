import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService with ChangeNotifier {
  FirebaseAuth? _auth;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  FirebaseAuthService() {
    _init();
  }

  void _init() {
    try {
      if (Firebase.apps.isNotEmpty) {
        _auth = FirebaseAuth.instance;
        _isInitialized = true;
        _auth?.authStateChanges().listen((_) {
          notifyListeners();
        });
      }
    } catch (e) {
      debugPrint('FirebaseAuthService: Firebase not initialized: $e');
    }
  }

  /// Refreshes initialization once Firebase.initializeApp has succeeded
  void refreshInitialization() {
    _init();
    notifyListeners();
  }

  User? get currentUser => _auth?.currentUser;
  bool get isAuthenticated => currentUser != null;
  Stream<User?> get authStateChanges => _auth?.authStateChanges() ?? const Stream.empty();

  String get userDisplayName {
    final user = currentUser;
    if (user == null) return 'Guest';
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    if (user.email != null && user.email!.isNotEmpty) {
      return user.email!.split('@').first;
    }
    if (user.isAnonymous) return 'Guest (Anonymous)';
    return 'User';
  }

  String get userEmail {
    final user = currentUser;
    if (user == null) return 'Not signed in';
    if (user.email != null && user.email!.isNotEmpty) return user.email!;
    if (user.isAnonymous) return 'Temporary Guest Account';
    return 'Signed In';
  }

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      if (_auth == null) _init();
      final credential = await _auth?.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      notifyListeners();
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred during sign in.';
    }
  }

  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      if (_auth == null) _init();
      final credential = await _auth?.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      notifyListeners();
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred during sign up.';
    }
  }

  Future<UserCredential?> signInAnonymously() async {
    try {
      if (_auth == null) _init();
      final credential = await _auth?.signInAnonymously();
      notifyListeners();
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred during anonymous sign in.';
    }
  }

  Future<void> signOut() async {
    try {
      await _auth?.signOut();
      notifyListeners();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password provided.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'invalid-email':
        return 'The email address is badly formatted.';
      case 'weak-password':
        return 'The password must be at least 6 characters.';
      default:
        return e.message ?? 'Authentication failed. Please check credentials.';
    }
  }
}
