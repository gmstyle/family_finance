import 'package:flutter/foundation.dart';

import '../data/family_repository.dart';
import '../domain/family.dart';

export '../domain/family.dart' show FamilyInfo, FamilyInvite, FamilyMember;
export '../data/family_repository.dart'
    show FamilyRepository, FirebaseFunctionsException;

export 'package:cloud_functions/cloud_functions.dart'
    show FirebaseFunctionsException;

/// UI-facing family actions wrapping [FamilyRepository].
class FamilyController extends ChangeNotifier {
  FamilyController({FamilyRepository? repository})
    : _repository = repository ?? FamilyRepository();

  final FamilyRepository _repository;

  bool _busy = false;
  String? _errorMessage;
  FamilyInvite? _lastCreatedInvite;

  bool get busy => _busy;
  String? get errorMessage => _errorMessage;
  FamilyInvite? get lastCreatedInvite => _lastCreatedInvite;

  Stream<FamilyInfo?> watchFamily(String familyId) =>
      _repository.watchFamily(familyId);

  Stream<List<FamilyMember>> watchMembers(String familyId) =>
      _repository.watchMembers(familyId);

  Stream<List<FamilyInvite>> watchPendingInvites(String familyId) =>
      _repository.watchPendingInvites(familyId);

  Future<T> _guard<T>(Future<T> Function() action) async {
    _busy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      return await action();
    } on FirebaseFunctionsException catch (e) {
      _errorMessage = _formatFunctionsError(e);
      rethrow;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<String> createFamily({
    required String name,
    String currency = 'EUR',
    String timezone = 'Europe/Rome',
  }) {
    return _guard(
      () => _repository.createFamily(
        name: name,
        currency: currency,
        timezone: timezone,
      ),
    );
  }

  Future<FamilyInvite> createInvite(String email) {
    return _guard(() async {
      final invite = await _repository.createInvite(invitedEmail: email);
      _lastCreatedInvite = invite;
      return invite;
    });
  }

  Future<void> revokeInvite(String inviteId) =>
      _guard(() => _repository.revokeInvite(inviteId));

  Future<String> acceptInvite(String token) =>
      _guard(() => _repository.acceptInvite(token));

  Future<void> leaveFamily() => _guard(() => _repository.leaveFamily());

  Future<void> removeMember(String userId) =>
      _guard(() => _repository.removeMember(userId));

  Future<void> updateMemberRole({
    required String userId,
    required String role,
  }) => _guard(() => _repository.updateMemberRole(userId: userId, role: role));

  Future<void> transferOwnership(String userId) =>
      _guard(() => _repository.transferOwnership(userId));

  void clearLastInvite() {
    _lastCreatedInvite = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  static String _formatFunctionsError(FirebaseFunctionsException e) {
    final parts = <String>[e.code];
    if (e.message != null && e.message!.trim().isNotEmpty) {
      parts.add(e.message!.trim());
    }
    final details = e.details;
    if (details != null) {
      parts.add(details.toString());
    }
    if (e.code == 'not-found' || e.code == 'NOT_FOUND') {
      parts.add(
        '(callable missing or wrong project/region — '
        'check emulator --project and Functions region)',
      );
    }
    return parts.join(' — ');
  }
}
