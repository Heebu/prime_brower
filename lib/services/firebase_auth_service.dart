import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAuthService with ChangeNotifier {
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;
  bool _isInitialized = false;
  bool _googleSignInInitialized = false;

  bool get isInitialized => _isInitialized;

  FirebaseAuthService() {
    _init();
  }

  void _init() {
    try {
      if (Firebase.apps.isNotEmpty) {
        _auth = FirebaseAuth.instance;
        _firestore = FirebaseFirestore.instance;
        _isInitialized = true;
        _auth?.authStateChanges().listen((user) {
          if (user != null) {
            _syncUserWithFirestore(user);
          }
          notifyListeners();
        });
      }
      _initGoogleSignIn();
    } catch (e) {
      debugPrint('FirebaseAuthService: Firebase not initialized: $e');
    }
  }

  Future<void> _initGoogleSignIn() async {
    if (_googleSignInInitialized) return;
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId: '920487723086-fhjvu8frsr4ic6ium57b24g9h6e04v5r.apps.googleusercontent.com',
      );
      _googleSignInInitialized = true;
    } catch (e) {
      debugPrint('GoogleSignIn initialize notice: $e');
    }
  }

  /// Automatically synchronizes the user profile into Firestore: users/{uid}
  Future<void> _syncUserWithFirestore(User user) async {
    try {
      if (_firestore == null && Firebase.apps.isNotEmpty) {
        _firestore = FirebaseFirestore.instance;
      }
      if (_firestore == null) return;

      final userDoc = _firestore!.collection('users').doc(user.uid);
      final snapshot = await userDoc.get();

      final data = <String, dynamic>{
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': user.displayName ?? '',
        'photoURL': user.photoURL ?? '',
        'isAnonymous': user.isAnonymous,
        'lastLogin': FieldValue.serverTimestamp(),
      };

      if (!snapshot.exists) {
        data['createdAt'] = FieldValue.serverTimestamp();
      }

      await userDoc.set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirebaseAuthService: Firestore sync notice: $e');
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

  String? get userPhotoUrl => currentUser?.photoURL;

  bool get isGoogleUser {
    final user = currentUser;
    if (user == null) return false;
    return user.providerData.any((p) => p.providerId == 'google.com');
  }

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

  /// Email & Password Sign In
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      if (_auth == null) _init();
      final credential = await _auth?.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      if (credential?.user != null) {
        await _syncUserWithFirestore(credential!.user!);
      }
      notifyListeners();
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred during sign in: $e';
    }
  }

  /// Email & Password Sign Up / Registration
  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      if (_auth == null) _init();
      final credential = await _auth?.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      if (credential?.user != null) {
        await _syncUserWithFirestore(credential!.user!);
      }
      notifyListeners();
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred during sign up: $e';
    }
  }

  /// Google Sign-In with OAuth credential exchange
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (_auth == null) _init();
      await _initGoogleSignIn();

      final GoogleSignInAccount account = await GoogleSignIn.instance.authenticate();
      final GoogleSignInAuthentication auth = account.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: auth.idToken,
      );

      final userCredential = await _auth?.signInWithCredential(credential);
      if (userCredential?.user != null) {
        await _syncUserWithFirestore(userCredential!.user!);
      }
      notifyListeners();
      return userCredential;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        // User explicitly cancelled the sign in
        return null;
      }
      throw 'Google Sign-In failed: ${e.description ?? e.code.name}';
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      throw 'Google Sign-In failed: $e';
    }
  }

  /// Password Reset Email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      if (_auth == null) _init();
      await _auth?.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to send password reset email: $e';
    }
  }

  /// 1-Tap Anonymous / Guest Sign-In
  Future<UserCredential?> signInAnonymously() async {
    try {
      if (_auth == null) _init();
      final credential = await _auth?.signInAnonymously();
      if (credential?.user != null) {
        await _syncUserWithFirestore(credential!.user!);
      }
      notifyListeners();
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred during anonymous sign in: $e';
    }
  }

  /// Sign Out (both Firebase Auth and Google)
  Future<void> signOut() async {
    try {
      await _auth?.signOut();
      try {
        await GoogleSignIn.instance.signOut();
      } catch (e) {
        debugPrint('Google sign-out notice: $e');
      }
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
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different credential.';
      case 'invalid-credential':
        return 'Invalid authentication credentials provided.';
      default:
        return e.message ?? 'Authentication failed. Please check credentials.';
    }
  }
}
