import 'dart:async';

import 'package:flutter/foundation.dart' hide Category;

import '../../categories/data/categories_repository.dart';
import '../../categories/domain/category.dart';
import '../../family/data/family_repository.dart';
import '../data/budgets_repository.dart';
import '../domain/budget.dart';

/// Budgets list + CRUD; screens never touch [BudgetsRepository] directly.
class BudgetsController extends ChangeNotifier {
  BudgetsController({
    BudgetsRepository? budgetsRepository,
    CategoriesRepository? categoriesRepository,
    FamilyRepository? familyRepository,
  }) : _budgets = budgetsRepository ?? BudgetsRepository(),
       _categories = categoriesRepository ?? CategoriesRepository(),
       _family = familyRepository ?? FamilyRepository();

  final BudgetsRepository _budgets;
  final CategoriesRepository _categories;
  final FamilyRepository _family;

  String? _familyId;
  String _periodId = currentBudgetPeriodId();
  List<BudgetWithPeriod> _items = const [];
  List<Budget> _budgetsOnly = const [];
  Map<String, Category> _categoriesById = const {};
  List<Category> _expenseCategories = const [];
  String _currency = 'EUR';
  bool _loading = false;
  bool _busy = false;
  bool _hasReceived = false;
  String? _errorMessage;

  final List<StreamSubscription<dynamic>> _subs = [];

  String? get familyId => _familyId;
  String get periodId => _periodId;
  List<BudgetWithPeriod> get items => _items;
  List<Budget> get budgets => _budgetsOnly;
  Map<String, Category> get categoriesById => _categoriesById;
  List<Category> get expenseCategories => _expenseCategories;
  String get currency => _currency;
  bool get loading => _loading && !_hasReceived;
  bool get busy => _busy;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => !loading && _errorMessage == null && _items.isEmpty;

  /// Categories available for a new budget (expense, not already budgeted).
  List<Category> get availableExpenseCategories {
    final used = {for (final b in _budgetsOnly) b.categoryId};
    return _expenseCategories.where((c) => !used.contains(c.id)).toList();
  }

  Future<void> bindFamily(String? familyId) async {
    if (familyId == null || familyId.isEmpty) {
      await _clear();
      return;
    }
    if (_familyId == familyId && _subs.isNotEmpty) return;
    _familyId = familyId;
    _periodId = currentBudgetPeriodId();
    await _resubscribe();
  }

  /// Move the watched budget period by [deltaMonths] (e.g. `-1` = previous).
  Future<void> shiftPeriod(int deltaMonths) async {
    final next = shiftBudgetPeriodId(_periodId, deltaMonths);
    if (next == _periodId) return;
    _periodId = next;
    await _resubscribe();
  }

  Future<void> resetPeriodToCurrent() async {
    final current = currentBudgetPeriodId();
    if (current == _periodId) return;
    _periodId = current;
    await _resubscribe();
  }

  Future<void> _clear() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    _familyId = null;
    _items = const [];
    _budgetsOnly = const [];
    _categoriesById = const {};
    _expenseCategories = const [];
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
    _budgetsOnly = const [];
    _hasReceived = false;
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    _subs.add(
      _budgets
          .watchBudgetsWithPeriod(familyId, _periodId)
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
      _budgets
          .watchBudgets(familyId)
          .listen(
            (budgets) {
              _budgetsOnly = budgets;
              notifyListeners();
            },
            onError: (Object e) {
              _errorMessage = e.toString();
              notifyListeners();
            },
          ),
    );

    _subs.add(
      _categories
          .watchCategories(familyId, includeArchived: true)
          .listen(
            (cats) {
              _categoriesById = {for (final c in cats) c.id: c};
              notifyListeners();
            },
            onError: (Object e) {
              _errorMessage = e.toString();
              notifyListeners();
            },
          ),
    );

    _subs.add(
      _categories
          .watchCategories(familyId, type: CategoryType.expense)
          .listen(
            (cats) {
              _expenseCategories = cats;
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

  Future<Budget?> getBudget(String budgetId) {
    final familyId = _familyId;
    if (familyId == null) return Future.value(null);
    return _budgets.getBudget(familyId, budgetId);
  }

  Future<String> createBudget({
    required String categoryId,
    required int limitAmountMinor,
  }) {
    return _guard(() {
      final familyId = _familyId;
      if (familyId == null) {
        throw StateError('No family bound');
      }
      return _budgets.createBudget(
        familyId: familyId,
        categoryId: categoryId,
        limitAmountMinor: limitAmountMinor,
      );
    });
  }

  Future<void> updateBudget({
    required String budgetId,
    required int limitAmountMinor,
  }) {
    return _guard(() {
      final familyId = _familyId;
      if (familyId == null) {
        throw StateError('No family bound');
      }
      return _budgets.updateBudget(
        familyId: familyId,
        budgetId: budgetId,
        limitAmountMinor: limitAmountMinor,
      );
    });
  }

  Future<void> deleteBudget(String budgetId) {
    return _guard(() {
      final familyId = _familyId;
      if (familyId == null) {
        throw StateError('No family bound');
      }
      return _budgets.deleteBudget(familyId: familyId, budgetId: budgetId);
    });
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
