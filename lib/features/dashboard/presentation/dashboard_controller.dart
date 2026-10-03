import 'dart:async';

import 'package:flutter/foundation.dart' hide Category;

import '../../budgets/data/budgets_repository.dart';
import '../../budgets/domain/budget.dart';
import '../../categories/data/categories_repository.dart';
import '../../categories/domain/category.dart';
import '../../family/data/family_repository.dart';
import '../data/stats_repository.dart';
import '../domain/month_stats.dart';

/// Typed dashboard snapshot for the home screen.
class DashboardState {
  const DashboardState({
    required this.periodId,
    required this.currency,
    required this.stats,
    required this.alerts,
    required this.categoriesById,
    required this.loading,
    this.errorMessage,
  });

  final String periodId;
  final String currency;
  final MonthStats stats;
  final List<BudgetWithPeriod> alerts;
  final Map<String, Category> categoriesById;
  final bool loading;
  final String? errorMessage;

  static DashboardState initial(String periodId) => DashboardState(
    periodId: periodId,
    currency: 'EUR',
    stats: MonthStats.empty,
    alerts: const [],
    categoriesById: const {},
    loading: true,
  );
}

/// Subscribes to stats, budgets, categories, and family currency.
class DashboardController extends ChangeNotifier {
  DashboardController({
    StatsRepository? statsRepository,
    BudgetsRepository? budgetsRepository,
    CategoriesRepository? categoriesRepository,
    FamilyRepository? familyRepository,
  }) : _stats = statsRepository ?? StatsRepository(),
       _budgets = budgetsRepository ?? BudgetsRepository(),
       _categories = categoriesRepository ?? CategoriesRepository(),
       _family = familyRepository ?? FamilyRepository();

  final StatsRepository _stats;
  final BudgetsRepository _budgets;
  final CategoriesRepository _categories;
  final FamilyRepository _family;

  String? _familyId;
  final List<StreamSubscription<dynamic>> _subs = [];

  MonthStats? _statsData;
  List<BudgetWithPeriod> _budgetsWithPeriod = const [];
  Map<String, Category> _categoriesById = const {};
  String _currency = 'EUR';
  String _periodId = currentBudgetPeriodId();
  bool _loading = false;
  bool _hasReceivedStats = false;
  String? _errorMessage;

  String? get familyId => _familyId;

  DashboardState get state {
    final alerts = _budgetsWithPeriod.where((b) {
      final p = b.period;
      return p.threshold80Notified ||
          p.threshold100Notified ||
          p.thresholdState(b.budget.limitAmountMinor) !=
              BudgetThresholdState.ok;
    }).toList();

    return DashboardState(
      periodId: _periodId,
      currency: _currency,
      stats:
          _statsData ??
          MonthStats(
            id: _periodId,
            totalIncomeMinor: 0,
            totalExpenseMinor: 0,
            incomeByCategory: const {},
            expenseByCategory: const {},
            incomeByAccount: const {},
            expenseByAccount: const {},
          ),
      alerts: alerts,
      categoriesById: _categoriesById,
      loading: _loading && !_hasReceivedStats,
      errorMessage: _errorMessage,
    );
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

  Future<void> _clear() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    _familyId = null;
    _statsData = null;
    _budgetsWithPeriod = const [];
    _categoriesById = const {};
    _currency = 'EUR';
    _loading = false;
    _hasReceivedStats = false;
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
    _statsData = null;
    _budgetsWithPeriod = const [];
    _hasReceivedStats = false;
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    _subs.add(
      _stats
          .watchMonthStats(familyId, _periodId)
          .listen(
            (stats) {
              _statsData = stats;
              _hasReceivedStats = true;
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
          .watchBudgetsWithPeriod(familyId, _periodId)
          .listen(
            (items) {
              _budgetsWithPeriod = items;
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
