import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../data/transactions_repository.dart';
import '../domain/transaction.dart';

/// Paginated transaction list with filters and a live head window.
///
/// Listens to the newest [TransactionsRepository.defaultPageSize] docs for the
/// active filter set. "Load more" appends older one-shot pages; if the live
/// window's last document changes (new/removed head docs), older pages are
/// cleared so the list stays consistent.
class TransactionsController extends ChangeNotifier {
  TransactionsController({TransactionsRepository? repository})
    : _repository = repository ?? TransactionsRepository();

  final TransactionsRepository _repository;

  final List<LedgerTransaction> _liveItems = [];
  final List<LedgerTransaction> _olderItems = [];
  TransactionFilters _filters = const TransactionFilters();
  DocumentSnapshot<Map<String, dynamic>>? _liveLastDoc;
  DocumentSnapshot<Map<String, dynamic>>? _olderLastDoc;
  bool _liveHasMore = false;
  bool _olderHasMore = false;
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasReceivedLive = false;
  String? _errorMessage;
  String? _familyId;
  StreamSubscription<TransactionPage>? _liveSub;

  List<LedgerTransaction> get items {
    if (_olderItems.isEmpty) return List.unmodifiable(_liveItems);
    final liveIds = _liveItems.map((e) => e.id).toSet();
    return List.unmodifiable([
      ..._liveItems,
      ..._olderItems.where((t) => !liveIds.contains(t.id)),
    ]);
  }

  TransactionFilters get filters => _filters;
  bool get hasMore => _olderItems.isEmpty ? _liveHasMore : _olderHasMore;
  bool get loading => _loading && !_hasReceivedLive;
  bool get loadingMore => _loadingMore;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => !loading && _errorMessage == null && _liveItems.isEmpty;
  String? get familyId => _familyId;

  Future<void> bindFamily(String? familyId) async {
    if (familyId == null || familyId.isEmpty) {
      await _liveSub?.cancel();
      _liveSub = null;
      _familyId = null;
      _liveItems.clear();
      _olderItems.clear();
      _hasReceivedLive = false;
      _loading = false;
      notifyListeners();
      return;
    }
    if (_familyId == familyId && _liveSub != null) return;
    _familyId = familyId;
    await refresh();
  }

  Future<void> setFilters(TransactionFilters filters) async {
    _filters = filters;
    await refresh();
  }

  /// Re-subscribes to the live head for the current family + filters.
  Future<void> refresh() async {
    final familyId = _familyId;
    if (familyId == null) return;
    _subscribeLive(familyId);
  }

  void _subscribeLive(String familyId) {
    _liveSub?.cancel();
    _liveSub = null;
    _liveItems.clear();
    _olderItems.clear();
    _liveLastDoc = null;
    _olderLastDoc = null;
    _liveHasMore = false;
    _olderHasMore = false;
    _hasReceivedLive = false;
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    _liveSub = _repository
        .watchTransactions(familyId: familyId, filters: _filters)
        .listen(
          _onLivePage,
          onError: (Object e) {
            _errorMessage = e.toString();
            _loading = false;
            notifyListeners();
          },
        );
  }

  void _onLivePage(TransactionPage page) {
    final previousLastId = _liveLastDoc?.id;
    final nextLastId = page.lastDocument?.id;

    // Live window membership shifted — drop older pages to avoid gaps/dupes.
    if (_olderItems.isNotEmpty && previousLastId != nextLastId) {
      _olderItems.clear();
      _olderLastDoc = null;
      _olderHasMore = false;
    } else if (_olderItems.isNotEmpty) {
      final liveIds = page.items.map((e) => e.id).toSet();
      _olderItems.removeWhere((t) => liveIds.contains(t.id));
    }

    _liveItems
      ..clear()
      ..addAll(page.items);
    _liveLastDoc = page.lastDocument;
    _liveHasMore = page.hasMore;
    _hasReceivedLive = true;
    _loading = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadMore() async {
    final familyId = _familyId;
    if (familyId == null || !hasMore || _loadingMore || loading) return;

    final startAfter = _olderItems.isEmpty ? _liveLastDoc : _olderLastDoc;
    if (startAfter == null) return;

    _loadingMore = true;
    notifyListeners();
    try {
      final page = await _repository.fetchTransactions(
        familyId: familyId,
        filters: _filters,
        startAfter: startAfter,
      );
      final existingIds = {
        ..._liveItems.map((e) => e.id),
        ..._olderItems.map((e) => e.id),
      };
      _olderItems.addAll(page.items.where((t) => !existingIds.contains(t.id)));
      _olderLastDoc = page.lastDocument;
      _olderHasMore = page.hasMore;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  Future<LedgerTransaction?> getTransaction(String transactionId) {
    final familyId = _requireFamilyId();
    return _repository.getTransaction(familyId, transactionId);
  }

  Future<String> createManualTransaction({
    required TransactionType type,
    required String accountId,
    required String categoryId,
    required int amountMinor,
    required String currency,
    required String bookingDate,
    String? merchant,
    String? note,
  }) {
    final familyId = _requireFamilyId();
    return _repository.createManualTransaction(
      familyId: familyId,
      type: type,
      accountId: accountId,
      categoryId: categoryId,
      amountMinor: amountMinor,
      currency: currency,
      bookingDate: bookingDate,
      merchant: merchant,
      note: note,
    );
  }

  Future<void> updateManualTransaction({
    required String transactionId,
    required TransactionType type,
    required String accountId,
    required String categoryId,
    required int amountMinor,
    required String bookingDate,
    String? merchant,
    String? note,
  }) {
    final familyId = _requireFamilyId();
    return _repository.updateManualTransaction(
      familyId: familyId,
      transactionId: transactionId,
      type: type,
      accountId: accountId,
      categoryId: categoryId,
      amountMinor: amountMinor,
      bookingDate: bookingDate,
      merchant: merchant,
      note: note,
    );
  }

  Future<void> deleteTransaction(LedgerTransaction tx) async {
    final familyId = _requireFamilyId();
    if (tx.type == TransactionType.transfer && tx.transferId != null) {
      await _repository.deleteTransfer(tx.transferId!);
    } else {
      await _repository.deleteManualTransaction(
        familyId: familyId,
        transactionId: tx.id,
      );
    }
  }

  Future<String> createTransfer({
    required String sourceAccountId,
    required String destinationAccountId,
    required int amountMinor,
    required String bookingDate,
    String? note,
  }) {
    return _repository.createTransfer(
      sourceAccountId: sourceAccountId,
      destinationAccountId: destinationAccountId,
      amountMinor: amountMinor,
      bookingDate: bookingDate,
      note: note,
    );
  }

  Future<void> deleteTransfer(String transferId) {
    return _repository.deleteTransfer(transferId);
  }

  String _requireFamilyId() {
    final familyId = _familyId;
    if (familyId == null) {
      throw StateError('No family bound to TransactionsController');
    }
    return familyId;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _liveSub?.cancel();
    _liveSub = null;
    super.dispose();
  }
}
