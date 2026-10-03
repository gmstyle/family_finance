import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../family/data/family_repository.dart';
import '../data/goals_repository.dart';
import '../domain/goal.dart';

/// Goals list + CRUD + contributions.
class GoalsController extends ChangeNotifier {
  GoalsController({
    GoalsRepository? goalsRepository,
    FamilyRepository? familyRepository,
  }) : _goals = goalsRepository ?? GoalsRepository(),
       _family = familyRepository ?? FamilyRepository();

  final GoalsRepository _goals;
  final FamilyRepository _family;

  String? _familyId;
  List<Goal> _items = const [];
  String _currency = 'EUR';
  bool _loading = false;
  bool _busy = false;
  bool _hasReceived = false;
  String? _errorMessage;
  final List<StreamSubscription<dynamic>> _subs = [];

  String? get familyId => _familyId;
  List<Goal> get items => _items;
  String get currency => _currency;
  bool get loading => _loading && !_hasReceived;
  bool get busy => _busy;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => !loading && _errorMessage == null && _items.isEmpty;

  Stream<Goal?> watchGoal(String goalId) =>
      _goals.watchGoal(_requireFamilyId(), goalId);

  Stream<List<GoalContribution>> watchContributions(String goalId) =>
      _goals.watchContributions(_requireFamilyId(), goalId);

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
      _goals
          .watchGoals(familyId)
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

  Future<Goal?> getGoal(String goalId) =>
      _goals.getGoal(_requireFamilyId(), goalId);

  Future<String> createGoal({
    required String name,
    required int targetAmountMinor,
    String? dueDate,
  }) {
    return _guard(
      () => _goals.createGoal(
        familyId: _requireFamilyId(),
        name: name,
        targetAmountMinor: targetAmountMinor,
        dueDate: dueDate,
      ),
    );
  }

  Future<void> updateGoal({
    required String goalId,
    required String name,
    required int targetAmountMinor,
    String? dueDate,
  }) {
    return _guard(
      () => _goals.updateGoal(
        familyId: _requireFamilyId(),
        goalId: goalId,
        name: name,
        targetAmountMinor: targetAmountMinor,
        dueDate: dueDate,
      ),
    );
  }

  Future<void> deleteGoal(String goalId) {
    return _guard(
      () => _goals.deleteGoal(familyId: _requireFamilyId(), goalId: goalId),
    );
  }

  Future<String> addContribution({
    required String goalId,
    required int amountMinor,
    String? bookingDate,
  }) {
    return _guard(
      () => _goals.addContribution(
        familyId: _requireFamilyId(),
        goalId: goalId,
        amountMinor: amountMinor,
        bookingDate: bookingDate,
      ),
    );
  }

  String _requireFamilyId() {
    final familyId = _familyId;
    if (familyId == null) {
      throw StateError('No family bound to GoalsController');
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
