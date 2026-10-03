import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/locale/locale_controller.dart';
import '../../../core/money/money.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/ui/app_page.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/ledger_async_body.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../categories/data/categories_repository.dart';
import '../../family/data/family_repository.dart';
import '../../ledger/ledger_labels.dart';
import '../data/budgets_repository.dart';

class BudgetsListScreen extends StatelessWidget {
  const BudgetsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthController>();
    final familyId = auth.familyId;
    final locale = context.watch<LocaleController>().locale.languageCode;
    final budgetsRepo = context.read<BudgetsRepository>();
    final categoriesRepo = context.read<CategoriesRepository>();
    final familyRepo = context.read<FamilyController>().repository;
    final periodId = currentBudgetPeriodId();

    if (familyId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.budgetsTitle)),
        body: Center(child: Text(l10n.familyMissing)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.budgetsTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: Center(
              child: Text(
                l10n.budgetPeriodLabel(periodId),
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.budgetNew),
        child: const Icon(Icons.add),
      ),
      body: AppPage(
        child: StreamBuilder<FamilyInfo?>(
          stream: familyRepo.watchFamily(familyId),
          builder: (context, familySnap) {
            final currency = familySnap.data?.currency ?? 'EUR';
            return StreamBuilder<List<Category>>(
              stream: categoriesRepo.watchCategories(familyId),
              builder: (context, catSnap) {
                final categories = {
                  for (final c in catSnap.data ?? const <Category>[]) c.id: c,
                };
                return StreamBuilder<List<BudgetWithPeriod>>(
                  stream: budgetsRepo.watchBudgetsWithPeriod(
                    familyId,
                    periodId,
                  ),
                  builder: (context, snap) {
                    final error = snap.hasError ? snap.error.toString() : null;
                    final items = snap.data;

                    return LedgerAsyncBody(
                      isLoading:
                          snap.connectionState == ConnectionState.waiting &&
                          items == null,
                      errorMessage: error,
                      isEmpty: items != null && items.isEmpty,
                      emptyMessage: l10n.budgetsEmpty,
                      child: ListView(
                        padding: AppInsets.pageCompact,
                        children: [
                          for (final item
                              in items ?? const <BudgetWithPeriod>[])
                            _BudgetTile(
                              item: item,
                              currency: currency,
                              locale: locale,
                              categoryLabel: () {
                                final cat = categories[item.budget.categoryId];
                                if (cat == null) {
                                  return item.budget.categoryId;
                                }
                                return categoryLabel(l10n, cat);
                              }(),
                              onTap: () => context.push(
                                AppRoutes.budgetEditPath(item.budget.id),
                              ),
                              onDelete: () => budgetsRepo.deleteBudget(
                                familyId: familyId,
                                budgetId: item.budget.id,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _BudgetTile extends StatelessWidget {
  const _BudgetTile({
    required this.item,
    required this.currency,
    required this.locale,
    required this.categoryLabel,
    required this.onTap,
    required this.onDelete,
  });

  final BudgetWithPeriod item;
  final String currency;
  final String locale;
  final String categoryLabel;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final extras = AppExtraColors.of(context);
    final budget = item.budget;
    final period = item.period;
    final limit = budget.limitAmountMinor;
    final spent = period.spentAmountMinor;
    final progress = limit <= 0 ? 0.0 : (spent / limit).clamp(0.0, 1.5);
    final state = period.thresholdState(limit);
    final barColor = switch (state) {
      BudgetThresholdState.atOrOver100 => extras.expense,
      BudgetThresholdState.atOrOver80 => theme.colorScheme.tertiary,
      BudgetThresholdState.ok => extras.income,
    };

    String? alertLabel;
    if (period.threshold100Notified ||
        state == BudgetThresholdState.atOrOver100) {
      alertLabel = l10n.budgetAlert100;
    } else if (period.threshold80Notified ||
        state == BudgetThresholdState.atOrOver80) {
      alertLabel = l10n.budgetAlert80;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        borderRadius: AppRadius.mdAll,
        onTap: onTap,
        child: Padding(
          padding: AppInsets.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      categoryLabel,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(l10n.actionDelete),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.budgetSpentOfLimit(
                  '${Money.formatFromMinor(spent, locale)} $currency',
                  '${Money.formatFromMinor(limit, locale)} $currency',
                ),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              ClipRRect(
                borderRadius: AppRadius.fullAll,
                child: LinearProgressIndicator(
                  value: progress > 1 ? 1 : progress,
                  minHeight: AppSizes.progressBarHeight,
                  color: barColor,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
              if (alertLabel != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  alertLabel,
                  style: theme.textTheme.labelMedium?.copyWith(color: barColor),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

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

  bool get _isEdit => widget.budgetId != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final familyId = context.read<AuthController>().familyId;
    final locale = context.read<LocaleController>().locale.languageCode;
    if (familyId == null || widget.budgetId == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final budget = await context.read<BudgetsRepository>().getBudget(
        familyId,
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
      final repo = context.read<BudgetsRepository>();
      if (_isEdit) {
        await repo.updateBudget(
          familyId: familyId,
          budgetId: widget.budgetId!,
          limitAmountMinor: limitMinor,
        );
      } else {
        await repo.createBudget(
          familyId: familyId,
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
    final familyId = context.watch<AuthController>().familyId;

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
                      StreamBuilder<List<Category>>(
                        stream: context
                            .read<CategoriesRepository>()
                            .watchCategories(
                              familyId,
                              type: CategoryType.expense,
                            ),
                        builder: (context, catSnap) {
                          return StreamBuilder<List<Budget>>(
                            stream: context
                                .read<BudgetsRepository>()
                                .watchBudgets(familyId),
                            builder: (context, budgetSnap) {
                              final used = {
                                for (final b
                                    in budgetSnap.data ?? const <Budget>[])
                                  b.categoryId,
                              };
                              final available =
                                  (catSnap.data ?? const <Category>[])
                                      .where((c) => !used.contains(c.id))
                                      .toList();
                              return DropdownButtonFormField<String>(
                                // ignore: deprecated_member_use
                                value: available.any((c) => c.id == _categoryId)
                                    ? _categoryId
                                    : null,
                                decoration: InputDecoration(
                                  labelText: l10n.budgetCategory,
                                ),
                                items: available
                                    .map(
                                      (c) => DropdownMenuItem(
                                        value: c.id,
                                        child: Text(categoryLabel(l10n, c)),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _categoryId = v),
                                validator: (v) => (v == null || v.isEmpty)
                                    ? l10n.budgetCategoryRequired
                                    : null,
                              );
                            },
                          );
                        },
                      )
                    else if (_existing != null && familyId != null)
                      StreamBuilder<List<Category>>(
                        stream: context
                            .read<CategoriesRepository>()
                            .watchCategories(familyId),
                        builder: (context, snap) {
                          final matches = (snap.data ?? const <Category>[])
                              .where((c) => c.id == _existing!.categoryId);
                          final cat = matches.isEmpty ? null : matches.first;
                          return InputDecorator(
                            decoration: InputDecoration(
                              labelText: l10n.budgetCategory,
                              helperText: l10n.budgetCategoryImmutableHint,
                            ),
                            child: Text(
                              cat == null
                                  ? _existing!.categoryId
                                  : categoryLabel(l10n, cat),
                            ),
                          );
                        },
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
