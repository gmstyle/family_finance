import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/invite/pending_invite_store.dart';
import '../data/auth_repository.dart';

/// Auth + lightweight user profile (familyId from Firestore).
class AuthController extends ChangeNotifier {
  AuthController({AuthRepository? repository})
    : _repository = repository ?? AuthRepository() {
    _authSub = _repository.authStateChanges.listen(_onAuthChanged);
  }

  final AuthRepository _repository;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<String?>? _familyIdSub;

  User? _user;
  String? _familyId;
  String? _familyIdConfirmedByCallable;
  String? _pendingInvitePath;
  bool _profileReady = false;
  String? _errorMessage;
  bool _busy = false;
  bool _clearingInvalidSession = false;
  bool _familyIdReconcileAttempted = false;

  static const String _invalidSessionMessage =
      'Your session expired or is invalid. Please sign in again.';

  User? get user => _user;
  bool get isSignedIn => _user != null;
  bool get isEmailVerified => _user?.emailVerified ?? false;
  String? get familyId => _familyId;
  bool get hasFamily => _familyId != null && _familyId!.isNotEmpty;
  String? get pendingInvitePath => _pendingInvitePath;
  String? get pendingInviteToken {
    final path = _pendingInvitePath;
    if (path == null || !path.startsWith('/invite/')) return null;
    final token = path.substring('/invite/'.length);
    return token.isEmpty ? null : token;
  }

  bool get profileReady => _profileReady;
  bool get busy => _busy;
  String? get errorMessage => _errorMessage;

  Future<void> _onAuthChanged(User? user) async {
    // Token refresh / emailVerified update — keep Firestore family subscription.
    if (user != null &&
        user.uid == _user?.uid &&
        (_familyIdSub != null || _profileReady)) {
      _user = user;
      notifyListeners();
      return;
    }

    await _familyIdSub?.cancel();
    _familyIdSub = null;
    _user = user;
    _familyId = null;
    _familyIdConfirmedByCallable = null;
    _familyIdReconcileAttempted = false;
    _profileReady = false;
    // Preserve the message set by [_forceSignOutForInvalidSession] across the
    // authStateChanges(null) that follows signOut.
    if (!_clearingInvalidSession) {
      _errorMessage = null;
    }
    notifyListeners();

    if (user == null) {
      _pendingInvitePath = null;
      _profileReady = true;
      unawaited(PendingInviteStore.clear());
      notifyListeners();
      return;
    }

    if (!await _repository.ensureFreshToken(user)) {
      await _forceSignOutForInvalidSession();
      return;
    }

    try {
      await _repository.ensureUserProfile(user);
    } on FirebaseAuthException catch (e) {
      if (_repository.isInvalidSession(e)) {
        await _forceSignOutForInvalidSession();
        return;
      }
      rethrow;
    }

    _familyIdSub = _repository
        .watchFamilyId(user.uid)
        .listen(
          (familyId) {
            if (familyId != null && familyId.isNotEmpty) {
              _familyId = familyId;
              _familyIdConfirmedByCallable = null;
              unawaited(PendingInviteStore.clear());
              _pendingInvitePath = null;
            } else if (_familyIdConfirmedByCallable != null) {
              _familyId = _familyIdConfirmedByCallable;
            } else {
              _familyId = familyId;
              final missingFamily =
                  familyId == null || familyId.isEmpty;
              if (missingFamily && !_familyIdReconcileAttempted) {
                _familyIdReconcileAttempted = true;
                unawaited(_reconcileFamilyIdFromServer());
              }
            }
            _profileReady = true;
            notifyListeners();
          },
          onError: (Object e) {
            if (_repository.looksLikeInvalidSession(e)) {
              unawaited(_forceSignOutForInvalidSession());
              return;
            }
            _errorMessage = e.toString();
            _profileReady = true;
            notifyListeners();
          },
        );
  }

  Future<void> _forceSignOutForInvalidSession() async {
    if (_clearingInvalidSession) return;
    _clearingInvalidSession = true;
    await _familyIdSub?.cancel();
    _familyIdSub = null;
    _user = null;
    _familyId = null;
    _profileReady = true;
    _errorMessage = _invalidSessionMessage;
    try {
      await _repository.signOut();
    } catch (_) {
      // Already cleared locally; ignore secondary signOut failures.
    } finally {
      _clearingInvalidSession = false;
      _errorMessage = _invalidSessionMessage;
      notifyListeners();
    }
  }

