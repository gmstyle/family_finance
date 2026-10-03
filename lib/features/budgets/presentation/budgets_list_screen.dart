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
import '../../ledger/ledger_labels.dart';
import '../domain/budget.dart';
import 'budgets_controller.dart';

class BudgetsListScreen extends StatefulWidget {
  const BudgetsListScreen({super.key});

  @override
  State<BudgetsListScreen> createState() => _BudgetsListScreenState();
}

class _BudgetsListScreenState extends State<BudgetsListScreen> {
  String? _boundFamilyId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final familyId = context.watch<AuthController>().familyId;
    if (familyId != _boundFamilyId) {
      _boundFamilyId = familyId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<BudgetsController>().bindFamily(familyId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final familyId = context.select((AuthController c) => c.familyId);
    final locale = context.watch<LocaleController>().locale.languageCode;
    final ctrl = context.watch<BudgetsController>();

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
                l10n.budgetPeriodLabel(ctrl.periodId),
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
        child: LedgerAsyncBody(
          isLoading: ctrl.loading,
          errorMessage: ctrl.errorMessage,
          isEmpty: ctrl.isEmpty,
          emptyMessage: l10n.budgetsEmpty,
          child: ListView(
            padding: AppInsets.pageCompact,
            children: [
              for (final item in ctrl.items)
                _BudgetTile(
                  item: item,
                  currency: ctrl.currency,
                  locale: locale,
                  categoryLabel: () {
                    final cat = ctrl.categoriesById[item.budget.categoryId];
                    if (cat == null) {
                      return item.budget.categoryId;
                    }
                    return categoryLabel(l10n, cat);
                  }(),
                  onTap: () =>
                      context.push(AppRoutes.budgetEditPath(item.budget.id)),
                  onDelete: () => ctrl.deleteBudget(item.budget.id),
                ),
            ],
          ),
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
