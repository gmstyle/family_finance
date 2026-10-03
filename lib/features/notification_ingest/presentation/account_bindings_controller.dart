import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../accounts/data/accounts_repository.dart';
import '../../accounts/domain/account.dart';
import '../data/account_bindings_repository.dart';
import '../domain/account_binding.dart';

/// Package → account bindings for notification ingest.
class AccountBindingsController extends ChangeNotifier {
  AccountBindingsController({
    AccountBindingsRepository? bindingsRepository,
    AccountsRepository? accountsRepository,
  }) : _bindings = bindingsRepository ?? AccountBindingsRepository(),
       _accounts = accountsRepository ?? AccountsRepository();

  final AccountBindingsRepository _bindings;
  final AccountsRepository _accounts;

  String? _familyId;
  List<AccountBinding> _bindingsList = const [];
  List<Account> _accountsList = const [];
  bool _loading = false;
  bool _busy = false;
  bool _hasReceivedBindings = false;
  bool _hasReceivedAccounts = false;
  String? _errorMessage;
  final List<StreamSubscription<dynamic>> _subs = [];

  String? get familyId => _familyId;
  List<AccountBinding> get bindings => _bindingsList;
  List<Account> get accounts => _accountsList;
  bool get loading =>
      _loading && (!_hasReceivedBindings || !_hasReceivedAccounts);
  bool get busy => _busy;
  String? get errorMessage => _errorMessage;

  Map<String, AccountBinding> get bindingsByPackage => {
    for (final b in _bindingsList) b.packageName: b,
  };

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
    _bindingsList = const [];
    _accountsList = const [];
    _loading = false;
    _hasReceivedBindings = false;
    _hasReceivedAccounts = false;
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
    _bindingsList = const [];
    _accountsList = const [];
    _hasReceivedBindings = false;
    _hasReceivedAccounts = false;
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    _subs.add(
      _bindings
          .watchBindings(familyId)
          .listen(
            (items) {
              _bindingsList = items;
              _hasReceivedBindings = true;
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
      _accounts
          .watchAccounts(familyId)
          .listen(
            (items) {
              _accountsList = items;
              _hasReceivedAccounts = true;
              _loading = false;
              notifyListeners();
            },
            onError: (Object e) {
              _errorMessage = e.toString();
              _loading = false;
              notifyListeners();
            },
          ),
    );
  }

  Future<void> setBinding({
    required String packageName,
    required String accountId,
  }) {
    return _guard(
      () => _bindings.setBinding(
        familyId: _requireFamilyId(),
        packageName: packageName,
        accountId: accountId,
      ),
    );
  }

  Future<void> clearBinding(String packageName) {
    return _guard(
      () => _bindings.clearBinding(
        familyId: _requireFamilyId(),
        packageName: packageName,
      ),
    );
  }

  String _requireFamilyId() {
    final familyId = _familyId;
    if (familyId == null) {
      throw StateError('No family bound to AccountBindingsController');
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