  Future<void> _guard(Future<void> Function() action) async {
    _busy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
    } on FirebaseAuthException catch (e) {
      if (_repository.isInvalidSession(e)) {
        await _forceSignOutForInvalidSession();
        return;
      }
      _errorMessage = e.message ?? e.code;
      rethrow;
    } catch (e) {
      if (_repository.looksLikeInvalidSession(e)) {
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
      await _repository.firebaseAuth.signInWithEmailAndPassword(
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
      final cred = await _repository.firebaseAuth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
      if (displayName != null && displayName.trim().isNotEmpty) {
        await cred.user?.updateDisplayName(displayName.trim());
      }
      await cred.user?.sendEmailVerification();
      await cred.user?.reload();
      _user = _repository.currentUser;
    });
  }

  Future<void> sendPasswordReset(String email) {
    return _guard(() async {
      await _repository.firebaseAuth.sendPasswordResetEmail(
        email: email.trim(),
      );
    });
  }

  Future<void> sendEmailVerification() {
    return _guard(() async {
      await _user?.sendEmailVerification();
    });
  }

  Future<void> reloadUser() async {
    await _user?.reload();
    _user = _repository.currentUser;
    notifyListeners();
  }

  /// Deep link to accept an invite — survives redirects without `?next=`.
  void rememberPendingInvite(String path) {
    if (!path.startsWith('/invite/') || path.length <= '/invite/'.length) {
      return;
    }
    _pendingInvitePath = path;
    final token = pendingInviteToken;
    if (token != null) {
      unawaited(PendingInviteStore.saveToken(token));
    }
    notifyListeners();
  }

  void restorePendingInviteFromToken(String? token) {
    if (token == null || token.trim().isEmpty) return;
    rememberPendingInvite('/invite/${token.trim()}');
  }

  void clearPendingInvite() {
    if (_pendingInvitePath == null) return;
    _pendingInvitePath = null;
    notifyListeners();
  }

  /// Callable just joined/created a family; Firestore listener may lag.
  void applyFamilyId(String familyId) {
    if (familyId.isEmpty) return;
    _familyId = familyId;
    _familyIdConfirmedByCallable = familyId;
    _pendingInvitePath = null;
    unawaited(PendingInviteStore.clear());
    _profileReady = true;
    notifyListeners();
  }

  /// After a successful accept on the server, refresh profile from Firestore.
  Future<bool> syncFamilyIdFromServer() async {
    final uid = _user?.uid;
    if (uid == null) return false;
    final id = await _repository.fetchFamilyIdOnce(uid);
    if (id == null || id.isEmpty) return false;
    if (_user?.uid != uid) return false;
    applyFamilyId(id);
    return true;
  }

  Future<void> _reconcileFamilyIdFromServer() async {
    try {
      await syncFamilyIdFromServer();
    } catch (_) {
      // Realtime listener remains source of truth; ignore transient read errors.
    }
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
      await _repository.firebaseAuth.signInWithCredential(credential);
    });
  }

  bool get hasPasswordProvider => _repository.hasPasswordProvider;
  bool get hasGoogleProvider => _repository.hasGoogleProvider;

  Future<void> reauthenticateWithPassword(String password) {
    return _guard(() => _repository.reauthenticateWithPassword(password));
  }

  Future<void> reauthenticateWithGoogle() {
    return _guard(() async {
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize();
      final account = await googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw StateError('Google Sign-In did not return an idToken.');
      }
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      await _repository.reauthenticateWithGoogleCredential(credential);
    });
  }

  Future<void> signOut() {
    return _guard(() async {
      // Capture before Firebase clears the user. GoogleSignIn.signOut hangs on
      // web when GIS was never initialized (email/password sessions).
      final disconnectGoogle = _repository.hasGoogleProvider;
      await _repository.signOut();
      if (!disconnectGoogle) return;
      try {
        await GoogleSignIn.instance.signOut().timeout(
          const Duration(seconds: 3),
        );
      } catch (_) {
        // GIS may hang/fail on web if not initialized for this session.
      }
    });
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _familyIdSub?.cancel();
    super.dispose();
  }
}
