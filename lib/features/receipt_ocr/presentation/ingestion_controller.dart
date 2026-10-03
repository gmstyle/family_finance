import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../accounts/data/accounts_repository.dart';
import '../../family/data/family_repository.dart';
import '../../notification_ingest/domain/bank_notification_parser.dart';
import '../../accounts/domain/account.dart';
import '../data/ingestion_repository.dart';
import '../domain/ingestion.dart';
import '../domain/italian_receipt_parser.dart';

/// Ingestion drafts queue + confirm/discard/OCR orchestration.
class IngestionController extends ChangeNotifier {
  IngestionController({
    IngestionRepository? ingestionRepository,
    AccountsRepository? accountsRepository,
    FamilyRepository? familyRepository,
  }) : _ingestion = ingestionRepository ?? IngestionRepository(),
       _accounts = accountsRepository ?? AccountsRepository(),
       _family = familyRepository ?? FamilyRepository();

  final IngestionRepository _ingestion;
  final AccountsRepository _accounts;
  final FamilyRepository _family;

  String? _familyId;
  List<IngestionDraft> _pending = const [];
  List<Account> _accountsList = const [];
  String _currency = 'EUR';
  bool _loading = false;
  bool _busy = false;
  bool _hasReceived = false;
  String? _errorMessage;
  final List<StreamSubscription<dynamic>> _subs = [];

  String? get familyId => _familyId;
  List<IngestionDraft> get pending => _pending;
  List<Account> get accounts => _accountsList;
  String get currency => _currency;
  bool get loading => _loading && !_hasReceived;
  bool get busy => _busy;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => !loading && _errorMessage == null && _pending.isEmpty;

  Stream<IngestionDraft?> watchDraft(String dedupKey) =>
      _ingestion.watchDraft(_requireFamilyId(), dedupKey);

  Stream<List<Account>> watchAccounts() =>
      _accounts.watchAccounts(_requireFamilyId());

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
    _pending = const [];
    _accountsList = const [];
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
    _pending = const [];
    _hasReceived = false;
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    _subs.add(
      _ingestion
          .watchPendingQueue(familyId)
          .listen(
            (items) {
              _pending = items;
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
      _accounts
          .watchAccounts(familyId)
          .listen(
            (items) {
              _accountsList = items;
              notifyListeners();
            },
            onError: (Object e) {
              _errorMessage = e.toString();
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

  Future<IngestionDraft?> getDraft(String dedupKey) =>
      _ingestion.getDraft(_requireFamilyId(), dedupKey);

  Future<String> createDraftFromOcr({
    required ParsedReceipt parsed,
    String? defaultAccountId,
  }) {
    return _guard(
      () => _ingestion.createDraftFromOcr(
        familyId: _requireFamilyId(),
        parsed: parsed,
        defaultAccountId: defaultAccountId,
      ),
    );
  }

  Future<NotificationDraftResult> createDraftFromNotification({
    required ParsedBankNotification parsed,
  }) {
    return _guard(
      () => _ingestion.createDraftFromNotification(
        familyId: _requireFamilyId(),
        parsed: parsed,
      ),
    );
  }

  Future<void> updateDraft({
    required String dedupKey,
    required IngestionDraftUpdate update,
  }) {
    return _guard(
      () => _ingestion.updateDraft(
        familyId: _requireFamilyId(),
        dedupKey: dedupKey,
        update: update,
      ),
    );
  }

  Future<String> confirmDraft({
    required String dedupKey,
    required IngestionDraftUpdate update,
    String? currency,
    bool saveMerchantRule = true,
  }) {
    return _guard(
      () => _ingestion.confirmDraft(
        familyId: _requireFamilyId(),
        dedupKey: dedupKey,
        update: update,
        currency: currency ?? _currency,
        saveMerchantRule: saveMerchantRule,
      ),
    );
  }

  Future<void> discardDraft(String dedupKey) {
    return _guard(
      () => _ingestion.discardDraft(
        familyId: _requireFamilyId(),
        dedupKey: dedupKey,
      ),
    );
  }

  String _requireFamilyId() {
    final familyId = _familyId;
    if (familyId == null) {
      throw StateError('No family bound to IngestionController');
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
