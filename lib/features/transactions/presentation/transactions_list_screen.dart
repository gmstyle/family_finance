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
import '../../accounts/presentation/accounts_controller.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../budgets/domain/budget.dart';
import '../../categories/domain/category.dart';
import '../../categories/presentation/categories_controller.dart';
import '../../dashboard/presentation/dashboard_controller.dart';
import '../../family/presentation/family_controller.dart';
import '../../ledger/ledger_labels.dart';
import '../../receipt_ocr/presentation/ingestion_controller.dart';
import '../../settings/presentation/settings_controller.dart';
import '../domain/transaction.dart';
import 'transaction_filters_sheet.dart';
import 'transaction_labels.dart';
import 'transactions_controller.dart';

class TransactionsListScreen extends StatefulWidget {
  const TransactionsListScreen({super.key});

  @override
  State<TransactionsListScreen> createState() => _TransactionsListScreenState();
}

class _TransactionsListScreenState extends State<TransactionsListScreen> {
  String? _boundFamilyId;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final familyId = context.watch<AuthController>().familyId;
    if (familyId != _boundFamilyId) {
      _boundFamilyId = familyId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<TransactionsController>().bindFamily(familyId);
        context.read<DashboardController>().bindFamily(familyId);
        context.read<AccountsController>().bindFamily(familyId);
        context.read<CategoriesController>().bindFamily(familyId);
        context.read<IngestionController>().bindFamily(familyId);
      });
    }
  }

  Future<void> _openFilters() async {
    final ctrl = context.read<TransactionsController>();
    final result = await showModalBottomSheet<TransactionFilters>(
      context: context,
      isScrollControlled: true,
      builder: (context) => TransactionFiltersSheet(initial: ctrl.filters),
    );
    if (result != null && mounted) {
      await ctrl.setFilters(result);
    }
  }

  Future<void> _confirmDelete(LedgerTransaction tx) async {
    final l10n = AppLocalizations.of(context)!;
    final familyId = context.read<AuthController>().familyId;
    if (familyId == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.transactionDeleteTitle),
        content: Text(
          tx.type == TransactionType.transfer
              ? l10n.transferDeleteBody
              : l10n.transactionDeleteBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    try {
      await context.read<TransactionsController>().deleteTransaction(tx);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _export() async {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.read<AuthController>();
    final settings = context.read<SettingsController>();
    try {
      await settings.exportAndShare(familyId: auth.familyId);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.settingsExportDone)));
    } catch (_) {
      if (!mounted) return;
      final msg = settings.errorMessage ?? l10n.settingsDeleteFailedGeneric;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  void _openTransaction(LedgerTransaction tx) {
    if (!tx.type.isManual) return;
    context.push(AppRoutes.transactionEditPath(tx.id));
  }

  Future<void> _selectMember(String? memberId) async {
    final ctrl = context.read<TransactionsController>();
    final next = ctrl.filters.copyWith(
      memberId: memberId,
      clearMemberId: memberId == null,
    );
    await ctrl.setFilters(next);
  }

  Future<void> _toggleThisMonth(bool enable) async {
    final ctrl = context.read<TransactionsController>();
    if (!enable) {
      await ctrl.setFilters(
        ctrl.filters.copyWith(
          clearBookingDateFrom: true,
          clearBookingDateTo: true,
        ),
      );
      return;
    }
    final period = currentBudgetPeriodId();
    final parts = period.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final lastDay = DateTime(year, month + 1, 0).day;
    final from = '$year-${month.toString().padLeft(2, '0')}-01';
    final to =
        '$year-${month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';
    await ctrl.setFilters(
      ctrl.filters.copyWith(bookingDateFrom: from, bookingDateTo: to),
    );
  }

  List<LedgerTransaction> _visibleItems(List<LedgerTransaction> items) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((tx) {
      final merchant = tx.merchant?.toLowerCase() ?? '';
      final note = tx.note?.toLowerCase() ?? '';
      final amount = (tx.amountMinor / 100.0).toStringAsFixed(2);
      return merchant.contains(q) ||
          note.contains(q) ||
          amount.contains(q) ||
          tx.bookingDate.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final familyId = context.select((AuthController c) => c.familyId);
    final ctrl = context.watch<TransactionsController>();
    final dash = context.watch<DashboardController>().state;
    final accounts = context.watch<AccountsController>().items;
    final categories = context.watch<CategoriesController>().items;
    final pendingCount = context.watch<IngestionController>().pending.length;
    final locale = context.watch<LocaleController>().locale;

    if (familyId == null) {
      return Center(child: Text(l10n.familyMissing));
    }

    final accountsById = {for (final a in accounts) a.id: a.name};
    final categoriesById = {for (final c in categories) c.id: c};
    final visible = _visibleItems(ctrl.items);
    final isWide = AppBreakpoints.isWide(context);
    final thisMonthActive = _isThisMonthFilter(ctrl.filters);

    return StreamBuilder<List<FamilyMember>>(
      stream: context.read<FamilyController>().watchMembers(familyId),
      builder: (context, membersSnap) {
        final members = membersSnap.data ?? const <FamilyMember>[];
        final membersById = {for (final m in members) m.userId: m.displayName};
        final memberSpend = _memberSpendShares(visible, members);

        return AppPage(
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? AppSpacing.xl : AppSpacing.md,
            vertical: isWide ? AppSpacing.lg : AppSpacing.md,
          ),
          child: LedgerAsyncBody(
            isLoading: ctrl.loading,
            errorMessage: ctrl.errorMessage,
            isEmpty: false,
            emptyMessage: l10n.transactionsEmpty,
            onRetry: ctrl.refresh,
            child: RefreshIndicator(
              onRefresh: ctrl.refresh,
              child: isWide
                  ? _WebBody(
                      l10n: l10n,
                      locale: locale,
                      ctrl: ctrl,
                      dash: dash,
                      pendingCount: pendingCount,
                      visible: visible,
                      members: members,
                      membersById: membersById,
                      accountsById: accountsById,
                      categoriesById: categoriesById,
                      memberSpend: memberSpend,
                      searchController: _searchController,
                      thisMonthActive: thisMonthActive,
                      onSearchChanged: (v) => setState(() => _searchQuery = v),
                      onOpenFilters: _openFilters,
                      onExport: _export,
                      onSelectMember: _selectMember,
                      onToggleThisMonth: _toggleThisMonth,
                      onOpenTransaction: _openTransaction,
                      onDelete: _confirmDelete,
                      onNewTransaction: () =>
                          context.push(AppRoutes.transactionNew),
                      onOpenReview: () => context.go(AppRoutes.ingestion),
                      onTransfer: () => context.push(AppRoutes.transferNew),
                    )
                  : _MobileBody(
                      l10n: l10n,
                      locale: locale,
                      ctrl: ctrl,
                      dash: dash,
                      visible: visible,
                      members: members,
                      membersById: membersById,
                      accountsById: accountsById,
                      categoriesById: categoriesById,
                      memberSpend: memberSpend,
                      searchController: _searchController,
                      thisMonthActive: thisMonthActive,
                      onSearchChanged: (v) => setState(() => _searchQuery = v),
                      onOpenFilters: _openFilters,
                      onExport: _export,
                      onSelectMember: _selectMember,
                      onToggleThisMonth: _toggleThisMonth,
                      onOpenTransaction: _openTransaction,
                      onDelete: _confirmDelete,
                    ),
            ),
          ),
        );
      },
    );
  }

  static bool _isThisMonthFilter(TransactionFilters filters) {
    final period = currentBudgetPeriodId();
    final parts = period.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final lastDay = DateTime(year, month + 1, 0).day;
    final from = '$year-${month.toString().padLeft(2, '0')}-01';
    final to =
        '$year-${month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';
    return filters.bookingDateFrom == from && filters.bookingDateTo == to;
  }

  static List<_MemberSpendShare> _memberSpendShares(
    List<LedgerTransaction> items,
    List<FamilyMember> members,
  ) {
    if (members.isEmpty) return const [];
    final totals = <String, int>{for (final m in members) m.userId: 0};
    for (final tx in items) {
      if (tx.type != TransactionType.expense) continue;
      if (!totals.containsKey(tx.createdByUserId)) continue;
      totals[tx.createdByUserId] =
          (totals[tx.createdByUserId] ?? 0) + tx.amountMinor;
    }
    final grand = totals.values.fold<int>(0, (a, b) => a + b);
    if (grand <= 0) return const [];
    final shares =
        members
            .map(
              (m) => _MemberSpendShare(
                userId: m.userId,
                name: m.displayName,
                amountMinor: totals[m.userId] ?? 0,
                ratio: (totals[m.userId] ?? 0) / grand,
              ),
            )
            .where((s) => s.amountMinor > 0)
            .toList()
          ..sort((a, b) => b.amountMinor.compareTo(a.amountMinor));
    return shares.take(2).toList();
  }
}

class _MemberSpendShare {
  const _MemberSpendShare({
    required this.userId,
    required this.name,
    required this.amountMinor,
    required this.ratio,
  });

  final String userId;
  final String name;
  final int amountMinor;
  final double ratio;
}

// ---------------------------------------------------------------------------
// Mobile
// ---------------------------------------------------------------------------

class _MobileBody extends StatelessWidget {
  const _MobileBody({
    required this.l10n,
    required this.locale,
    required this.ctrl,
    required this.dash,
    required this.visible,
    required this.members,
    required this.membersById,
    required this.accountsById,
    required this.categoriesById,
    required this.memberSpend,
    required this.searchController,
    required this.thisMonthActive,
    required this.onSearchChanged,
    required this.onOpenFilters,
    required this.onExport,
    required this.onSelectMember,
    required this.onToggleThisMonth,
    required this.onOpenTransaction,
    required this.onDelete,
  });

  final AppLocalizations l10n;
  final Locale locale;
  final TransactionsController ctrl;
  final DashboardState dash;
  final List<LedgerTransaction> visible;
  final List<FamilyMember> members;
  final Map<String, String> membersById;
  final Map<String, String> accountsById;
  final Map<String, Category> categoriesById;
  final List<_MemberSpendShare> memberSpend;
  final TextEditingController searchController;
  final bool thisMonthActive;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onOpenFilters;
  final VoidCallback onExport;
  final Future<void> Function(String? memberId) onSelectMember;
  final Future<void> Function(bool enable) onToggleThisMonth;
  final ValueChanged<LedgerTransaction> onOpenTransaction;
  final Future<void> Function(LedgerTransaction tx) onDelete;

  @override
  Widget build(BuildContext context) {
    final groups = _groupByDay(visible);
    final periodLabel = _monthTitle(dash.periodId, locale.languageCode);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _MobileSummaryCard(
            l10n: l10n,
            locale: locale.languageCode,
            periodLabel: periodLabel,
            expenseMinor: dash.stats.totalExpenseMinor,
            incomeMinor: dash.stats.totalIncomeMinor,
            memberSpend: memberSpend,
            onExport: onExport,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
        SliverToBoxAdapter(
          child: _SearchFilterRow(
            controller: searchController,
            hint: l10n.ledgerSearchPlaceholder,
            filtersActive: ctrl.filters.hasAny,
            onChanged: onSearchChanged,
            onOpenFilters: onOpenFilters,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xs)),
        SliverToBoxAdapter(
          child: _MemberFilterChips(
            l10n: l10n,
            members: members,
            selectedMemberId: ctrl.filters.memberId,
            thisMonthActive: thisMonthActive,
            accountFilterActive: ctrl.filters.accountId != null,
            onSelectMember: onSelectMember,
            onToggleThisMonth: onToggleThisMonth,
            onOpenFilters: onOpenFilters,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
        if (ctrl.isEmpty || visible.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text(l10n.transactionsEmpty)),
          )
        else ...[
          for (final group in groups) ...[
            SliverToBoxAdapter(
              child: _DayHeader(
                label: _dayGroupLabel(l10n, locale.languageCode, group.date),
                netText: _formatSignedNet(group.netMinor, locale.languageCode),
                isPositive: group.netMinor > 0,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              sliver: SliverList.separated(
                itemCount: group.items.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.xs),
                itemBuilder: (context, index) {
                  final tx = group.items[index];
                  return _TxLedgerCard(
                    tx: tx,
                    l10n: l10n,
                    locale: locale.languageCode,
                    memberName: membersById[tx.createdByUserId],
                    category: tx.categoryId == null
                        ? null
                        : categoriesById[tx.categoryId!],
                    onTap: () => onOpenTransaction(tx),
                    onLongPress: () => onDelete(tx),
                  );
                },
              ),
            ),
          ],
          if (ctrl.hasMore)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Center(
                  child: ctrl.loadingMore
                      ? const CircularProgressIndicator()
                      : TextButton(
                          onPressed: ctrl.loadMore,
                          child: Text(l10n.actionLoadMore),
                        ),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],
      ],
    );
  }
}

class _MobileSummaryCard extends StatelessWidget {
  const _MobileSummaryCard({
    required this.l10n,
    required this.locale,
    required this.periodLabel,
    required this.expenseMinor,
    required this.incomeMinor,
    required this.memberSpend,
    required this.onExport,
  });

  final AppLocalizations l10n;
  final String locale;
  final String periodLabel;
  final int expenseMinor;
  final int incomeMinor;
  final List<_MemberSpendShare> memberSpend;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final extras = AppExtraColors.of(context);

    return KinshipCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.ledgerBookTitle.toUpperCase(),
                  style: textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Material(
                color: scheme.surfaceContainerLow,
                shape: const StadiumBorder(),
                child: InkWell(
                  onTap: onExport,
                  customBorder: const StadiumBorder(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs + 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.download_outlined,
                          size: 16,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.shellExport,
                          style: textTheme.labelSmall?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  dotColor: extras.expense,
                  label: l10n.ledgerExpensesMonth(periodLabel),
                  amount: '− € ${Money.formatFromMinor(expenseMinor, locale)}',
                  amountColor: scheme.onSurface,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _SummaryMetric(
                  dotColor: scheme.primaryContainer,
                  label: l10n.ledgerIncomeTotal,
                  amount: '+ € ${Money.formatFromMinor(incomeMinor, locale)}',
                  amountColor: scheme.primary,
                ),
              ),
            ],
          ),
          if (memberSpend.length >= 2) ...[
            const SizedBox(height: AppSpacing.sm),
            _MemberSplitBar(shares: memberSpend, locale: locale),
          ],
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.dotColor,
    required this.label,
    required this.amount,
    required this.amountColor,
  });

  final Color dotColor;
  final String label;
  final String amount;
  final Color amountColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          amount,
          style: AppTextStyles.tabularAmountMd(context)
              ?.copyWith(color: amountColor, fontSize: 20, height: 28 / 20),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Web
// ---------------------------------------------------------------------------

class _WebBody extends StatelessWidget {
  const _WebBody({
    required this.l10n,
    required this.locale,
    required this.ctrl,
    required this.dash,
    required this.pendingCount,
    required this.visible,
    required this.members,
    required this.membersById,
    required this.accountsById,
    required this.categoriesById,
    required this.memberSpend,
    required this.searchController,
    required this.thisMonthActive,
    required this.onSearchChanged,
    required this.onOpenFilters,
    required this.onExport,
    required this.onSelectMember,
    required this.onToggleThisMonth,
    required this.onOpenTransaction,
    required this.onDelete,
    required this.onNewTransaction,
    required this.onOpenReview,
    required this.onTransfer,
  });

  final AppLocalizations l10n;
  final Locale locale;
  final TransactionsController ctrl;
  final DashboardState dash;
  final int pendingCount;
  final List<LedgerTransaction> visible;
  final List<FamilyMember> members;
  final Map<String, String> membersById;
  final Map<String, String> accountsById;
  final Map<String, Category> categoriesById;
  final List<_MemberSpendShare> memberSpend;
  final TextEditingController searchController;
  final bool thisMonthActive;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onOpenFilters;
  final VoidCallback onExport;
  final Future<void> Function(String? memberId) onSelectMember;
  final Future<void> Function(bool enable) onToggleThisMonth;
  final ValueChanged<LedgerTransaction> onOpenTransaction;
  final Future<void> Function(LedgerTransaction tx) onDelete;
  final VoidCallback onNewTransaction;
  final VoidCallback onOpenReview;
  final VoidCallback onTransfer;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final extras = AppExtraColors.of(context);
    final lang = locale.languageCode;
    final periodLabel = _monthTitle(dash.periodId, lang);
    final year = dash.periodId.length >= 4
        ? dash.periodId.substring(0, 4)
        : DateTime.now().year.toString();
    final net = dash.stats.netMinor;
    final totalCount = visible.length;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 16,
                          color: scheme.primaryContainer,
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Flexible(
                          child: Text(
                            '${l10n.ledgerUnifiedFinance}  •  ${l10n.ledgerFiscalYear(year)}',
                            style: textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              letterSpacing: 0.6,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.ledgerBookTitle,
                      style: textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _MonthChip(
                    label: periodLabel,
                    active: thisMonthActive,
                    onTap: () => onToggleThisMonth(!thisMonthActive),
                  ),
                  OutlinedButton.icon(
                    onPressed: onExport,
                    icon: const Icon(Icons.ios_share, size: 18),
                    label: Text(l10n.shellExport),
                    style: KinshipPillCta.secondary(context).copyWith(
                      minimumSize: const WidgetStatePropertyAll(Size(0, 40)),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: onTransfer,
                    icon: const Icon(Icons.swap_horiz, size: 18),
                    label: Text(l10n.transferCreateTitle),
                    style: KinshipPillCta.secondary(context).copyWith(
                      minimumSize: const WidgetStatePropertyAll(Size(0, 40)),
                    ),
                  ),
                  KinshipPrimaryPillButton(
                    onPressed: onNewTransaction,
                    icon: const Icon(Icons.add, size: 20),
                    child: Text(l10n.transactionCreateTitle),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
        SliverToBoxAdapter(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth >= 1100
                  ? 4
                  : constraints.maxWidth >= 700
                  ? 2
                  : 1;
              return GridView.count(
                crossAxisCount: cols,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: cols == 4 ? 1.55 : 1.8,
                children: [
                  KinshipKpiTile(
                    label: l10n.ledgerMonthlyOutflows.toUpperCase(),
                    amountText:
                        '−€ ${Money.formatFromMinor(dash.stats.totalExpenseMinor, lang)}',
                    icon: Icons.trending_down,
                    iconBackground: scheme.secondaryFixed.withValues(
                      alpha: 0.5,
                    ),
                    iconColor: extras.expense,
                    footer: memberSpend.length >= 2
                        ? _MemberSplitBar(
                            shares: memberSpend,
                            locale: lang,
                            compact: true,
                          )
                        : null,
                  ),
                  KinshipKpiTile(
                    label: l10n.ledgerMonthlyInflows.toUpperCase(),
                    amountText:
                        '+€ ${Money.formatFromMinor(dash.stats.totalIncomeMinor, lang)}',
                    icon: Icons.payments_outlined,
                    amountColor: scheme.primary,
                    iconBackground: scheme.primaryFixed.withValues(alpha: 0.6),
                    iconColor: scheme.primaryContainer,
                  ),
                  KinshipKpiTile(
                    label: l10n.ledgerNetSavings.toUpperCase(),
                    amountText:
                        '${net >= 0 ? '+' : '−'}€ ${Money.formatFromMinor(net.abs(), lang)}',
                    icon: Icons.savings_outlined,
                    amountColor: scheme.primaryContainer,
                    iconBackground: scheme.tertiaryFixed,
                    iconColor: scheme.tertiary,
                  ),
                  KinshipKpiTile(
                    label: l10n.ledgerDataIntegrity.toUpperCase(),
                    amountText: '$totalCount',
                    icon: Icons.verified_outlined,
                    trend: Text(
                      l10n.ledgerRegistered,
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    footer: pendingCount > 0
                        ? Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: onOpenReview,
                              style: TextButton.styleFrom(
                                foregroundColor: extras.expense,
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 32),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(l10n.ledgerInReview(pendingCount)),
                            ),
                          )
                        : null,
                  ),
                ],
              );
            },
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
        SliverToBoxAdapter(
          child: KinshipCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: _SearchField(
                          controller: searchController,
                          hint: l10n.ledgerSearchPlaceholder,
                          onChanged: onSearchChanged,
                          filled: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Flexible(
                      child: _MemberFilterChips(
                        l10n: l10n,
                        members: members,
                        selectedMemberId: ctrl.filters.memberId,
                        thisMonthActive: thisMonthActive,
                        accountFilterActive: ctrl.filters.accountId != null,
                        onSelectMember: onSelectMember,
                        onToggleThisMonth: onToggleThisMonth,
                        onOpenFilters: onOpenFilters,
                        showSecondary: false,
                        denseCounts: true,
                        itemCount: totalCount,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _FilterBadge(
                        icon: Icons.category_outlined,
                        label: ctrl.filters.categoryId == null
                            ? '${l10n.filterCategory}: ${l10n.filterAll}'
                            : l10n.filterCategory,
                        onTap: onOpenFilters,
                      ),
                      _FilterBadge(
                        icon: Icons.credit_card_outlined,
                        label: ctrl.filters.accountId == null
                            ? '${l10n.filterAccount}: ${l10n.ledgerAllAccounts}'
                            : l10n.filterAccount,
                        onTap: onOpenFilters,
                      ),
                      _FilterBadge(
                        icon: Icons.tune,
                        label: l10n.transactionsFilters,
                        active: ctrl.filters.hasAny,
                        onTap: onOpenFilters,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
        SliverToBoxAdapter(
          child: KinshipCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.ledgerSortNewest,
                          style: textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Text(
                        l10n.ledgerShownOf(visible.length, ctrl.items.length),
                        style: textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  color: scheme.surfaceContainerLow,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      _TableHead(flex: 2, label: l10n.transactionBookingDate),
                      _TableHead(flex: 4, label: l10n.transactionMerchant),
                      _TableHead(flex: 2, label: l10n.filterMember),
                      _TableHead(flex: 2, label: l10n.filterAccount),
                      _TableHead(flex: 2, label: l10n.filterCategory),
                      _TableHead(
                        flex: 2,
                        label: l10n.transactionAmount,
                        alignEnd: true,
                      ),
                    ],
                  ),
                ),
                if (ctrl.isEmpty || visible.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Center(child: Text(l10n.transactionsEmpty)),
                  )
                else
                  for (final tx in visible)
                    _WebTableRow(
                      tx: tx,
                      l10n: l10n,
                      locale: lang,
                      memberName: membersById[tx.createdByUserId],
                      accountName: accountsById[tx.accountId],
                      category: tx.categoryId == null
                          ? null
                          : categoriesById[tx.categoryId!],
                      onTap: () => onOpenTransaction(tx),
                      onDelete: () => onDelete(tx),
                    ),
                if (ctrl.hasMore)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Center(
                      child: ctrl.loadingMore
                          ? const CircularProgressIndicator()
                          : TextButton(
                              onPressed: ctrl.loadMore,
                              child: Text(l10n.actionLoadMore),
                            ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared UI bits
// ---------------------------------------------------------------------------

class _SearchFilterRow extends StatelessWidget {
  const _SearchFilterRow({
    required this.controller,
    required this.hint,
    required this.filtersActive,
    required this.onChanged,
    required this.onOpenFilters,
  });

  final TextEditingController controller;
  final String hint;
  final bool filtersActive;
  final ValueChanged<String> onChanged;
  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: _SearchField(
            controller: controller,
            hint: hint,
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Material(
          color: scheme.surfaceContainerLow,
          borderRadius: AppRadius.mdAll,
          child: InkWell(
            onTap: onOpenFilters,
            borderRadius: AppRadius.mdAll,
            child: SizedBox(
              width: AppSizes.minTapTarget,
              height: AppSizes.minTapTarget,
              child: Badge(
                isLabelVisible: filtersActive,
                child: Icon(Icons.tune, color: scheme.onSurface),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.filled = false,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final extras = AppExtraColors.of(context);
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search, size: 20),
        filled: true,
        fillColor: filled ? scheme.surfaceContainerLow : extras.inputContainer,
        border: OutlineInputBorder(
          borderRadius: filled ? AppRadius.fullAll : AppRadius.mdAll,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: filled ? AppRadius.fullAll : AppRadius.mdAll,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: filled ? AppRadius.fullAll : AppRadius.mdAll,
          borderSide: BorderSide(color: scheme.primaryContainer, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
    );
  }
}

class _MemberFilterChips extends StatelessWidget {
  const _MemberFilterChips({
    required this.l10n,
    required this.members,
    required this.selectedMemberId,
    required this.thisMonthActive,
    required this.accountFilterActive,
    required this.onSelectMember,
    required this.onToggleThisMonth,
    required this.onOpenFilters,
    this.showSecondary = true,
    this.denseCounts = false,
    this.itemCount = 0,
  });

  final AppLocalizations l10n;
  final List<FamilyMember> members;
  final String? selectedMemberId;
  final bool thisMonthActive;
  final bool accountFilterActive;
  final Future<void> Function(String? memberId) onSelectMember;
  final Future<void> Function(bool enable) onToggleThisMonth;
  final VoidCallback onOpenFilters;
  final bool showSecondary;
  final bool denseCounts;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chips = <Widget>[
      KinshipFilterChip(
        label: denseCounts
            ? '${l10n.filterAll} ($itemCount)'
            : l10n.ledgerAllMembers,
        selected: selectedMemberId == null,
        onSelected: (_) => onSelectMember(null),
      ),
      for (var i = 0; i < members.length; i++)
        KinshipFilterChip(
          label: denseCounts
              ? members[i].displayName
              : l10n.ledgerMemberOnly(members[i].displayName),
          selected: selectedMemberId == members[i].userId,
          showCheckWhenSelected: !denseCounts,
          leading: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i.isEven ? scheme.primary : scheme.secondary,
            ),
          ),
          onSelected: (_) => onSelectMember(members[i].userId),
        ),
    ];

    if (showSecondary) {
      chips.addAll([
        Container(width: 1, height: 20, color: scheme.surfaceContainerHigh),
        KinshipFilterChip(
          label: l10n.ledgerThisMonth,
          selected: thisMonthActive,
          showCheckWhenSelected: false,
          leading: const Icon(Icons.calendar_today_outlined, size: 14),
          onSelected: (_) => onToggleThisMonth(!thisMonthActive),
        ),
        KinshipFilterChip(
          label: l10n.ledgerAllAccounts,
          selected: !accountFilterActive,
          showCheckWhenSelected: false,
          leading: const Icon(Icons.account_balance_outlined, size: 14),
          onSelected: (_) => onOpenFilters(),
        ),
      ]);
    }

    return KinshipFilterChips(children: chips);
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({
    required this.label,
    required this.netText,
    required this.isPositive,
  });

  final String label;
  final String netText;
  final bool isPositive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxs,
        0,
        AppSpacing.xxs,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            netText,
            style: textTheme.labelSmall?.copyWith(
              color: isPositive ? scheme.primary : scheme.onSurfaceVariant,
              fontWeight: isPositive ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _TxLedgerCard extends StatelessWidget {
  const _TxLedgerCard({
    required this.tx,
    required this.l10n,
    required this.locale,
    required this.memberName,
    required this.category,
    required this.onTap,
    required this.onLongPress,
  });

  final LedgerTransaction tx;
  final AppLocalizations l10n;
  final String locale;
  final String? memberName;
  final Category? category;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isOut = _isOutflow(tx);
    final isIncome =
        tx.type == TransactionType.income ||
        tx.type == TransactionType.refund ||
        (tx.type == TransactionType.transfer &&
            tx.transferRole == TransferRole.destination);
    final amount =
        '${isOut ? '−' : '+'} € ${Money.formatFromMinor(tx.amountMinor, locale)}';
    final title = tx.merchant?.isNotEmpty == true
        ? tx.merchant!
        : transactionTypeLabel(l10n, tx.type);
    final icon = _categoryIcon(category, tx.type);
    final iconBg = isIncome
        ? scheme.primaryContainer
        : (category == null
              ? scheme.surfaceContainerHigh
              : scheme.primaryFixed.withValues(alpha: 0.5));
    final iconFg = isIncome ? scheme.onPrimary : scheme.primary;

    return KinshipCard(
      color: isIncome
          ? scheme.primaryFixed.withValues(alpha: 0.2)
          : scheme.surfaceContainerLowest,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      onTap: tx.type.isManual ? onTap : null,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: KinshipLedgerRow(
          title: title,
          amountText: amount,
          isIncome: isIncome,
          leadingIcon: icon,
          leadingBackground: iconBg,
          leadingForeground: iconFg,
          attribution: memberName,
          timestamp: _timeLabel(tx),
          categoryLabel: category == null
              ? null
              : categoryLabel(l10n, category!),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _WebTableRow extends StatelessWidget {
  const _WebTableRow({
    required this.tx,
    required this.l10n,
    required this.locale,
    required this.memberName,
    required this.accountName,
    required this.category,
    required this.onTap,
    required this.onDelete,
  });

  final LedgerTransaction tx;
  final AppLocalizations l10n;
  final String locale;
  final String? memberName;
  final String? accountName;
  final Category? category;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isOut = _isOutflow(tx);
    final isIncome =
        !isOut &&
        (tx.type == TransactionType.income ||
            tx.type == TransactionType.refund ||
            tx.type == TransactionType.transfer);
    final amount =
        '${isOut ? '−' : '+'}€ ${Money.formatFromMinor(tx.amountMinor, locale)}';
    final title = tx.merchant?.isNotEmpty == true
        ? tx.merchant!
        : transactionTypeLabel(l10n, tx.type);
    final date = parseBookingDate(tx.bookingDate);
    final dateLabel = date == null
        ? tx.bookingDate
        : DateFormat('d MMM', locale).format(date);
    final icon = _categoryIcon(category, tx.type);

    return Material(
      color: isIncome
          ? scheme.primaryFixed.withValues(alpha: 0.1)
          : Colors.transparent,
      child: InkWell(
        onTap: tx.type.isManual ? onTap : null,
        onLongPress: onDelete,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  dateLabel,
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isIncome
                            ? scheme.primaryFixed
                            : scheme.primaryFixed.withValues(alpha: 0.4),
                        borderRadius: AppRadius.mdAll,
                      ),
                      child: Icon(
                        icon,
                        size: 18,
                        color: isIncome
                            ? scheme.primary
                            : scheme.primaryContainer,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: memberName == null
                    ? const SizedBox.shrink()
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.secondaryFixed.withValues(alpha: 0.4),
                            borderRadius: AppRadius.fullAll,
                          ),
                          child: Text(
                            memberName!,
                            style: textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  accountName ?? '—',
                  style: textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 2,
                child: category == null
                    ? const SizedBox.shrink()
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainer,
                            borderRadius: AppRadius.fullAll,
                          ),
                          child: Text(
                            categoryLabel(l10n, category!),
                            style: textTheme.labelSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  amount,
                  textAlign: TextAlign.end,
                  style: AppTextStyles.tabularAmountMd(context)?.copyWith(
                    color: isIncome ? scheme.primary : scheme.onSurface,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TableHead extends StatelessWidget {
  const _TableHead({
    required this.flex,
    required this.label,
    this.alignEnd = false,
  });

  final int flex;
  final String label;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      flex: flex,
      child: Text(
        label.toUpperCase(),
        textAlign: alignEnd ? TextAlign.end : TextAlign.start,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _FilterBadge extends StatelessWidget {
  const _FilterBadge({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: active ? scheme.primaryContainer : scheme.surfaceContainerLow,
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: active ? scheme.onPrimary : scheme.outline,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: active ? scheme.onPrimary : scheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.expand_more,
                size: 14,
                color: active ? scheme.onPrimary : scheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthChip extends StatelessWidget {
  const _MonthChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      shape: const StadiumBorder(),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 10,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: scheme.primaryContainer,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: active ? scheme.primary : scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberSplitBar extends StatelessWidget {
  const _MemberSplitBar({
    required this.shares,
    required this.locale,
    this.compact = false,
  });

  final List<_MemberSpendShare> shares;
  final String locale;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (shares.length < 2) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final a = shares[0];
    final b = shares[1];
    final aPct = (a.ratio * 100).round();
    final bPct = 100 - aPct;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '${a.name}: $aPct% (€ ${Money.formatFromMinor(a.amountMinor, locale)})',
                      style: textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      '${b.name}: $bPct% (€ ${Money.formatFromMinor(b.amountMinor, locale)})',
                      style: textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 6 : 8),
        ClipRRect(
          borderRadius: AppRadius.fullAll,
          child: SizedBox(
            height: 10,
            child: Row(
              children: [
                Expanded(
                  flex: aPct.clamp(1, 99),
                  child: ColoredBox(color: scheme.primaryContainer),
                ),
                Expanded(
                  flex: bPct.clamp(1, 99),
                  child: ColoredBox(color: scheme.secondaryContainer),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

class _DayGroup {
  const _DayGroup({
    required this.date,
    required this.items,
    required this.netMinor,
  });

  final DateTime date;
  final List<LedgerTransaction> items;
  final int netMinor;
}

List<_DayGroup> _groupByDay(List<LedgerTransaction> items) {
  final map = <String, List<LedgerTransaction>>{};
  for (final tx in items) {
    map.putIfAbsent(tx.bookingDate, () => []).add(tx);
  }
  final keys = map.keys.toList()..sort((a, b) => b.compareTo(a));
  return [
    for (final key in keys)
      _DayGroup(
        date: parseBookingDate(key) ?? DateTime.now(),
        items: map[key]!,
        netMinor: map[key]!.fold<int>(0, (sum, tx) {
          final signed = _isOutflow(tx) ? -tx.amountMinor : tx.amountMinor;
          return sum + signed;
        }),
      ),
  ];
}

bool _isOutflow(LedgerTransaction tx) {
  return tx.type == TransactionType.expense ||
      (tx.type == TransactionType.transfer &&
          tx.transferRole == TransferRole.source);
}

String _formatSignedNet(int netMinor, String locale) {
  final sign = netMinor >= 0 ? '+' : '−';
  return '$sign € ${Money.formatFromMinor(netMinor.abs(), locale)}';
}

String _monthTitle(String periodId, String locale) {
  final parts = periodId.split('-');
  if (parts.length < 2) return periodId;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  if (year == null || month == null) return periodId;
  return DateFormat('MMMM yyyy', locale).format(DateTime(year, month));
}

String _dayGroupLabel(AppLocalizations l10n, String locale, DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final pretty = DateFormat('d MMMM', locale).format(date);
  if (day == today) return l10n.ledgerDayToday(pretty);
  if (day == today.subtract(const Duration(days: 1))) {
    return l10n.ledgerDayYesterday(pretty);
  }
  return pretty;
}

String? _timeLabel(LedgerTransaction tx) {
  final created = tx.createdAt;
  if (created == null) return null;
  return DateFormat('HH:mm').format(created);
}

IconData _categoryIcon(Category? category, TransactionType type) {
  if (type == TransactionType.income || type == TransactionType.refund) {
    return Icons.payments_outlined;
  }
  if (type == TransactionType.transfer) {
    return Icons.swap_horiz;
  }
  final key = category?.nameKey;
  return switch (key) {
    'categoryFood' => Icons.shopping_cart_outlined,
    'categoryTransport' => Icons.local_gas_station_outlined,
    'categoryHousing' => Icons.home_outlined,
    'categoryUtilities' => Icons.bolt_outlined,
    'categoryHealth' => Icons.local_pharmacy_outlined,
    'categoryEntertainment' => Icons.celebration_outlined,
    'categoryShopping' => Icons.checkroom_outlined,
    'categoryEducation' => Icons.school_outlined,
    'categorySalary' => Icons.account_balance_outlined,
    _ => Icons.receipt_long_outlined,
  };
}
