import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/locale/locale_controller.dart';
import '../../../core/money/money.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/ui/kinship_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/ledger_async_body.dart';
import '../../accounts/domain/account.dart';
import '../../accounts/presentation/accounts_controller.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../budgets/domain/budget.dart';
import '../../categories/domain/category.dart';
import '../../family/presentation/family_controller.dart';
import '../../goals/domain/goal.dart';
import '../../goals/presentation/goals_controller.dart';
import '../../ledger/ledger_labels.dart';
import '../../receipt_ocr/domain/ingestion.dart';
import '../../receipt_ocr/presentation/ingestion_controller.dart';
import '../../transactions/domain/transaction.dart';
import '../../transactions/presentation/transactions_controller.dart';
import 'dashboard_controller.dart';

/// Home dashboard — Stitch Kinship mobile + web (≥840) layouts.
///
/// Content only: [KinshipScaffold] already provides shell chrome.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _boundFamilyId;
  bool _balanceHidden = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final familyId = context.watch<AuthController>().familyId;
    if (familyId != _boundFamilyId) {
      _boundFamilyId = familyId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<DashboardController>().bindFamily(familyId);
        context.read<AccountsController>().bindFamily(familyId);
        context.read<TransactionsController>().bindFamily(familyId);
        context.read<GoalsController>().bindFamily(familyId);
        context.read<IngestionController>().bindFamily(familyId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final familyId = context.select((AuthController c) => c.familyId);
    final locale = context.watch<LocaleController>().locale.languageCode;
    final dash = context.watch<DashboardController>();
    final accounts = context.watch<AccountsController>();
    final txs = context.watch<TransactionsController>();
    final goals = context.watch<GoalsController>();
    final ingestion = context.watch<IngestionController>();
    final auth = context.watch<AuthController>();
    final state = dash.state;

    if (familyId == null) {
      return Center(child: Text(l10n.familyMissing));
    }

    final firstName = _firstName(auth.user?.displayName);
    final monthLabel = _monthLabel(state.periodId, locale);
    final currency = state.currency;
    final activeAccounts = accounts.items
        .where((a) => !a.archived)
        .toList(growable: false);
    final totalBalanceMinor = activeAccounts.fold<int>(
      0,
      (sum, a) => sum + a.balanceMinor,
    );
    final income = state.stats.totalIncomeMinor;
    final expense = state.stats.totalExpenseMinor;
    final net = income - expense;
    final netPercent = income > 0 ? ((net / income) * 100).round() : 0;
    final budgetLimitTotal = state.budgets.fold<int>(
      0,
      (sum, b) => sum + b.budget.limitAmountMinor,
    );

    final data = _DashboardViewData(
      familyId: familyId,
      locale: locale,
      currency: currency,
      periodId: state.periodId,
      monthLabel: monthLabel,
      firstName: firstName,
      totalBalanceMinor: totalBalanceMinor,
      incomeMinor: income,
      expenseMinor: expense,
      netMinor: net,
      netPercent: netPercent,
      budgetLimitTotalMinor: budgetLimitTotal,
      budgets: state.budgets,
      categoriesById: state.categoriesById,
      accounts: activeAccounts,
      recentTx: txs.items.take(5).toList(growable: false),
      pending: ingestion.pending.take(3).toList(growable: false),
      pendingCount: ingestion.pending.length,
      goals: goals.items.take(3).toList(growable: false),
      balanceHidden: _balanceHidden,
      onToggleBalance: () => setState(() => _balanceHidden = !_balanceHidden),
    );

    final loading = state.loading || accounts.loading || txs.loading;
    final error =
        state.errorMessage ??
        accounts.errorMessage ??
        txs.errorMessage ??
        goals.errorMessage ??
        ingestion.errorMessage;

    return AppPage(
      padding: EdgeInsets.zero,
      child: LedgerAsyncBody(
        isLoading: loading,
        errorMessage: error,
        isEmpty: false,
        emptyMessage: '',
        onRetry: () {
          dash.clearError();
          accounts.clearError();
          txs.clearError();
          goals.clearError();
          ingestion.clearError();
          dash.bindFamily(familyId);
          accounts.bindFamily(familyId);
          txs.bindFamily(familyId);
          goals.bindFamily(familyId);
          ingestion.bindFamily(familyId);
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= AppBreakpoints.medium;
            return wide
                ? _DashboardWeb(data: data)
                : _DashboardMobile(data: data);
          },
        ),
      ),
    );
  }

  static String _firstName(String? displayName) {
    final trimmed = displayName?.trim() ?? '';
    if (trimmed.isEmpty) return '';
    return trimmed.split(RegExp(r'\s+')).first;
  }

  static String _monthLabel(String periodId, String locale) {
    final parts = periodId.split('-');
    if (parts.length != 2) return periodId;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year == null || month == null) return periodId;
    return DateFormat.yMMMM(locale).format(DateTime(year, month));
  }
}

