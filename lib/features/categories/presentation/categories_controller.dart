import 'dart:async';

import 'package:flutter/foundation.dart' hide Category;

import '../data/categories_repository.dart';
import '../domain/category.dart';

/// Categories list + create/archive.
class CategoriesController extends ChangeNotifier {
  CategoriesController({CategoriesRepository? categoriesRepository})
    : _categories = categoriesRepository ?? CategoriesRepository();

  final CategoriesRepository _categories;

  String? _familyId;
  List<Category> _items = const [];
  bool _includeArchived = false;
  bool _loading = false;
  bool _busy = false;
  bool _hasReceived = false;
  String? _errorMessage;
  StreamSubscription<List<Category>>? _sub;

  String? get familyId => _familyId;
  List<Category> get items => _items;
  bool get includeArchived => _includeArchived;
  bool get loading => _loading && !_hasReceived;
  bool get busy => _busy;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => !loading && _errorMessage == null && _items.isEmpty;

  List<Category> get expenseCategories =>
      _items.where((c) => c.type == CategoryType.expense).toList();

  List<Category> get incomeCategories =>
      _items.where((c) => c.type == CategoryType.income).toList();

  Stream<List<Category>> watchCategories({
    bool includeArchived = false,
    CategoryType? type,
  }) {
    return _categories.watchCategories(
      _requireFamilyId(),
      includeArchived: includeArchived,
      type: type,
    );
  }

  Future<void> bindFamily(String? familyId) async {
    if (familyId == null || familyId.isEmpty) {
      await _clear();
      return;
    }
    if (_familyId == familyId && _sub != null) return;
    _familyId = familyId;
    await _resubscribe();
  }

  Future<void> setIncludeArchived(bool value) async {
    if (_includeArchived == value) return;
    _includeArchived = value;
    await _resubscribe();
  }

  Future<void> _clear() async {
    await _sub?.cancel();
    _sub = null;
    _familyId = null;
    _items = const [];
    _loading = false;
    _hasReceived = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _resubscribe() async {
    final familyId = _familyId;
    if (familyId == null) return;
    await _sub?.cancel();
    _sub = null;
    _items = const [];
    _hasReceived = false;
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    _sub = _categories
        .watchCategories(familyId, includeArchived: _includeArchived)
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

  Future<String> createCustomCategory({
    required String name,
    required CategoryType type,
    String? icon,
    String? color,
  }) {
    return _guard(
      () => _categories.createCustomCategory(
        familyId: _requireFamilyId(),
        name: name,
        type: type,
        icon: icon,
        color: color,
      ),
    );
  }

  Future<void> archiveCategory(String categoryId, {bool archived = true}) {
    return _guard(
      () => _categories.archiveCategory(
        familyId: _requireFamilyId(),
        categoryId: categoryId,
        archived: archived,
      ),
    );
  }

  String _requireFamilyId() {
    final familyId = _familyId;
    if (familyId == null) {
      throw StateError('No family bound to CategoriesController');
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
    _sub?.cancel();
    _sub = null;
    super.dispose();
  }
}
