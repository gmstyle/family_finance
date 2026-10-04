import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/locale/locale_controller.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/ui/app_page.dart';
import '../../../l10n/app_localizations.dart';
import '../../accounts/domain/account.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../budgets/domain/budget.dart';
import '../../categories/domain/category.dart';
import '../../categories/presentation/categories_controller.dart';
import '../../ledger/ledger_labels.dart';
import '../domain/ingestion.dart';
import 'ingestion_controller.dart';

/// Review / edit a single draft — Confirm creates the ledger transaction.
class IngestionDetailScreen extends StatefulWidget {
  const IngestionDetailScreen({super.key, required this.dedupKey});

  final String dedupKey;

  @override
  State<IngestionDetailScreen> createState() => _IngestionDetailScreenState();
}

class _IngestionDetailScreenState extends State<IngestionDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _merchant = TextEditingController();

  String? _accountId;
  String? _categoryId;
  String _bookingDate = '';
  String _currency = 'EUR';
  bool _loading = true;
  bool _busy = false;
  bool _saveMerchantRule = true;
  String? _error;
  IngestionDraft? _draft;
  String? _boundFamilyId;

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
        context.read<IngestionController>().bindFamily(familyId);
        context.read<CategoriesController>().bindFamily(familyId);
        if (_loading) _load();
      });
    }
  }

  Future<void> _load() async {
    final locale = context.read<LocaleController>().locale.languageCode;
    final ingestionCtrl = context.read<IngestionController>();
    final notFound = AppLocalizations.of(context)!.ledgerNotFound;

    try {
      _currency = ingestionCtrl.currency;
      final draft = await ingestionCtrl.getDraft(widget.dedupKey);
      if (!mounted) return;
      if (draft == null || !draft.isPending) {
        setState(() {
          _error = notFound;
          _loading = false;
        });
        return;
      }
      _draft = draft;
      _accountId = draft.accountId;
      _categoryId = draft.categoryId;
      _bookingDate = (draft.bookingDate?.isNotEmpty ?? false)
          ? draft.bookingDate!
          : formatBookingDate(DateTime.now());
      _merchant.text = draft.merchant ?? '';
      if (draft.amountMinor != null) {
        _amount.text = Money.formatFromMinor(draft.amountMinor!, locale);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  IngestionDraftUpdate? _validatedUpdate(AppLocalizations l10n) {
    if (!_formKey.currentState!.validate()) return null;
    if (_accountId == null || _categoryId == null) {
      setState(() => _error = l10n.transactionFormIncomplete);
      return null;
    }
    final locale = context.read<LocaleController>().locale.languageCode;
    late final int amountMinor;
    try {
      amountMinor = Money.parseToMinor(_amount.text, locale);
      if (amountMinor <= 0) throw const FormatException('zero');
    } catch (_) {
      setState(() => _error = l10n.moneyInvalid);
      return null;
    }
    return IngestionDraftUpdate(
      amountMinor: amountMinor,
      bookingDate: _bookingDate,
      accountId: _accountId!,
      categoryId: _categoryId!,
      merchant: _merchant.text,
    );
  }

  Future<void> _confirm() async {
    final l10n = AppLocalizations.of(context)!;
    final update = _validatedUpdate(l10n);
    if (update == null) return;

    final bookingPeriod = periodIdFromBookingDate(update.bookingDate);
    final currentPeriod = currentBudgetPeriodId();
    var finalUpdate = update;

    if (bookingPeriod != currentPeriod) {
      final choice = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.ingestionPeriodMismatchTitle),
          content: Text(
            l10n.ingestionPeriodMismatchBody(
              update.bookingDate,
              bookingPeriod,
              currentPeriod,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'cancel'),
              child: Text(l10n.actionCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'receipt'),
              child: Text(l10n.ingestionUseReceiptDate),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, 'today'),
              child: Text(l10n.ingestionUseTodayDate),
            ),
          ],
        ),
      );
      if (choice == null || choice == 'cancel' || !mounted) return;
      if (choice == 'today') {
        final today = formatBookingDate(DateTime.now());
        setState(() => _bookingDate = today);
        finalUpdate = IngestionDraftUpdate(
          amountMinor: update.amountMinor,
          bookingDate: today,
          accountId: update.accountId,
          categoryId: update.categoryId,
          merchant: update.merchant,
        );
      }
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<IngestionController>().confirmDraft(
        dedupKey: widget.dedupKey,
        update: finalUpdate,
        currency: _currency,
        saveMerchantRule: _saveMerchantRule,
      );
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _discard() async {
    final l10n = AppLocalizations.of(context)!;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.ingestionDiscardTitle),
        content: Text(l10n.ingestionDiscardBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.ingestionDiscardAction),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<IngestionController>().discardDraft(widget.dedupKey);
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _merchant.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final familyId = context.select((AuthController c) => c.familyId);
    final theme = Theme.of(context);
    final ingestionCtrl = context.watch<IngestionController>();
    final categoriesCtrl = context.watch<CategoriesController>();

    if (familyId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.ingestionReviewTitle)),
        body: Center(child: Text(l10n.familyMissing)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.ingestionReviewTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : AppPage(
              form: true,
              padding: AppInsets.page,
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    if (_draft != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Chip(
                            avatar: Icon(
                              _draft!.source == IngestionSource.notification
                                  ? Icons.notifications_outlined
                                  : Icons.document_scanner_outlined,
                              size: 18,
                            ),
                            label: Text(
                              _draft!.source == IngestionSource.notification
                                  ? l10n.ingestionSourceNotification
                                  : l10n.ingestionSourceReceiptOcr,
                            ),
                          ),
                        ),
                      ),
                    if (_draft?.status == IngestionStatus.possibleDuplicate)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Material(
                          color: theme.colorScheme.tertiaryContainer.withValues(
                            alpha: 0.55,
                          ),
                          borderRadius: AppRadius.mdAll,
                          child: Padding(
                            padding: AppInsets.card,
                            child: Text(
                              l10n.ingestionPossibleDuplicateHint,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ),
                      ),
                    StreamBuilder<List<Account>>(
                      stream: ingestionCtrl.watchAccounts(),
                      builder: (context, snap) {
                        final accounts = snap.data ?? ingestionCtrl.accounts;
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
                    StreamBuilder<List<Category>>(
                      stream: categoriesCtrl.watchCategories(
                        type: CategoryType.expense,
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
                        suffixText: ingestionCtrl.currency,
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
                    if (periodIdFromBookingDate(_bookingDate) !=
                        currentBudgetPeriodId()) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Material(
                        color: theme.colorScheme.tertiaryContainer,
                        borderRadius: AppRadius.mdAll,
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Text(
                            l10n.ingestionPeriodMismatchBody(
                              _bookingDate,
                              periodIdFromBookingDate(_bookingDate),
                              currentBudgetPeriodId(),
                            ),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onTertiaryContainer,
                            ),
                          ),
                        ),
                      ),
                    ],
                    TextFormField(
                      controller: _merchant,
                      decoration: InputDecoration(
                        labelText: l10n.transactionMerchant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.ingestionSaveMerchantRule),
                      subtitle: Text(l10n.ingestionSaveMerchantRuleHint),
                      value: _saveMerchantRule,
                      onChanged: (v) => setState(() => _saveMerchantRule = v),
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
                      onPressed: _busy ? null : _confirm,
                      child: _busy
                          ? const SizedBox(
                              width: AppSizes.buttonProgress,
                              height: AppSizes.buttonProgress,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.ingestionConfirmAction),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton(
                      onPressed: _busy ? null : _discard,
                      child: Text(l10n.ingestionDiscardAction),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
