import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Firebase Auth + Firestore user profile (`users/{uid}`).
class AuthRepository {
  AuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  FirebaseAuth get firebaseAuth => _auth;

  Stream<String?> watchFamilyId(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snap) => snap.data()?['familyId'] as String?);
  }

  /// Returns false if the session was cleared due to a bad/expired token.
  Future<bool> ensureFreshToken(User user) async {
    try {
      await user.getIdToken(true);
      return true;
    } catch (e) {
      if (looksLikeInvalidSession(e)) {
        return false;
      }
      rethrow;
    }
  }

  Future<void> ensureUserProfile(User user) async {
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

  Future<void> signOut() => _auth.signOut();

  /// True when the current user has an email/password provider.
  bool get hasPasswordProvider {
    final user = _auth.currentUser;
    if (user == null) return false;
    return user.providerData.any((p) => p.providerId == 'password');
  }

  /// True when the current user signed in with Google.
  bool get hasGoogleProvider {
    final user = _auth.currentUser;
    if (user == null) return false;
    return user.providerData.any((p) => p.providerId == 'google.com');
  }

  Future<void> reauthenticateWithPassword(String password) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null || email.isEmpty) {
      throw StateError('No signed-in email user to reauthenticate.');
    }
    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);
  }

  Future<void> reauthenticateWithGoogleCredential(
    AuthCredential credential,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No signed-in user to reauthenticate.');
    }
    await user.reauthenticateWithCredential(credential);
  }

  bool isInvalidSession(FirebaseAuthException e) {
    final code = e.code.toLowerCase();
    final message = (e.message ?? '').toLowerCase();
    return code == 'invalid-refresh-token' ||
        code == 'user-token-expired' ||
        code == 'invalid-user-token' ||
        message.contains('invalid refresh token') ||
        message.contains('token has been expired') ||
        message.contains('user token expired');
  }

  bool looksLikeInvalidSession(Object e) {
    if (e is FirebaseAuthException) return isInvalidSession(e);
    final text = e.toString().toLowerCase();
    return text.contains('invalid refresh token') ||
        text.contains('user-token-expired') ||
        text.contains('invalid-user-token') ||
        text.contains('user token expired');
  }
}