class _DashboardViewData {
  const _DashboardViewData({
    required this.familyId,
    required this.locale,
    required this.currency,
    required this.periodId,
    required this.monthLabel,
    required this.firstName,
    required this.totalBalanceMinor,
    required this.incomeMinor,
    required this.expenseMinor,
    required this.netMinor,
    required this.netPercent,
    required this.budgetLimitTotalMinor,
    required this.budgets,
    required this.categoriesById,
    required this.accounts,
    required this.recentTx,
    required this.pending,
    required this.pendingCount,
    required this.goals,
    required this.balanceHidden,
    required this.onToggleBalance,
  });

  final String familyId;
  final String locale;
  final String currency;
  final String periodId;
  final String monthLabel;
  final String firstName;
  final int totalBalanceMinor;
  final int incomeMinor;
  final int expenseMinor;
  final int netMinor;
  final int netPercent;
  final int budgetLimitTotalMinor;
  final List<BudgetWithPeriod> budgets;
  final Map<String, Category> categoriesById;
  final List<Account> accounts;
  final List<LedgerTransaction> recentTx;
  final List<IngestionDraft> pending;
  final int pendingCount;
  final List<Goal> goals;
  final bool balanceHidden;
  final VoidCallback onToggleBalance;
}

// ─── Mobile ─────────────────────────────────────────────────────────────────

class _DashboardMobile extends StatelessWidget {
  const _DashboardMobile({required this.data});

  final _DashboardViewData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final familyCtrl = context.read<FamilyController>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.margin,
        AppSpacing.sm,
        AppSpacing.margin,
        AppSpacing.xxl,
      ),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: scheme.surfaceTint,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          l10n.dashboardCurrentMonth(data.monthLabel),
                          style: textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.firstName.isEmpty
                        ? l10n.dashboardTitle
                        : l10n.dashboardGreetingHi(data.firstName),
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 28,
                      height: 36 / 28,
                    ),
                  ),
                ],
              ),
            ),
            StreamBuilder<List<FamilyMember>>(
              stream: familyCtrl.watchMembers(data.familyId),
              builder: (context, snap) {
                final members = snap.data ?? const <FamilyMember>[];
                if (members.isEmpty) return const SizedBox.shrink();
                return _ActiveMembersPill(members: members);
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _HeroBalanceSection(data: data),
        if (data.pendingCount > 0) ...[
          const SizedBox(height: AppSpacing.lg),
          _ReviewAlertCard(
            count: data.pendingCount,
            onTap: () => context.go(AppRoutes.ingestion),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        KinshipSectionHeader(
          title: l10n.dashboardAccountsSection,
          actionLabel: l10n.dashboardManage,
          onAction: () => context.push(AppRoutes.accounts),
        ),
        const SizedBox(height: AppSpacing.xs),
        _AccountsRail(data: data),
        const SizedBox(height: AppSpacing.lg),
        KinshipCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KinshipSectionHeader(
                title: l10n.dashboardBudgetOfMonth(data.monthLabel),
                actionLabel: l10n.dashboardSeeAllCount(data.budgets.length),
                onAction: () => context.go(AppRoutes.budgets),
              ),
              const SizedBox(height: AppSpacing.xs),
              if (data.budgets.isEmpty)
                Text(
                  l10n.budgetsEmpty,
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                )
              else
                for (final item in data.budgets.take(3)) ...[
                  _BudgetMeterBlock(item: item, data: data, dense: false),
                  const SizedBox(height: AppSpacing.sm),
                ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        KinshipSectionHeader(
          title: l10n.dashboardRecentTransactions,
          actionLabel: l10n.dashboardSeeAll,
          onAction: () => context.go(AppRoutes.transactions),
        ),
        const SizedBox(height: AppSpacing.xs),
        KinshipCard(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: data.recentTx.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    l10n.dashboardNoRecentTx,
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (final tx in data.recentTx)
                      _TxLedgerRow(tx: tx, data: data),
                  ],
                ),
        ),
      ],
    );
  }
}

