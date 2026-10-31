import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/recurring_rules_repository.dart';
import '../domain/recurring_rule.dart';
import '../domain/transaction.dart';

/// Recurring rules list + CRUD; screens never touch the repository directly.
class RecurringRulesController extends ChangeNotifier {
  RecurringRulesController({RecurringRulesRepository? repository})
    : _repository = repository ?? RecurringRulesRepository();

  final RecurringRulesRepository _repository;

  String? _familyId;
  List<RecurringRule> _items = const [];
  bool _loading = false;
  bool _busy = false;
  bool _hasReceived = false;
  String? _errorMessage;
  StreamSubscription<List<RecurringRule>>? _sub;

  String? get familyId => _familyId;
  List<RecurringRule> get items => List.unmodifiable(_items);
  bool get loading => _loading && !_hasReceived;
  bool get busy => _busy;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => !loading && _errorMessage == null && _items.isEmpty;

  Future<void> bindFamily(String? familyId) async {
    if (familyId == null || familyId.isEmpty) {
      await _sub?.cancel();
      _sub = null;
      _familyId = null;
      _items = const [];
      _hasReceived = false;
      _loading = false;
      _errorMessage = null;
      notifyListeners();
      return;
    }
    if (_familyId == familyId && _sub != null) return;
    _familyId = familyId;
    await refresh();
  }

  Future<void> refresh() async {
    final familyId = _familyId;
    if (familyId == null) return;

    await _sub?.cancel();
    _sub = null;
    _items = const [];
    _hasReceived = false;
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    _sub = _repository
        .watchRules(familyId)
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
        );
  }

  Future<RecurringRule?> getRule(String ruleId) {
    final familyId = _requireFamilyId();
    return _repository.getRule(familyId, ruleId);
  }

  Future<String> createRule({
    required TransactionType type,
    required String accountId,
    required String categoryId,
    required int amountMinor,
    required String currency,
    required int dayOfMonth,
    required String nextBookingDate,
    String? merchant,
    String? note,
    String? endBookingDate,
  }) async {
    final familyId = _requireFamilyId();
    _busy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      return await _repository.createRule(
        familyId: familyId,
        type: type,
        accountId: accountId,
        categoryId: categoryId,
        amountMinor: amountMinor,
        currency: currency,
        dayOfMonth: dayOfMonth,
        nextBookingDate: nextBookingDate,
        merchant: merchant,
        note: note,
        endBookingDate: endBookingDate,
      );
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Creates a monthly rule after a first manual expense/income save.
  ///
  /// [totalOccurrences] includes the manual first payment; omit for open-ended.
  Future<String> createMonthlyRuleFromTransaction({
    required TransactionType type,
    required String accountId,
    required String categoryId,
    required int amountMinor,
    required String currency,
    required String bookingDate,
    String? merchant,
    String? note,
    int? totalOccurrences,
  }) {
    final dayOfMonth = dayOfMonthFromBookingDate(bookingDate);
    final nextBookingDate = nextBookingDateAfterFirstOccurrence(
      bookingDate: bookingDate,
      dayOfMonth: dayOfMonth,
    );
    String? endBookingDate;
    if (totalOccurrences != null) {
      if (totalOccurrences < 2) {
        throw ArgumentError.value(
          totalOccurrences,
          'totalOccurrences',
          'must be >= 2 when limited (first payment is this save)',
        );
      }
      endBookingDate = endBookingDateForTotalOccurrences(
        firstBookingDate: bookingDate,
        dayOfMonth: dayOfMonth,
        totalOccurrences: totalOccurrences,
      );
    }
    return createRule(
      type: type,
      accountId: accountId,
      categoryId: categoryId,
      amountMinor: amountMinor,
      currency: currency,
      dayOfMonth: dayOfMonth,
      nextBookingDate: nextBookingDate,
      merchant: merchant,
      note: note,
      endBookingDate: endBookingDate,
    );
  }

  Future<void> updateRuleDetails({
    required String ruleId,
    required String accountId,
    required String categoryId,
    required int amountMinor,
    String? merchant,
    String? note,
    String? endBookingDate,
    bool clearEndBookingDate = false,
  }) async {
    final familyId = _requireFamilyId();
    _busy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.updateRule(
        familyId: familyId,
        ruleId: ruleId,
        accountId: accountId,
        categoryId: categoryId,
        amountMinor: amountMinor,
        merchant: merchant,
        note: note,
        endBookingDate: endBookingDate,
        clearEndBookingDate: clearEndBookingDate,
        clearMerchant: merchant == null || merchant.trim().isEmpty,
        clearNote: note == null || note.trim().isEmpty,
      );
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> setActive({required String ruleId, required bool active}) async {
    final familyId = _requireFamilyId();
    _busy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.setActive(
        familyId: familyId,
        ruleId: ruleId,
        active: active,
      );
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> deleteRule(String ruleId) async {
    final familyId = _requireFamilyId();
    _busy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.deleteRule(familyId: familyId, ruleId: ruleId);
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

  String _requireFamilyId() {
    final familyId = _familyId;
    if (familyId == null) {
      throw StateError('No family bound to RecurringRulesController');
    }
    return familyId;
  }

  @override
  void dispose() {
    _sub?.cancel();
    _sub = null;
    super.dispose();
  }
}
