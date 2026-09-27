import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Auth + lightweight user profile (familyId from Firestore).
class AuthController extends ChangeNotifier {
  AuthController({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance {
    _authSub = _auth.authStateChanges().listen(_onAuthChanged);
  }

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userDocSub;

  User? _user;
  String? _familyId;
  bool _profileReady = false;
  String? _errorMessage;
  bool _busy = false;
  bool _clearingInvalidSession = false;

  static const String _invalidSessionMessage =
      'Your session expired or is invalid. Please sign in again.';

  User? get user => _user;
  bool get isSignedIn => _user != null;
  bool get isEmailVerified => _user?.emailVerified ?? false;
  String? get familyId => _familyId;
  bool get hasFamily => _familyId != null && _familyId!.isNotEmpty;
  bool get profileReady => _profileReady;
  bool get busy => _busy;
  String? get errorMessage => _errorMessage;

  Future<void> _onAuthChanged(User? user) async {
    await _userDocSub?.cancel();
    _userDocSub = null;
    _user = user;
    _familyId = null;
    _profileReady = false;
    // Preserve the message set by [_forceSignOutForInvalidSession] across the
    // authStateChanges(null) that follows signOut.
    if (!_clearingInvalidSession) {
      _errorMessage = null;
    }
    notifyListeners();

    if (user == null) {
      _profileReady = true;
      notifyListeners();
      return;
    }

    if (!await _ensureFreshToken(user)) {
      return;
    }

    try {
      await _ensureUserProfile(user);
    } on FirebaseAuthException catch (e) {
      if (_isInvalidSession(e)) {
        await _forceSignOutForInvalidSession();
        return;
      }
      rethrow;
    }

    _userDocSub = _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen(
          (snap) {
            _familyId = snap.data()?['familyId'] as String?;
            _profileReady = true;
            notifyListeners();
          },
          onError: (Object e) {
            if (_looksLikeInvalidSession(e)) {
              unawaited(_forceSignOutForInvalidSession());
              return;
            }
            _errorMessage = e.toString();
            _profileReady = true;
            notifyListeners();
          },
        );
  }

  /// Returns false if the session was cleared due to a bad/expired token.
  Future<bool> _ensureFreshToken(User user) async {
    try {
      await user.getIdToken(true);
      return true;
    } catch (e) {
      if (_looksLikeInvalidSession(e)) {
        await _forceSignOutForInvalidSession();
        return false;
      }
      rethrow;
    }
  }

  bool _isInvalidSession(FirebaseAuthException e) {
    final code = e.code.toLowerCase();
    final message = (e.message ?? '').toLowerCase();
    return code == 'invalid-refresh-token' ||
        code == 'user-token-expired' ||
        code == 'invalid-user-token' ||
        message.contains('invalid refresh token') ||
        message.contains('token has been expired') ||
        message.contains('user token expired');
  }

  bool _looksLikeInvalidSession(Object e) {
    if (e is FirebaseAuthException) return _isInvalidSession(e);
    final text = e.toString().toLowerCase();
    return text.contains('invalid refresh token') ||
        text.contains('user-token-expired') ||
        text.contains('invalid-user-token') ||
        text.contains('user token expired');
  }

  Future<void> _forceSignOutForInvalidSession() async {
    if (_clearingInvalidSession) return;
    _clearingInvalidSession = true;
    await _userDocSub?.cancel();
    _userDocSub = null;
    _user = null;
    _familyId = null;
    _profileReady = true;
    _errorMessage = _invalidSessionMessage;
    try {
      await _auth.signOut();
    } catch (_) {
      // Already cleared locally; ignore secondary signOut failures.
    } finally {
      _clearingInvalidSession = false;
      _errorMessage = _invalidSessionMessage;
      notifyListeners();
    }
  }

  Future<void> _ensureUserProfile(User user) async {
    final ref = _firestore.collection('users').doc(user.uid);
    final snap = await ref.get();
    if (snap.exists) return;
    await ref.set({
      'email': user.email ?? '',
      'displayName': user.displayName ?? user.email?.split('@').first ?? 'User',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _guard(Future<void> Function() action) async {
    _busy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
    } on FirebaseAuthException catch (e) {
      if (_isInvalidSession(e)) {
        await _forceSignOutForInvalidSession();
        return;
      }
      _errorMessage = e.message ?? e.code;
      rethrow;
    } catch (e) {
      if (_looksLikeInvalidSession(e)) {
        await _forceSignOutForInvalidSession();
        return;
      }
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _guard(() async {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    });
  }

  Future<void> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) {
    return _guard(() async {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (displayName != null && displayName.trim().isNotEmpty) {
        await cred.user?.updateDisplayName(displayName.trim());
      }
      await cred.user?.sendEmailVerification();
      await cred.user?.reload();
      _user = _auth.currentUser;
    });
  }

  Future<void> sendPasswordReset(String email) {
    return _guard(() async {
      await _auth.sendPasswordResetEmail(email: email.trim());
    });
  }

  Future<void> sendEmailVerification() {
    return _guard(() async {
      await _user?.sendEmailVerification();
    });
  }

  Future<void> reloadUser() async {
    await _user?.reload();
    _user = _auth.currentUser;
    notifyListeners();
  }

  Future<void> signInWithGoogle() {
    return _guard(() async {
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize();
      final account = await googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw StateError('Google Sign-In did not return an idToken.');
      }
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      await _auth.signInWithCredential(credential);
    });
  }

  Future<void> signOut() {
    return _guard(() async {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        // Google may not be initialized (email-only sessions).
      }
      await _auth.signOut();
    });
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _userDocSub?.cancel();
    super.dispose();
  }
}