// ─── Web ────────────────────────────────────────────────────────────────────

class _DashboardWeb extends StatelessWidget {
  const _DashboardWeb({required this.data});

  final _DashboardViewData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final extras = AppExtraColors.of(context);
    final today = DateFormat.yMMMMEEEEd(data.locale).format(DateTime.now());

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xxl,
      ),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: scheme.primaryContainer,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          today,
                          style: textTheme.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    data.firstName.isEmpty
                        ? l10n.dashboardTitle
                        : l10n.dashboardGreetingWelcome(data.firstName),
                    style: textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                alignment: WrapAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                      borderRadius: AppRadius.fullAll,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          data.monthLabel,
                          style: textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  KinshipSecondaryPillButton(
                    onPressed: () => context.push(AppRoutes.receiptScan),
                    icon: const Icon(Icons.document_scanner_outlined, size: 18),
                    child: Text(l10n.shellScanReceipt),
                  ),
                  KinshipPrimaryPillButton(
                    onPressed: () => context.push(AppRoutes.transactionNew),
                    icon: const Icon(Icons.add, size: 20),
                    child: Text(l10n.shellAddTransaction),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth < 900 ? 2 : 4;
            return GridView.count(
              crossAxisCount: cols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: cols == 4 ? 1.35 : 1.5,
              children: [
                KinshipKpiTile(
                  label: l10n.dashboardPatrimony.toUpperCase(),
                  amountText: data.balanceHidden
                      ? _maskedAmount(data.currency)
                      : _money(data.totalBalanceMinor, data),
                  icon: Icons.account_balance_outlined,
                ),
                KinshipKpiTile(
                  label: l10n
                      .dashboardIncomeForMonth(data.monthLabel)
                      .toUpperCase(),
                  amountText: _money(data.incomeMinor, data),
                  amountColor: extras.income,
                  icon: Icons.payments_outlined,
                  iconBackground: scheme.surfaceContainerHigh,
                  iconColor: scheme.primary,
                ),
                _ExpenseKpiTile(data: data),
                _SmartReviewKpi(
                  count: data.pendingCount,
                  onTap: () => context.go(AppRoutes.ingestion),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.xl),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 960;
            final left = _WebLeftColumn(data: data);
            final right = _WebRightColumn(data: data);
            if (stacked) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  left,
                  const SizedBox(height: AppSpacing.lg),
                  right,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 8, child: left),
                const SizedBox(width: AppSpacing.lg),
                Expanded(flex: 4, child: right),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _WebLeftColumn extends StatelessWidget {
  const _WebLeftColumn({required this.data});

  final _DashboardViewData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KinshipCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.dashboardCashflowTitle,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: AppRadius.mdAll,
                ),
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    l10n.dashboardCashflowPlaceholder,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        KinshipCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KinshipSectionHeader(
                title: l10n.dashboardBudgetMonitor,
                actionLabel: l10n.budgetsTitle,
                onAction: () => context.go(AppRoutes.budgets),
              ),
              const SizedBox(height: AppSpacing.md),
              if (data.budgets.isEmpty)
                Text(
                  l10n.budgetsEmpty,
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final twoCol = constraints.maxWidth >= 520;
                    final items = data.budgets.take(4).toList();
                    if (!twoCol) {
                      return Column(
                        children: [
                          for (final item in items) ...[
                            _BudgetMeterBlock(
                              item: item,
                              data: data,
                              dense: true,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                        ],
                      );
                    }
                    return Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.md,
                      children: [
                        for (final item in items)
                          SizedBox(
                            width: (constraints.maxWidth - AppSpacing.md) / 2,
                            child: _BudgetMeterBlock(
                              item: item,
                              data: data,
                              dense: true,
                              inTile: true,
                            ),
                          ),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        KinshipCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KinshipSectionHeader(
                title: l10n.dashboardRecentTransactions,
                actionLabel: l10n.dashboardViewAllTransactions,
                onAction: () => context.go(AppRoutes.transactions),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (data.recentTx.isEmpty)
                Text(
                  l10n.dashboardNoRecentTx,
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                )
              else
                for (final tx in data.recentTx)
                  _TxLedgerRow(tx: tx, data: data),
            ],
          ),
        ),
      ],
    );
  }
}

