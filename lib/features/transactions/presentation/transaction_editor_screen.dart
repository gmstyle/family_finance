import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/locale/locale_controller.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/ui/app_page.dart';
import '../../../l10n/app_localizations.dart';
import '../../accounts/domain/account.dart';
import '../../accounts/presentation/accounts_controller.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../categories/domain/category.dart';
import '../../categories/presentation/categories_controller.dart';
import '../../family/presentation/family_controller.dart';
import '../../ledger/ledger_labels.dart';
import '../domain/transaction.dart';
import 'transaction_labels.dart';
import 'transactions_controller.dart';

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
  String? _boundFamilyId;

  bool get _isEdit => widget.transactionId != null;

  @override
  void initState() {
    super.initState();
    _bookingDate = formatBookingDate(DateTime.now());
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
        context.read<AccountsController>().bindFamily(familyId);
        context.read<CategoriesController>().bindFamily(familyId);
        if (_loading) _load();
      });
    }
  }

  Future<void> _load() async {
    final familyId = context.read<AuthController>().familyId;
    final locale = context.read<LocaleController>().locale.languageCode;
    final familyCtrl = context.read<FamilyController>();
    final accountsCtrl = context.read<AccountsController>();
    final txCtrl = context.read<TransactionsController>();
    final notFound = AppLocalizations.of(context)!.ledgerNotFound;
    if (familyId == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final family = await familyCtrl.watchFamily(familyId).first;
      _currency = family?.currency ?? accountsCtrl.currency;

      if (widget.transactionId != null) {
        final tx = await txCtrl.getTransaction(widget.transactionId!);
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
    final ctrl = context.read<TransactionsController>();
    try {
      if (_isEdit) {
        await ctrl.updateManualTransaction(
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
        await ctrl.createManualTransaction(
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
    final familyId = context.select((AuthController c) => c.familyId);
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
    final accountsCtrl = context.watch<AccountsController>();
    final categoriesCtrl = context.watch<CategoriesController>();

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
                      stream: accountsCtrl.watchAccounts(),
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
                      stream: categoriesCtrl.watchCategories(
                        type: categoryType,
                      ),
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
