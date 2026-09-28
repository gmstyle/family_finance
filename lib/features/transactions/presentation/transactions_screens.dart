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
import '../../accounts/data/accounts_repository.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../categories/data/categories_repository.dart';
import '../../family/data/family_repository.dart';
import '../../ledger/ledger_labels.dart';
import '../data/transactions_repository.dart';
import 'transactions_controller.dart';

String transactionTypeLabel(AppLocalizations l10n, TransactionType type) {
  return switch (type) {
    TransactionType.expense => l10n.transactionTypeExpense,
    TransactionType.income => l10n.transactionTypeIncome,
    TransactionType.refund => l10n.transactionTypeRefund,
    TransactionType.transfer => l10n.transactionTypeTransfer,
  };
}

class TransactionsListScreen extends StatefulWidget {
  const TransactionsListScreen({super.key});

  @override
  State<TransactionsListScreen> createState() => _TransactionsListScreenState();
}

class _TransactionsListScreenState extends State<TransactionsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final familyId = context.read<AuthController>().familyId;
      if (familyId != null) {
        context.read<TransactionsController>().bindFamily(familyId);
      }
    });
  }

  Future<void> _openFilters() async {
    final ctrl = context.read<TransactionsController>();
    final result = await showModalBottomSheet<TransactionFilters>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _FiltersSheet(initial: ctrl.filters),
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

    final repo = context.read<TransactionsController>().repository;
    try {
      if (tx.type == TransactionType.transfer && tx.transferId != null) {
        await repo.deleteTransfer(tx.transferId!);
      } else {
        await repo.deleteManualTransaction(
          familyId: familyId,
          transactionId: tx.id,
        );
      }
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
    final auth = context.watch<AuthController>();
    final ctrl = context.watch<TransactionsController>();
    final locale = context.watch<LocaleController>().locale.languageCode;
    final familyId = auth.familyId;
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

class _FiltersSheet extends StatefulWidget {
  const _FiltersSheet({required this.initial});

  final TransactionFilters initial;

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late String? _accountId = widget.initial.accountId;
  late String? _categoryId = widget.initial.categoryId;
  late String? _memberId = widget.initial.memberId;
  late String? _from = widget.initial.bookingDateFrom;
  late String? _to = widget.initial.bookingDateTo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final familyId = context.read<AuthController>().familyId!;
    final accountsRepo = context.read<AccountsRepository>();
    final categoriesRepo = context.read<CategoriesRepository>();
    final familyRepo = context.read<FamilyController>().repository;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.transactionsFilters,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            StreamBuilder(
              stream: accountsRepo.watchAccounts(familyId),
              builder: (context, snap) {
                final accounts = snap.data ?? const <Account>[];
                return DropdownButtonFormField<String?>(
                  // ignore: deprecated_member_use
                  value: _accountId,
                  decoration: InputDecoration(labelText: l10n.filterAccount),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l10n.filterAll)),
                    ...accounts.map(
                      (a) => DropdownMenuItem(value: a.id, child: Text(a.name)),
                    ),
                  ],
                  onChanged: (v) => setState(() => _accountId = v),
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            StreamBuilder(
              stream: categoriesRepo.watchCategories(familyId),
              builder: (context, snap) {
                final cats = snap.data ?? const <Category>[];
                return DropdownButtonFormField<String?>(
                  // ignore: deprecated_member_use
                  value: _categoryId,
                  decoration: InputDecoration(labelText: l10n.filterCategory),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l10n.filterAll)),
                    ...cats.map(
                      (c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(categoryLabel(l10n, c)),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _categoryId = v),
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            StreamBuilder(
              stream: familyRepo.watchMembers(familyId),
              builder: (context, snap) {
                final members = snap.data ?? const <FamilyMember>[];
                return DropdownButtonFormField<String?>(
                  // ignore: deprecated_member_use
                  value: _memberId,
                  decoration: InputDecoration(labelText: l10n.filterMember),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l10n.filterAll)),
                    ...members.map(
                      (m) => DropdownMenuItem(
                        value: m.userId,
                        child: Text(m.displayName),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _memberId = v),
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.filterDateFrom),
              subtitle: Text(_from ?? l10n.filterAll),
              trailing: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => setState(() => _from = null),
              ),
              onTap: () async {
                final v = await pickBookingDate(context, initial: _from);
                if (v != null) setState(() => _from = v);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.filterDateTo),
              subtitle: Text(_to ?? l10n.filterAll),
              trailing: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => setState(() => _to = null),
              ),
              onTap: () async {
                final v = await pickBookingDate(context, initial: _to);
                if (v != null) setState(() => _to = v);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        Navigator.pop(context, const TransactionFilters()),
                    child: Text(l10n.actionClearFilters),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(
                      context,
                      TransactionFilters(
                        accountId: _accountId,
                        categoryId: _categoryId,
                        memberId: _memberId,
                        bookingDateFrom: _from,
                        bookingDateTo: _to,
                      ),
                    ),
                    child: Text(l10n.actionApply),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TransactionEditorScreen extends StatefulWidget {
  const TransactionEditorScreen({super.key, this.transactionId});

  final String? transactionId;

  @override
  State<TransactionEditorScreen> createState() =>
      _TransactionEditorScreenState();
}

class _TransactionEditorScreenState extends State<TransactionEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _merchant = TextEditingController();
  final _note = TextEditingController();

  TransactionType _type = TransactionType.expense;
  String? _accountId;
  String? _categoryId;
  String _bookingDate = '';
  String _currency = 'EUR';
  bool _loading = true;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.transactionId != null;

  @override
  void initState() {
    super.initState();
    _bookingDate = formatBookingDate(DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final familyId = context.read<AuthController>().familyId;
    final locale = context.read<LocaleController>().locale.languageCode;
    final familyRepo = context.read<FamilyController>().repository;
    final txRepo = context.read<TransactionsController>().repository;
    final notFound = AppLocalizations.of(context)!.ledgerNotFound;
    if (familyId == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final family = await familyRepo.watchFamily(familyId).first;
      _currency = family?.currency ?? 'EUR';

      if (widget.transactionId != null) {
        final tx = await txRepo.getTransaction(familyId, widget.transactionId!);
        if (!mounted) return;
        if (tx == null || !tx.type.isManual) {
          setState(() {
            _error = notFound;
            _loading = false;
          });
          return;
        }
        _type = tx.type;
        _accountId = tx.accountId;
        _categoryId = tx.categoryId;
        _amount.text = Money.formatFromMinor(tx.amountMinor, locale);
        _bookingDate = tx.bookingDate;
        _merchant.text = tx.merchant ?? '';
        _note.text = tx.note ?? '';
        _currency = tx.currency;
      }
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
    if (familyId == null || _accountId == null || _categoryId == null) {
      setState(() => _error = l10n.transactionFormIncomplete);
      return;
    }
    final locale = context.read<LocaleController>().locale.languageCode;

    late final int amountMinor;
    try {
      amountMinor = Money.parseToMinor(_amount.text, locale);
      if (amountMinor <= 0) throw const FormatException('zero');
    } catch (_) {
      setState(() => _error = l10n.moneyInvalid);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    final repo = context.read<TransactionsController>().repository;
    try {
      if (_isEdit) {
        await repo.updateManualTransaction(
          familyId: familyId,
          transactionId: widget.transactionId!,
          type: _type,
          accountId: _accountId!,
          categoryId: _categoryId!,
          amountMinor: amountMinor,
          bookingDate: _bookingDate,
          merchant: _merchant.text,
          note: _note.text,
        );
      } else {
        await repo.createManualTransaction(
          familyId: familyId,
          type: _type,
          accountId: _accountId!,
          categoryId: _categoryId!,
          amountMinor: amountMinor,
          currency: _currency,
          bookingDate: _bookingDate,
          merchant: _merchant.text,
          note: _note.text,
        );
      }
      // List updates via the live Firestore subscription.
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _merchant.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final familyId = context.watch<AuthController>().familyId;
    final theme = Theme.of(context);

    if (familyId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.transactionCreateTitle)),
        body: Center(child: Text(l10n.familyMissing)),
      );
    }

    final categoryType = switch (_type) {
      TransactionType.income => CategoryType.income,
      TransactionType.expense ||
      TransactionType.refund ||
      TransactionType.transfer => CategoryType.expense,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? l10n.transactionEditTitle : l10n.transactionCreateTitle,
        ),
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
                    DropdownButtonFormField<TransactionType>(
                      // ignore: deprecated_member_use
                      value: _type,
                      decoration: InputDecoration(
                        labelText: l10n.transactionType,
                      ),
                      items:
                          [
                                TransactionType.expense,
                                TransactionType.income,
                                TransactionType.refund,
                              ]
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(transactionTypeLabel(l10n, t)),
                                ),
                              )
                              .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          _type = v;
                          _categoryId = null;
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    StreamBuilder(
                      stream: context.read<AccountsRepository>().watchAccounts(
                        familyId,
                      ),
                      builder: (context, snap) {
                        final accounts = snap.data ?? const <Account>[];
                        return DropdownButtonFormField<String>(
                          // ignore: deprecated_member_use
                          value: _accountId,
                          decoration: InputDecoration(
                            labelText: l10n.filterAccount,
                          ),
                          items: accounts
                              .map(
                                (a) => DropdownMenuItem(
                                  value: a.id,
                                  child: Text(a.name),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _accountId = v),
                          validator: (v) =>
                              v == null ? l10n.transactionFormIncomplete : null,
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    StreamBuilder(
                      stream: context
                          .read<CategoriesRepository>()
                          .watchCategories(familyId, type: categoryType),
                      builder: (context, snap) {
                        final cats = snap.data ?? const <Category>[];
                        return DropdownButtonFormField<String>(
                          // ignore: deprecated_member_use
                          value: _categoryId,
                          decoration: InputDecoration(
                            labelText: l10n.filterCategory,
                          ),
                          items: cats
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(categoryLabel(l10n, c)),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _categoryId = v),
                          validator: (v) =>
                              v == null ? l10n.transactionFormIncomplete : null,
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _amount,
                      decoration: InputDecoration(
                        labelText: l10n.transactionAmount,
                        suffixText: _currency,
                      ),
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
                    const SizedBox(height: AppSpacing.md),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.transactionBookingDate),
                      subtitle: Text(_bookingDate),
                      trailing: const Icon(Icons.calendar_today_outlined),
                      onTap: () async {
                        final v = await pickBookingDate(
                          context,
                          initial: _bookingDate,
                        );
                        if (v != null) setState(() => _bookingDate = v);
                      },
                    ),
                    TextFormField(
                      controller: _merchant,
                      decoration: InputDecoration(
                        labelText: l10n.transactionMerchant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _note,
                      decoration: InputDecoration(
                        labelText: l10n.transactionNote,
                      ),
                      maxLines: 2,
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
