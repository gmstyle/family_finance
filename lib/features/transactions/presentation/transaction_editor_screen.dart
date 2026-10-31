import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/locale/locale_controller.dart';
import '../../../core/money/money.dart';
import '../../../core/router/app_router.dart';
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
import '../domain/recurring_rule.dart';
import '../domain/transaction.dart';
import 'recurring_rules_controller.dart';
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
  final _totalOccurrences = TextEditingController(text: '12');

  TransactionType _type = TransactionType.expense;
  String? _accountId;
  String? _categoryId;
  String _bookingDate = '';
  String _currency = 'EUR';
  bool _monthlyRecurring = false;
  bool _hasEnd = false;
  bool _loading = true;
  bool _saving = false;
  bool _ruleBusy = false;
  String? _error;
  String? _boundFamilyId;
  String? _linkedRuleId;
  RecurringRule? _linkedRule;
  bool _linkedRuleMissing = false;

  bool get _isEdit => widget.transactionId != null;

  bool get _canRecur =>
      _type == TransactionType.expense || _type == TransactionType.income;

  /// Create toggles when there is no live linked rule yet.
  bool get _showCreateRecurrenceControls =>
      _canRecur && _linkedRule == null && !_linkedRuleMissing;

  /// After a deleted rule id, allow starting a fresh recurrence on save.
  bool get _showCreateRecurrenceAfterMissing =>
      _canRecur && _linkedRuleMissing && _linkedRule == null;

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
        context.read<RecurringRulesController>().bindFamily(familyId);
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
    final rulesCtrl = context.read<RecurringRulesController>();
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
        _linkedRuleId = tx.recurringRuleId;
        if (_linkedRuleId != null && _linkedRuleId!.isNotEmpty) {
          await rulesCtrl.bindFamily(familyId);
          final rule = await rulesCtrl.getRule(_linkedRuleId!);
          if (!mounted) return;
          _linkedRule = rule;
          _linkedRuleMissing = rule == null;
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refreshLinkedRule() async {
    final ruleId = _linkedRuleId;
    final familyId = context.read<AuthController>().familyId;
    if (ruleId == null || familyId == null) return;
    final rulesCtrl = context.read<RecurringRulesController>();
    await rulesCtrl.bindFamily(familyId);
    final rule = await rulesCtrl.getRule(ruleId);
    if (!mounted) return;
    setState(() {
      _linkedRule = rule;
      _linkedRuleMissing = rule == null;
    });
  }

  int? _parseTotalOccurrences(AppLocalizations l10n) {
    if (!_hasEnd) return null;
    final totalOccurrences = int.tryParse(_totalOccurrences.text.trim());
    if (totalOccurrences == null || totalOccurrences < 2) {
      setState(() {
        _error = l10n.recurringTotalOccurrencesInvalid;
        _saving = false;
      });
      return null;
    }
    return totalOccurrences;
  }

  Future<void> _createAndAttachRule({
    required String familyId,
    required String transactionId,
    required int amountMinor,
    required int? totalOccurrences,
  }) async {
    final rulesCtrl = context.read<RecurringRulesController>();
    final txCtrl = context.read<TransactionsController>();
    await rulesCtrl.bindFamily(familyId);
    final ruleId = await rulesCtrl.createMonthlyRuleFromTransaction(
      type: _type,
      accountId: _accountId!,
      categoryId: _categoryId!,
      amountMinor: amountMinor,
      currency: _currency,
      bookingDate: _bookingDate,
      merchant: _merchant.text,
      note: _note.text,
      totalOccurrences: totalOccurrences,
    );
    await txCtrl.setRecurringRuleId(
      transactionId: transactionId,
      recurringRuleId: ruleId,
    );
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

    final wantsNewRule =
        _monthlyRecurring &&
        _canRecur &&
        _linkedRule == null &&
        (!_isEdit || _linkedRuleId == null || _linkedRuleMissing);

    int? totalOccurrences;
    if (wantsNewRule) {
      if (_hasEnd) {
        totalOccurrences = _parseTotalOccurrences(l10n);
        if (_hasEnd && totalOccurrences == null) return;
      }
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    final ctrl = context.read<TransactionsController>();
    try {
      late final String transactionId;
      if (_isEdit) {
        transactionId = widget.transactionId!;
        await ctrl.updateManualTransaction(
          transactionId: transactionId,
          type: _type,
          accountId: _accountId!,
          categoryId: _categoryId!,
          amountMinor: amountMinor,
          bookingDate: _bookingDate,
          merchant: _merchant.text,
          note: _note.text,
        );
      } else {
        transactionId = await ctrl.createManualTransaction(
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

      if (wantsNewRule) {
        await _createAndAttachRule(
          familyId: familyId,
          transactionId: transactionId,
          amountMinor: amountMinor,
          totalOccurrences: totalOccurrences,
        );
      }

      if (mounted) context.pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggleLinkedActive() async {
    final rule = _linkedRule;
    if (rule == null) return;
    setState(() => _ruleBusy = true);
    try {
      await context.read<RecurringRulesController>().setActive(
        ruleId: rule.id,
        active: !rule.active,
      );
      await _refreshLinkedRule();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _ruleBusy = false);
    }
  }

  Future<void> _stopLinkedRule() async {
    final rule = _linkedRule;
    final txId = widget.transactionId;
    if (rule == null || txId == null) return;
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.recurringStopTitle),
        content: Text(l10n.recurringStopBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.recurringStopAction),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _ruleBusy = true);
    try {
      final rulesCtrl = context.read<RecurringRulesController>();
      final txCtrl = context.read<TransactionsController>();
      await rulesCtrl.deleteRule(rule.id);
      await txCtrl.setRecurringRuleId(
        transactionId: txId,
        recurringRuleId: null,
      );
      if (!mounted) return;
      setState(() {
        _linkedRule = null;
        _linkedRuleId = null;
        _linkedRuleMissing = false;
        _monthlyRecurring = false;
        _hasEnd = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _ruleBusy = false);
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _merchant.dispose();
    _note.dispose();
    _totalOccurrences.dispose();
    super.dispose();
  }

  Widget _buildRecurrenceCreateControls(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.recurringMonthlySwitch),
          subtitle: Text(
            l10n.recurringMonthlyHint(parseBookingDate(_bookingDate)?.day ?? 1),
          ),
          value: _monthlyRecurring,
          onChanged: (v) => setState(() {
            _monthlyRecurring = v;
            if (!v) _hasEnd = false;
          }),
        ),
        if (_monthlyRecurring) ...[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.recurringHasEndSwitch),
            value: _hasEnd,
            onChanged: (v) => setState(() => _hasEnd = v),
          ),
          if (_hasEnd) ...[
            TextFormField(
              controller: _totalOccurrences,
              decoration: InputDecoration(
                labelText: l10n.recurringTotalOccurrences,
                helperText: l10n.recurringTotalOccurrencesHint,
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (!_hasEnd) return null;
                final n = int.tryParse((v ?? '').trim());
                if (n == null || n < 2) {
                  return l10n.recurringTotalOccurrencesInvalid;
                }
                return null;
              },
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildLinkedRuleCard(AppLocalizations l10n, ThemeData theme) {
    final rule = _linkedRule!;
    final status = rule.active ? l10n.recurringActive : l10n.recurringPaused;
    final lines = <String>[
      l10n.recurringLinkedBody(rule.dayOfMonth, rule.nextBookingDate),
      if (rule.endBookingDate != null)
        l10n.recurringEndsOn(rule.endBookingDate!)
      else
        l10n.recurringOpenEnded,
      status,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.recurringLinkedTitle, style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(lines.join(' · '), style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.recurringLinkedHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            TextButton(
              onPressed: _ruleBusy ? null : _toggleLinkedActive,
              child: Text(
                rule.active ? l10n.recurringPause : l10n.recurringResume,
              ),
            ),
            TextButton(
              onPressed: _ruleBusy
                  ? null
                  : () => context.push(AppRoutes.transactionsRecurring),
              child: Text(l10n.recurringEditManageAction),
            ),
            TextButton(
              onPressed: _ruleBusy ? null : _stopLinkedRule,
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
              child: Text(l10n.recurringStopAction),
            ),
          ],
        ),
      ],
    );
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
                      onChanged: (_linkedRule != null)
                          ? null
                          : (v) {
                              if (v == null) return;
                              setState(() {
                                _type = v;
                                _categoryId = null;
                                if (!_canRecur) {
                                  _monthlyRecurring = false;
                                  _hasEnd = false;
                                }
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
                    if (_canRecur) ...[
                      const SizedBox(height: AppSpacing.md),
                      if (_linkedRule != null)
                        _buildLinkedRuleCard(l10n, theme)
                      else ...[
                        if (_linkedRuleMissing) ...[
                          Text(
                            l10n.recurringLinkedMissing,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                        if (_showCreateRecurrenceControls ||
                            _showCreateRecurrenceAfterMissing)
                          _buildRecurrenceCreateControls(l10n),
                      ],
                    ],
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
