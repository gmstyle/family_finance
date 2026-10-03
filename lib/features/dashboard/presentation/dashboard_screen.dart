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
import '../../budgets/data/budgets_repository.dart';
import '../../categories/data/categories_repository.dart';
import '../../family/data/family_repository.dart';
import '../../ledger/ledger_labels.dart';
import '../data/stats_repository.dart';

/// Home dashboard: monthly rollup from `stats/{yyyy-MM}` + budget alerts.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthController>();
    final familyId = auth.familyId;
    final locale = context.watch<LocaleController>().locale.languageCode;
    final periodId = currentBudgetPeriodId();
    final statsRepo = context.read<StatsRepository>();
    final budgetsRepo = context.read<BudgetsRepository>();
    final categoriesRepo = context.read<CategoriesRepository>();
    final familyRepo = context.read<FamilyController>().repository;

    if (familyId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.dashboardTitle)),
        body: Center(child: Text(l10n.familyMissing)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.dashboardTitle)),
      body: AppPage(
        padding: AppInsets.pageCompact,
        child: StreamBuilder<FamilyInfo?>(
          stream: familyRepo.watchFamily(familyId),
          builder: (context, familySnap) {
            final currency = familySnap.data?.currency ?? 'EUR';
            return StreamBuilder<MonthStats>(
              stream: statsRepo.watchMonthStats(familyId, periodId),
              builder: (context, statsSnap) {
                final statsError = statsSnap.hasError
                    ? statsSnap.error.toString()
                    : null;
                final stats = statsSnap.data;

                return StreamBuilder<List<BudgetWithPeriod>>(
                  stream: budgetsRepo.watchBudgetsWithPeriod(
                    familyId,
                    periodId,
                  ),
                  builder: (context, budgetSnap) {
                    final budgets =
                        budgetSnap.data ?? const <BudgetWithPeriod>[];
                    final alerts = budgets.where((b) {
                      final p = b.period;
                      return p.threshold80Notified ||
                          p.threshold100Notified ||
                          p.thresholdState(b.budget.limitAmountMinor) !=
                              BudgetThresholdState.ok;
                    }).toList();

                    return StreamBuilder<List<Category>>(
                      stream: categoriesRepo.watchCategories(
                        familyId,
                        includeArchived: true,
                      ),
                      builder: (context, catSnap) {
                        final categories = {
                          for (final c in catSnap.data ?? const <Category>[])
                            c.id: c,
                        };

                        final isLoading =
                            statsSnap.connectionState ==
                                ConnectionState.waiting &&
                            stats == null;

                        return LedgerAsyncBody(
                          isLoading: isLoading,
                          errorMessage: statsError,
                          isEmpty: false,
                          emptyMessage: '',
                          child: ListView(
                            children: [
                              Text(
                                l10n.dashboardPeriodLabel(periodId),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              if (alerts.isNotEmpty) ...[
                                for (final alert in alerts)
                                  _BudgetAlertBanner(
                                    item: alert,
                                    categoryName: () {
                                      final cat =
                                          categories[alert.budget.categoryId];
                                      if (cat == null) {
                                        return alert.budget.categoryId;
                                      }
                                      return categoryLabel(l10n, cat);
                                    }(),
                                    currency: currency,
                                    locale: locale,
                                    onOpen: () => context.go(AppRoutes.budgets),
                                  ),
                                const SizedBox(height: AppSpacing.sm),
                              ],
                              _SummaryCard(
                                income: stats?.totalIncomeMinor ?? 0,
                                expense: stats?.totalExpenseMinor ?? 0,
                                currency: currency,
                                locale: locale,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              AppSectionTitle(
                                l10n.dashboardExpensesByCategory,
                                padding: EdgeInsets.zero,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              _CategoryBars(
                                amounts: stats?.expenseByCategory ?? const {},
                                categories: categories,
                                currency: currency,
                                locale: locale,
                                emptyLabel: l10n.dashboardNoExpenses,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              AppSectionTitle(
                                l10n.dashboardIncomeByCategory,
                                padding: EdgeInsets.zero,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              _CategoryBars(
                                amounts: stats?.incomeByCategory ?? const {},
                                categories: categories,
                                currency: currency,
                                locale: locale,
                                emptyLabel: l10n.dashboardNoIncome,
                                income: true,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              AppSectionTitle(
                                l10n.dashboardQuickLinks,
                                padding: EdgeInsets.zero,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Wrap(
                                spacing: AppSpacing.xs,
                                runSpacing: AppSpacing.xs,
                                children: [
                                  ActionChip(
                                    avatar: const Icon(Icons.pie_chart_outline),
                                    label: Text(l10n.budgetsTitle),
                                    onPressed: () =>
                                        context.go(AppRoutes.budgets),
                                  ),
                                  ActionChip(
                                    avatar: const Icon(Icons.flag_outlined),
                                    label: Text(l10n.goalsTitle),
                                    onPressed: () =>
                                        context.go(AppRoutes.goals),
                                  ),
                                  ActionChip(
                                    avatar: const Icon(
                                      Icons.receipt_long_outlined,
                                    ),
                                    label: Text(l10n.transactionsTitle),
                                    onPressed: () =>
                                        context.go(AppRoutes.transactions),
                                  ),
                                  ActionChip(
                                    avatar: const Icon(
                                      Icons.account_balance_wallet_outlined,
                                    ),
                                    label: Text(l10n.accountsTitle),
                                    onPressed: () =>
                                        context.push(AppRoutes.accounts),
                                  ),
                                  ActionChip(
                                    avatar: const Icon(Icons.category_outlined),
                                    label: Text(l10n.categoriesTitle),
                                    onPressed: () =>
                                        context.push(AppRoutes.categories),
                                  ),
                                  ActionChip(
                                    avatar: const Icon(Icons.swap_horiz),
                                    label: Text(l10n.transferCreateTitle),
                                    onPressed: () =>
                                        context.push(AppRoutes.transferNew),
                                  ),
                                  ActionChip(
                                    avatar: const Icon(Icons.inbox_outlined),
                                    label: Text(l10n.ingestionTitle),
                                    onPressed: () =>
                                        context.push(AppRoutes.ingestion),
                                  ),
                                  ActionChip(
                                    avatar: const Icon(
                                      Icons.document_scanner_outlined,
                                    ),
                                    label: Text(l10n.receiptScanTitle),
                                    onPressed: () =>
                                        context.push(AppRoutes.receiptScan),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xl),
                            ],
                          ),
                        );
                      },
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

class _BudgetAlertBanner extends StatelessWidget {
  const _BudgetAlertBanner({
    required this.item,
    required this.categoryName,
    required this.currency,
    required this.locale,
    required this.onOpen,
  });

  final BudgetWithPeriod item;
  final String categoryName;
  final String currency;
  final String locale;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final extras = AppExtraColors.of(context);
    final state = item.period.thresholdState(item.budget.limitAmountMinor);
    final is100 =
        item.period.threshold100Notified ||
        state == BudgetThresholdState.atOrOver100;
    final color = is100 ? extras.expense : theme.colorScheme.tertiary;
    final message = is100 ? l10n.budgetAlert100 : l10n.budgetAlert80;

    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: AppRadius.mdAll,
      child: InkWell(
        borderRadius: AppRadius.mdAll,
        onTap: onOpen,
        child: Padding(
          padding: AppInsets.card,
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: color),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryName,
                      style: theme.textTheme.titleSmall?.copyWith(color: color),
                    ),
                    Text(message, style: theme.textTheme.bodySmall),
                    Text(
                      l10n.budgetSpentOfLimit(
                        '${Money.formatFromMinor(item.period.spentAmountMinor, locale)} $currency',
                        '${Money.formatFromMinor(item.budget.limitAmountMinor, locale)} $currency',
                      ),
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.income,
    required this.expense,
    required this.currency,
    required this.locale,
  });

  final int income;
  final int expense;
  final String currency;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final extras = AppExtraColors.of(context);
    final net = income - expense;

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: AppRadius.mdAll,
      child: Padding(
        padding: AppInsets.card,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatCell(
                    label: l10n.dashboardTotalIncome,
                    value: '${Money.formatFromMinor(income, locale)} $currency',
                    color: extras.income,
                  ),
                ),
                Expanded(
                  child: _StatCell(
                    label: l10n.dashboardTotalExpense,
                    value:
                        '${Money.formatFromMinor(expense, locale)} $currency',
                    color: extras.expense,
                  ),
                ),
              ],
            ),
            const Divider(height: AppSpacing.lg),
            _StatCell(
              label: l10n.dashboardNet,
              value:
                  '${net < 0 ? '-' : ''}'
                  '${Money.formatFromMinor(net.abs(), locale)} $currency',
              color: net >= 0 ? extras.income : extras.expense,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelMedium),
        const SizedBox(height: AppSpacing.xxs),
        Text(value, style: theme.textTheme.titleMedium?.copyWith(color: color)),
      ],
    );
  }
}

class _CategoryBars extends StatelessWidget {
  const _CategoryBars({
    required this.amounts,
    required this.categories,
    required this.currency,
    required this.locale,
    required this.emptyLabel,
    this.income = false,
  });

  final Map<String, int> amounts;
  final Map<String, Category> categories;
  final String currency;
  final String locale;
  final String emptyLabel;
  final bool income;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final extras = AppExtraColors.of(context);
    final entries = amounts.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (entries.isEmpty) {
      return Text(emptyLabel, style: theme.textTheme.bodyMedium);
    }

    final max = entries.first.value.toDouble();
    final barColor = income ? extras.income : extras.expense;

    return Column(
      children: [
        for (final e in entries.take(8))
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(() {
                        final cat = categories[e.key];
                        if (cat == null) return e.key;
                        return categoryLabel(l10n, cat);
                      }(), style: theme.textTheme.bodyMedium),
                    ),
                    Text(
                      '${Money.formatFromMinor(e.value, locale)} $currency',
                      style: theme.textTheme.labelLarge,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                ClipRRect(
                  borderRadius: AppRadius.fullAll,
                  child: LinearProgressIndicator(
                    value: max <= 0 ? 0 : e.value / max,
                    minHeight: AppSizes.progressBarHeight,
                    color: barColor,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
