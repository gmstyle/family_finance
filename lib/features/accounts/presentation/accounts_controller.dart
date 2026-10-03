import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../family/data/family_repository.dart';
import '../data/accounts_repository.dart';
import '../domain/account.dart';

/// Accounts list + CRUD; screens never touch [AccountsRepository] directly.
class AccountsController extends ChangeNotifier {
  AccountsController({
    AccountsRepository? accountsRepository,
    FamilyRepository? familyRepository,
  }) : _accounts = accountsRepository ?? AccountsRepository(),
       _family = familyRepository ?? FamilyRepository();

  final AccountsRepository _accounts;
  final FamilyRepository _family;

  String? _familyId;
  List<Account> _items = const [];
  String _currency = 'EUR';
  bool _loading = false;
  bool _busy = false;
  bool _hasReceived = false;
  String? _errorMessage;
  final List<StreamSubscription<dynamic>> _subs = [];

  String? get familyId => _familyId;
  List<Account> get items => _items;
  String get currency => _currency;
  bool get loading => _loading && !_hasReceived;
  bool get busy => _busy;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => !loading && _errorMessage == null && _items.isEmpty;

  Stream<List<Account>> watchAccounts({bool includeArchived = false}) {
    final familyId = _requireFamilyId();
    return _accounts.watchAccounts(familyId, includeArchived: includeArchived);
  }

  Future<void> bindFamily(String? familyId) async {
    if (familyId == null || familyId.isEmpty) {
      await _clear();
      return;
    }
    if (_familyId == familyId && _subs.isNotEmpty) return;
    _familyId = familyId;
    await _resubscribe();
  }

  Future<void> _clear() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    _familyId = null;
    _items = const [];
    _currency = 'EUR';
    _loading = false;
    _hasReceived = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _resubscribe() async {
    final familyId = _familyId;
    if (familyId == null) return;
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    _items = const [];
    _hasReceived = false;
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    _subs.add(
      _accounts
          .watchAccounts(familyId, includeArchived: true)
          .listen(
            (items) {
              _items = items;
              _hasReceived = true;
              _loading = false;
              _errorMessage = null;
              notifyListeners();
            },
            onError: (Object e) {
              _errorMessage = e.toString();
              _loading = false;
              notifyListeners();
            },
          ),
    );

    _subs.add(
      _family
          .watchFamily(familyId)
          .listen(
            (info) {
              _currency = info?.currency ?? 'EUR';
              notifyListeners();
            },
            onError: (Object e) {
              _errorMessage = e.toString();
              notifyListeners();
            },
          ),
    );
  }

  Future<Account?> getAccount(String accountId) {
    return _accounts.getAccount(_requireFamilyId(), accountId);
  }

  Future<String> createAccount({
    required String name,
    required AccountType type,
    required int openingBalanceMinor,
    required String openingDate,
  }) {
    return _guard(
      () => _accounts.createAccount(
        familyId: _requireFamilyId(),
        name: name,
        type: type,
        openingBalanceMinor: openingBalanceMinor,
        openingDate: openingDate,
      ),
    );
  }

  Future<void> updateAccount({
    required String accountId,
    required String name,
    required AccountType type,
    required int openingBalanceMinor,
    required String openingDate,
  }) {
    return _guard(
      () => _accounts.updateAccount(
        familyId: _requireFamilyId(),
        accountId: accountId,
        name: name,
        type: type,
        openingBalanceMinor: openingBalanceMinor,
        openingDate: openingDate,
      ),
    );
  }

  Future<void> archiveAccount(String accountId, {bool archived = true}) {
    return _guard(
      () => _accounts.archiveAccount(
        familyId: _requireFamilyId(),
        accountId: accountId,
        archived: archived,
      ),
    );
  }

  String _requireFamilyId() {
    final familyId = _familyId;
    if (familyId == null) {
      throw StateError('No family bound to AccountsController');
    }
    return familyId;
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    _busy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      return await action();
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    super.dispose();
  }
}