class _WebRightColumn extends StatelessWidget {
  const _WebRightColumn({required this.data});

  final _DashboardViewData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final extras = AppExtraColors.of(context);
    final ingestion = context.read<IngestionController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KinshipCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.dashboardQuickQueue,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (data.pendingCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.tertiaryFixed.withValues(alpha: 0.5),
                        borderRadius: AppRadius.fullAll,
                      ),
                      child: Text(
                        l10n.dashboardReviewCount(data.pendingCount),
                        style: textTheme.labelSmall?.copyWith(
                          color: extras.onPending,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.dashboardQuickQueueHint,
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (data.pending.isEmpty)
                Text(
                  l10n.dashboardQuickQueueEmpty,
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                )
              else
                for (final draft in data.pending) ...[
                  _QuickDraftCard(
                    draft: draft,
                    data: data,
                    onOpen: () =>
                        context.push(AppRoutes.ingestionDetailPath(draft.id)),
                    onDiscard: () async {
                      try {
                        await ingestion.discardDraft(draft.id);
                      } catch (_) {
                        if (!context.mounted) return;
                        final msg = ingestion.errorMessage;
                        if (msg != null) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text(msg)));
                        }
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
              if (data.pendingCount > 0)
                TextButton(
                  onPressed: () => context.go(AppRoutes.ingestion),
                  child: Text(l10n.dashboardReviewCta),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        KinshipCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KinshipSectionHeader(
                title: l10n.dashboardLinkedAccounts,
                actionLabel: l10n.dashboardManage,
                onAction: () => context.push(AppRoutes.accounts),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (data.accounts.isEmpty)
                Text(
                  l10n.dashboardNoAccounts,
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                )
              else
                for (final account in data.accounts.take(4)) ...[
                  _LinkedAccountRow(account: account, data: data),
                  const SizedBox(height: AppSpacing.xs),
                ],
              const SizedBox(height: AppSpacing.xs),
              KinshipSecondaryPillButton(
                onPressed: () => context.push(AppRoutes.accountNew),
                icon: const Icon(Icons.add, size: 18),
                child: Text(l10n.dashboardLinkAccount),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        KinshipCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KinshipSectionHeader(
                title: l10n.dashboardSavingsGoals,
                actionLabel: l10n.dashboardSeeAll,
                onAction: () => context.go('${AppRoutes.budgets}?tab=goals'),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (data.goals.isEmpty)
                Text(
                  l10n.dashboardNoGoals,
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                )
              else
                for (final goal in data.goals) ...[
                  _GoalProgressBlock(goal: goal, data: data),
                  const SizedBox(height: AppSpacing.sm),
                ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Shared sections ────────────────────────────────────────────────────────

class _HeroBalanceSection extends StatelessWidget {
  const _HeroBalanceSection({required this.data});

  final _DashboardViewData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final extras = AppExtraColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final netSign = data.netMinor >= 0 ? '+' : '-';
    final netText = '$netSign ${_money(data.netMinor.abs(), data)}';

    return KinshipHeroBalance(
      label: l10n.dashboardTotalBalance.toUpperCase(),
      amountText: data.balanceHidden
          ? _maskedAmount(data.currency)
          : _money(data.totalBalanceMinor, data),
      trailing: IconButton(
        tooltip: l10n.dashboardTotalBalance,
        onPressed: data.onToggleBalance,
        icon: Icon(
          data.balanceHidden ? Icons.visibility_off : Icons.visibility,
          color: extras.onHeroSurface,
          size: 20,
        ),
      ),
      subtitle: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: AppRadius.fullAll,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              data.netMinor >= 0 ? Icons.trending_up : Icons.trending_down,
              size: 16,
              color: scheme.primaryFixed,
            ),
            const SizedBox(width: AppSpacing.xxs),
            Flexible(
              child: Text(
                l10n.dashboardNetSavings(netText, '${data.netPercent}'),
                style: textTheme.labelSmall?.copyWith(
                  color: extras.onHeroSurface,
                ),
              ),
            ),
          ],
        ),
      ),
      footer: Row(
        children: [
          Expanded(
            child: _HeroMetricPill(
              icon: Icons.arrow_downward,
              iconBg: scheme.primaryFixed.withValues(alpha: 0.2),
              iconColor: scheme.primaryFixed,
              label: l10n.dashboardIncomeMonth,
              amount: '+ ${_money(data.incomeMinor, data)}',
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: _HeroMetricPill(
              icon: Icons.arrow_upward,
              iconBg: scheme.secondaryFixed.withValues(alpha: 0.2),
              iconColor: scheme.secondaryFixed,
              label: l10n.dashboardExpenseMonth,
              amount: '- ${_money(data.expenseMinor, data)}',
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetricPill extends StatelessWidget {
  const _HeroMetricPill({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.amount,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String amount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final extras = AppExtraColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest.withValues(alpha: 0.1),
        borderRadius: AppRadius.mdAll,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(
                    color: extras.onHeroSurface,
                  ),
                ),
                Text(
                  amount,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.tabularAmountMd(context)
                      ?.copyWith(color: scheme.onPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewAlertCard extends StatelessWidget {
  const _ReviewAlertCard({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return KinshipCard(
      color: scheme.tertiaryFixed,
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.tertiaryContainer,
                  borderRadius: AppRadius.mdAll,
                ),
                child: Icon(
                  Icons.receipt_long,
                  color: scheme.onTertiaryContainer,
                ),
              ),
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: scheme.secondary,
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.tertiaryFixed, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        l10n.dashboardReviewCount(count),
                        style: textTheme.titleMedium?.copyWith(
                          color: scheme.onTertiaryFixed,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.tertiaryContainer,
                        borderRadius: AppRadius.fullAll,
                      ),
                      child: Text(
                        l10n.dashboardReviewActionBadge.toUpperCase(),
                        style: textTheme.labelSmall?.copyWith(
                          color: scheme.onTertiaryContainer,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.dashboardReviewSubtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onTertiaryFixedVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Text(
                      l10n.dashboardReviewNow,
                      style: textTheme.labelMedium?.copyWith(
                        color: scheme.tertiary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Icon(Icons.arrow_forward, size: 16, color: scheme.tertiary),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountsRail extends StatelessWidget {
  const _AccountsRail({required this.data});

  final _DashboardViewData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (data.accounts.isEmpty) {
      return Text(
        l10n.dashboardNoAccounts,
        style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      );
    }

    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: data.accounts.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final account = data.accounts[index];
          final isPrimary = index == 0;
          return SizedBox(
            width: 224,
            child: KinshipCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              onTap: () => context.push(AppRoutes.accounts),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isPrimary
                              ? scheme.primaryFixed
                              : scheme.surfaceContainerHigh,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _accountIcon(account.type),
                          size: 18,
                          color: isPrimary
                              ? scheme.onPrimaryFixed
                              : scheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              account.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            if (isPrimary)
                              Text(
                                l10n.dashboardPrimaryAccount.toUpperCase(),
                                style: textTheme.labelSmall?.copyWith(
                                  color: scheme.surfaceTint,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    l10n.dashboardAvailableBalance,
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    _money(account.balanceMinor, data),
                    style: AppTextStyles.tabularAmountMd(context),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BudgetMeterBlock extends StatelessWidget {
  const _BudgetMeterBlock({
    required this.item,
    required this.data,
    required this.dense,
    this.inTile = false,
  });

  final BudgetWithPeriod item;
  final _DashboardViewData data;
  final bool dense;
  final bool inTile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final limit = item.budget.limitAmountMinor;
    final spent = item.period.spentAmountMinor;
    final progress = limit <= 0 ? 0.0 : spent / limit;
    final remaining = (limit - spent).clamp(0, limit);
    final percent = (progress * 100).round().clamp(0, 999);
    final cat = data.categoriesById[item.budget.categoryId];
    final name = cat == null
        ? item.budget.categoryId
        : categoryLabel(l10n, cat);
    final warning = progress >= KinshipBudgetMeter.warningThreshold;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${_money(spent, data)} / ${_money(limit, data)}',
              style: textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SizedBox(height: dense ? AppSpacing.xs : 6),
        KinshipBudgetMeter(progress: progress),
        SizedBox(height: dense ? AppSpacing.xxs : 4),
        Row(
          children: [
            Expanded(
              child: Text(
                warning
                    ? '${l10n.dashboardSpentPercent('$percent')} '
                          '(${l10n.dashboardAttentionThreshold})'
                    : l10n.dashboardUsedPercent('$percent'),
                style: textTheme.labelSmall?.copyWith(
                  color: warning ? scheme.tertiary : scheme.onSurfaceVariant,
                  fontWeight: warning ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ),
            Text(
              l10n.dashboardRemaining(_money(remaining, data)),
              style: textTheme.labelSmall?.copyWith(
                color: warning ? scheme.tertiary : scheme.surfaceTint,
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );

    if (!inTile) return content;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: AppRadius.mdAll,
      ),
      child: content,
    );
  }
}

class _TxLedgerRow extends StatelessWidget {
  const _TxLedgerRow({required this.tx, required this.data});

  final LedgerTransaction tx;
  final _DashboardViewData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isIncome =
        tx.type == TransactionType.income || tx.type == TransactionType.refund;
    final title = (tx.merchant?.trim().isNotEmpty == true)
        ? tx.merchant!.trim()
        : (tx.note?.trim().isNotEmpty == true)
        ? tx.note!.trim()
        : l10n.transactionsTitle;
    final cat = tx.categoryId == null
        ? null
        : data.categoriesById[tx.categoryId!];
    final catLabel = cat == null ? null : categoryLabel(l10n, cat);
    final sign = isIncome ? '+' : '-';

    return KinshipLedgerRow(
      title: title,
      amountText: '$sign ${_money(tx.amountMinor, data)}',
      isIncome: isIncome,
      timestamp: _formatTxDate(tx.bookingDate, data.locale),
      categoryLabel: catLabel,
      onTap: () => context.push(AppRoutes.transactionEditPath(tx.id)),
    );
  }
}

class _ExpenseKpiTile extends StatelessWidget {
  const _ExpenseKpiTile({required this.data});

  final _DashboardViewData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final extras = AppExtraColors.of(context);
    final limit = data.budgetLimitTotalMinor;
    final spent = data.expenseMinor;
    final progress = limit <= 0 ? 0.0 : (spent / limit).clamp(0.0, 1.0);
    final remaining = limit > 0 ? (limit - spent).clamp(0, limit) : 0;
    final percent = (progress * 100).round();

    return KinshipKpiTile(
      label: l10n.dashboardMonthlyOutflows.toUpperCase(),
      amountText: _money(spent, data),
      icon: Icons.shopping_bag_outlined,
      iconBackground: scheme.secondaryFixed.withValues(alpha: 0.4),
      iconColor: extras.expense,
      footer: limit <= 0
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.dashboardBudgetPreset,
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ),
                    Text(
                      _money(limit, data),
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                KinshipBudgetMeter(progress: progress, height: 8),
                const SizedBox(height: AppSpacing.xxs),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.dashboardSpentPercent('$percent'),
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ),
                    Text(
                      l10n.dashboardRemaining(_money(remaining, data)),
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _SmartReviewKpi extends StatelessWidget {
  const _SmartReviewKpi({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return KinshipCard(
      color: scheme.tertiaryFixed.withValues(alpha: 0.3),
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.dashboardSmartReview.toUpperCase(),
                  style: textTheme.labelMedium?.copyWith(
                    color: scheme.tertiary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.tertiary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$count',
                  style: textTheme.labelSmall?.copyWith(
                    color: scheme.onTertiary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.dashboardReviewValidate(count),
            style: textTheme.headlineSmall?.copyWith(
              color: scheme.onTertiaryFixed,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            l10n.dashboardReviewSubtitle,
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onTertiaryFixedVariant,
            ),
          ),
          const Spacer(),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest,
              borderRadius: AppRadius.mdAll,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.dashboardReviewCta,
                    style: textTheme.labelMedium?.copyWith(
                      color: scheme.tertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward, size: 18, color: scheme.tertiary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickDraftCard extends StatelessWidget {
  const _QuickDraftCard({
    required this.draft,
    required this.data,
    required this.onOpen,
    required this.onDiscard,
  });

  final IngestionDraft draft;
  final _DashboardViewData data;
  final VoidCallback onOpen;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final extras = AppExtraColors.of(context);
    final title = draft.merchant?.trim().isNotEmpty == true
        ? draft.merchant!.trim()
        : l10n.ingestionTitle;
    final sourceLabel = draft.source == IngestionSource.notification
        ? 'Wallet'
        : 'OCR';
    final amount = draft.amountMinor == null
        ? '—'
        : _money(draft.amountMinor!, data);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: AppRadius.mdAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onOpen,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: AppRadius.mdAll,
                  ),
                  child: Icon(
                    draft.source == IngestionSource.notification
                        ? Icons.account_balance_wallet
                        : Icons.document_scanner_outlined,
                    size: 18,
                    color: scheme.onPrimary,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '$sourceLabel • $amount',
                        style: textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              TextButton(
                onPressed: onDiscard,
                style: TextButton.styleFrom(
                  foregroundColor: extras.expense,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(l10n.ingestionDiscardAction),
              ),
              const Spacer(),
              TextButton(
                onPressed: onOpen,
                style: TextButton.styleFrom(
                  foregroundColor: scheme.primaryContainer,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(l10n.ingestionConfirmAction),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LinkedAccountRow extends StatelessWidget {
  const _LinkedAccountRow({required this.account, required this.data});

  final Account account;
  final _DashboardViewData data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: AppRadius.mdAll,
          ),
          child: Icon(_accountIcon(account.type), size: 18),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            account.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          _money(account.balanceMinor, data),
          style: AppTextStyles.tabularAmountMd(context),
        ),
      ],
    );
  }
}

class _GoalProgressBlock extends StatelessWidget {
  const _GoalProgressBlock({required this.goal, required this.data});

  final Goal goal;
  final _DashboardViewData data;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final percent = (goal.progress * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                goal.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$percent%',
              style: textTheme.labelSmall?.copyWith(
                color: scheme.primaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        KinshipBudgetMeter(progress: goal.progress, height: 8),
        const SizedBox(height: 2),
        Text(
          '${_money(goal.accumulatedAmountMinor, data)} / '
          '${_money(goal.targetAmountMinor, data)}',
          style: textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _ActiveMembersPill extends StatelessWidget {
  const _ActiveMembersPill({required this.members});

  final List<FamilyMember> members;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final shown = members.take(3).toList();
    final colors = [
      scheme.primaryFixed,
      scheme.secondaryFixed,
      scheme.tertiaryFixed,
    ];
    final fgs = [
      scheme.onPrimaryFixed,
      scheme.onSecondaryFixed,
      scheme.onTertiaryFixed,
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: AppRadius.fullAll,
        boxShadow: AppElevation.level1Shadows(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12.0 + shown.length * 14,
            height: 24,
            child: Stack(
              children: [
                for (var i = 0; i < shown.length; i++)
                  Positioned(
                    left: i * 14.0,
                    child: Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors[i % colors.length],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: scheme.surfaceContainerLow,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        _initial(shown[i].displayName),
                        style: textTheme.labelSmall?.copyWith(
                          color: fgs[i % fgs.length],
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            l10n.dashboardActiveMembers(members.length),
            style: textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  static String _initial(String name) {
    final t = name.trim();
    if (t.isEmpty) return '?';
    return t.characters.first.toUpperCase();
  }
}

// ─── Helpers ────────────────────────────────────────────────────────────────

String _money(int amountMinor, _DashboardViewData data) {
  final formatted = Money.formatFromMinor(amountMinor, data.locale);
  if (data.currency.toUpperCase() == 'EUR') {
    return '€ $formatted';
  }
  return '$formatted ${data.currency}';
}

String _maskedAmount(String currency) {
  if (currency.toUpperCase() == 'EUR') return '€ ••••••••';
  return '••••••••';
}

IconData _accountIcon(AccountType type) {
  return switch (type) {
    AccountType.cash => Icons.payments_outlined,
    AccountType.bankAccount => Icons.account_balance,
    AccountType.card => Icons.credit_card,
    AccountType.wallet => Icons.account_balance_wallet_outlined,
  };
}

String _formatTxDate(String bookingDate, String locale) {
  final parsed = parseBookingDate(bookingDate);
  if (parsed == null) return bookingDate;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(parsed.year, parsed.month, parsed.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) {
    return locale.startsWith('it') ? 'Oggi' : 'Today';
  }
  if (diff == 1) {
    return locale.startsWith('it') ? 'Ieri' : 'Yesterday';
  }
  return DateFormat.MMMd(locale).format(parsed);
}
