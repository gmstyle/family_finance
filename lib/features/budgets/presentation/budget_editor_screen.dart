import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/locale/locale_controller.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/ui/app_page.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../ledger/ledger_labels.dart';
import '../domain/budget.dart';
import 'budgets_controller.dart';

class BudgetEditorScreen extends StatefulWidget {
  const BudgetEditorScreen({super.key, this.budgetId});

  final String? budgetId;

  @override
  State<BudgetEditorScreen> createState() => _BudgetEditorScreenState();
}

class _BudgetEditorScreenState extends State<BudgetEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _limit = TextEditingController();
  String? _categoryId;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  Budget? _existing;
  String? _boundFamilyId;

  bool get _isEdit => widget.budgetId != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final familyId = context.watch<AuthController>().familyId;
    if (familyId != _boundFamilyId) {
      _boundFamilyId = familyId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<BudgetsController>().bindFamily(familyId);
        if (_loading) _load();
      });
    }
  }

  Future<void> _load() async {
    final familyId = context.read<AuthController>().familyId;
    final locale = context.read<LocaleController>().locale.languageCode;
    if (familyId == null || widget.budgetId == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final budget = await context.read<BudgetsController>().getBudget(
        widget.budgetId!,
      );
      if (budget == null) {
        setState(() {
          _error = AppLocalizations.of(context)!.ledgerNotFound;
          _loading = false;
        });
        return;
      }
      _existing = budget;
      _categoryId = budget.categoryId;
      _limit.text = Money.formatFromMinor(budget.limitAmountMinor, locale);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;
    final familyId = context.read<AuthController>().familyId;
    if (familyId == null) return;
    final locale = context.read<LocaleController>().locale.languageCode;

    if (!_isEdit && (_categoryId == null || _categoryId!.isEmpty)) {
      setState(() => _error = l10n.budgetCategoryRequired);
      return;
    }

    late final int limitMinor;
    try {
      limitMinor = Money.parseToMinor(_limit.text, locale);
    } catch (_) {
      setState(() => _error = l10n.moneyInvalid);
      return;
    }
    if (limitMinor <= 0) {
      setState(() => _error = l10n.moneyInvalid);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final ctrl = context.read<BudgetsController>();
      if (_isEdit) {
        await ctrl.updateBudget(
          budgetId: widget.budgetId!,
          limitAmountMinor: limitMinor,
        );
      } else {
        await ctrl.createBudget(
          categoryId: _categoryId!,
          limitAmountMinor: limitMinor,
        );
      }
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _limit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final familyId = context.select((AuthController c) => c.familyId);
    final ctrl = context.watch<BudgetsController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? l10n.budgetEditTitle : l10n.budgetCreateTitle),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : AppPage(
              form: true,
              padding: AppInsets.page,
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    if (!_isEdit && familyId != null)
                      DropdownButtonFormField<String>(
                        // ignore: deprecated_member_use
                        value:
                            ctrl.availableExpenseCategories.any(
                              (c) => c.id == _categoryId,
                            )
                            ? _categoryId
                            : null,
                        decoration: InputDecoration(
                          labelText: l10n.budgetCategory,
                        ),
                        items: ctrl.availableExpenseCategories
                            .map(
                              (c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(categoryLabel(l10n, c)),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _categoryId = v),
                        validator: (v) => (v == null || v.isEmpty)
                            ? l10n.budgetCategoryRequired
                            : null,
                      )
                    else if (_existing != null && familyId != null)
                      InputDecorator(
                        decoration: InputDecoration(
                          labelText: l10n.budgetCategory,
                          helperText: l10n.budgetCategoryImmutableHint,
                        ),
                        child: Text(() {
                          final cat =
                              ctrl.categoriesById[_existing!.categoryId];
                          if (cat == null) return _existing!.categoryId;
                          return categoryLabel(l10n, cat);
                        }()),
                      ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _limit,
                      decoration: InputDecoration(labelText: l10n.budgetLimit),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return l10n.moneyInvalid;
                        }
                        try {
                          final n = Money.parseToMinor(
                            v,
                            context
                                .read<LocaleController>()
                                .locale
                                .languageCode,
                          );
                          if (n <= 0) return l10n.moneyInvalid;
                          return null;
                        } catch (_) {
                          return l10n.moneyInvalid;
                        }
                      },
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _error!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: AppSizes.buttonProgress,
                              height: AppSizes.buttonProgress,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.actionSave),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
