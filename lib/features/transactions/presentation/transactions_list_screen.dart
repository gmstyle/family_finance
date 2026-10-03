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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final familyId = context.watch<AuthController>().familyId;
    if (familyId != _boundFamilyId) {
      _boundFamilyId = familyId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<TransactionsController>().bindFamily(familyId);
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
      // List updates via the live Firestore subscription.
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final familyId = context.select((AuthController c) => c.familyId);
    final ctrl = context.watch<TransactionsController>();
    final locale = context.watch<LocaleController>().locale.languageCode;
    final extras = AppExtraColors.of(context);

    if (familyId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.transactionsTitle)),
        body: Center(child: Text(l10n.familyMissing)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.transactionsTitle),
        actions: [
          IconButton(
            tooltip: l10n.transactionsFilters,
            onPressed: _openFilters,
            icon: Badge(
              isLabelVisible: ctrl.filters.hasAny,
              child: const Icon(Icons.filter_list),
            ),
          ),
          IconButton(
            tooltip: l10n.transferCreateTitle,
            onPressed: () => context.push(AppRoutes.transferNew),
            icon: const Icon(Icons.swap_horiz),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.transactionNew),
        child: const Icon(Icons.add),
      ),
      body: AppPage(
        child: LedgerAsyncBody(
          isLoading: ctrl.loading,
          errorMessage: ctrl.errorMessage,
          isEmpty: ctrl.isEmpty,
          emptyMessage: l10n.transactionsEmpty,
          onRetry: ctrl.refresh,
          child: RefreshIndicator(
            onRefresh: ctrl.refresh,
            child: ListView.builder(
              padding: AppInsets.pageCompact,
              itemCount: ctrl.items.length + (ctrl.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= ctrl.items.length) {
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Center(
                      child: ctrl.loadingMore
                          ? const CircularProgressIndicator()
                          : TextButton(
                              onPressed: ctrl.loadMore,
                              child: Text(l10n.actionLoadMore),
                            ),
                    ),
                  );
                }
                final tx = ctrl.items[index];
                final amount = Money.formatFromMinor(tx.amountMinor, locale);
                final isOut =
                    tx.type == TransactionType.expense ||
                    (tx.type == TransactionType.transfer &&
                        tx.transferRole == TransferRole.source);
                final color = isOut ? extras.expense : extras.income;
                final sign = isOut ? '−' : '+';

                return ListTile(
                  title: Text(
                    tx.merchant?.isNotEmpty == true
                        ? tx.merchant!
                        : transactionTypeLabel(l10n, tx.type),
                  ),
                  subtitle: Text(
                    '${tx.bookingDate}'
                    '${tx.note?.isNotEmpty == true ? ' · ${tx.note}' : ''}',
                  ),
                  trailing: Text(
                    '$sign$amount ${tx.currency}',
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(color: color),
                  ),
                  onTap: tx.type.isManual
                      ? () => context.push(AppRoutes.transactionEditPath(tx.id))
                      : null,
                  onLongPress: () => _confirmDelete(tx),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
