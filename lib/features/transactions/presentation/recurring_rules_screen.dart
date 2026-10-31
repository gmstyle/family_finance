import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/locale/locale_controller.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/ui/kinship_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/ledger_async_body.dart';
import '../../accounts/domain/account.dart';
import '../../accounts/presentation/accounts_controller.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../categories/domain/category.dart';
import '../../categories/presentation/categories_controller.dart';
import '../../ledger/ledger_labels.dart';
import '../domain/recurring_rule.dart';
import '../domain/transaction.dart';
import 'recurring_rules_controller.dart';
import 'transaction_labels.dart';

class RecurringRulesScreen extends StatefulWidget {
  const RecurringRulesScreen({super.key});

  @override
  State<RecurringRulesScreen> createState() => _RecurringRulesScreenState();
}

class _RecurringRulesScreenState extends State<RecurringRulesScreen> {
  String? _boundFamilyId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final familyId = context.watch<AuthController>().familyId;
    if (familyId != _boundFamilyId) {
      _boundFamilyId = familyId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<RecurringRulesController>().bindFamily(familyId);
        context.read<AccountsController>().bindFamily(familyId);
        context.read<CategoriesController>().bindFamily(familyId);
      });
    }
  }

  Future<void> _confirmDelete(RecurringRule rule) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.recurringDeleteTitle),
        content: Text(l10n.recurringDeleteBody),
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
      await context.read<RecurringRulesController>().deleteRule(rule.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _toggleActive(RecurringRule rule) async {
    try {
      await context.read<RecurringRulesController>().setActive(
        ruleId: rule.id,
        active: !rule.active,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _editRule(RecurringRule rule) async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _RecurringRuleEditSheet(rule: rule),
    );
    if (updated == true && mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.recurringUpdated)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final familyId = context.select((AuthController c) => c.familyId);
    final ctrl = context.watch<RecurringRulesController>();
    final locale = context.watch<LocaleController>().locale.languageCode;
    final accounts = context.watch<AccountsController>().items;
    final categories = context.watch<CategoriesController>().items;

    if (familyId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.recurringTitle)),
        body: Center(child: Text(l10n.familyMissing)),
      );
    }

    final accountsById = {for (final a in accounts) a.id: a.name};
    final categoriesById = {for (final c in categories) c.id: c};

    return Scaffold(
      appBar: AppBar(title: Text(l10n.recurringTitle)),
      body: AppPage(
        padding: AppInsets.page,
        child: LedgerAsyncBody(
          isLoading: ctrl.loading,
          errorMessage: ctrl.errorMessage,
          isEmpty: ctrl.isEmpty,
          emptyMessage: l10n.recurringEmpty,
          onRetry: ctrl.refresh,
          child: RefreshIndicator(
            onRefresh: ctrl.refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: ctrl.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final rule = ctrl.items[index];
                final category = categoriesById[rule.categoryId];
                final title = rule.merchant?.isNotEmpty == true
                    ? rule.merchant!
                    : (category == null
                          ? transactionTypeLabel(l10n, rule.type)
                          : categoryLabel(l10n, category));
                final amount =
                    '€ ${Money.formatFromMinor(rule.amountMinor, locale)}';
                final accountName = accountsById[rule.accountId] ?? '—';
                final subtitleParts = <String>[
                  l10n.recurringRuleSubtitle(
                    rule.dayOfMonth,
                    rule.nextBookingDate,
                    accountName,
                  ),
                  if (rule.endBookingDate != null)
                    l10n.recurringEndsOn(rule.endBookingDate!)
                  else
                    l10n.recurringOpenEnded,
                ];
                final subtitle = subtitleParts.join(' · ');

                return KinshipCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  onTap: () => _editRule(rule),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      KinshipLedgerRow(
                        title: title,
                        amountText: amount,
                        isIncome: rule.type == TransactionType.income,
                        leadingIcon: rule.type == TransactionType.income
                            ? Icons.payments_outlined
                            : Icons.replay_outlined,
                        attribution: rule.active
                            ? l10n.recurringActive
                            : l10n.recurringPaused,
                        timestamp: subtitle,
                        categoryLabel: category == null
                            ? null
                            : categoryLabel(l10n, category),
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          TextButton(
                            onPressed: ctrl.busy
                                ? null
                                : () => _toggleActive(rule),
                            child: Text(
                              rule.active
                                  ? l10n.recurringPause
                                  : l10n.recurringResume,
                            ),
                          ),
                          TextButton(
                            onPressed: ctrl.busy ? null : () => _editRule(rule),
                            child: Text(l10n.recurringEdit),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: ctrl.busy
                                ? null
                                : () => _confirmDelete(rule),
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(context)
                                  .colorScheme
                                  .error,
                            ),
                            child: Text(l10n.actionDelete),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _RecurringRuleEditSheet extends StatefulWidget {
  const _RecurringRuleEditSheet({required this.rule});

  final RecurringRule rule;

  @override
  State<_RecurringRuleEditSheet> createState() =>
      _RecurringRuleEditSheetState();
}

class _RecurringRuleEditSheetState extends State<_RecurringRuleEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  late final TextEditingController _note;
  String? _accountId;
  String? _categoryId;
  late bool _hasEnd;
  String? _endBookingDate;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final locale =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    _amount = TextEditingController(
      text: Money.formatFromMinor(widget.rule.amountMinor, locale),
    );
    _note = TextEditingController(text: widget.rule.note ?? '');
    _accountId = widget.rule.accountId;
    _categoryId = widget.rule.categoryId;
    _endBookingDate = widget.rule.endBookingDate;
    _hasEnd = _endBookingDate != null && _endBookingDate!.isNotEmpty;
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickEndDate() async {
    final initial = _endBookingDate ?? widget.rule.nextBookingDate;
    final picked = await pickBookingDate(context, initial: initial);
    if (picked != null) setState(() => _endBookingDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;
    if (_accountId == null || _categoryId == null) {
      setState(() => _error = l10n.transactionFormIncomplete);
      return;
    }
    if (_hasEnd && (_endBookingDate == null || _endBookingDate!.isEmpty)) {
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
    try {
      await context.read<RecurringRulesController>().updateRuleDetails(
        ruleId: widget.rule.id,
        accountId: _accountId!,
        categoryId: _categoryId!,
        amountMinor: amountMinor,
        merchant: widget.rule.merchant,
        note: _note.text,
        endBookingDate: _hasEnd ? _endBookingDate : null,
        clearEndBookingDate: !_hasEnd,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final categoryType = widget.rule.type == TransactionType.income
        ? CategoryType.income
        : CategoryType.expense;
    final accountsCtrl = context.watch<AccountsController>();
    final categoriesCtrl = context.watch<CategoriesController>();
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        padding: AppInsets.page,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.recurringEdit,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.recurringMonthlyHint(widget.rule.dayOfMonth),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.recurringHasEndSwitch),
                value: _hasEnd,
                onChanged: (v) => setState(() {
                  _hasEnd = v;
                  if (v &&
                      (_endBookingDate == null || _endBookingDate!.isEmpty)) {
                    _endBookingDate = widget.rule.nextBookingDate;
                  }
                }),
              ),
              if (_hasEnd)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.recurringEndsOn(_endBookingDate ?? '—')),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: _pickEndDate,
                )
              else
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.recurringOpenEnded,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              StreamBuilder(
                stream: accountsCtrl.watchAccounts(),
                builder: (context, snap) {
                  final accounts = snap.data ?? const <Account>[];
                  return DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: _accountId,
                    decoration: InputDecoration(labelText: l10n.filterAccount),
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
                stream: categoriesCtrl.watchCategories(type: categoryType),
                builder: (context, snap) {
                  final cats = snap.data ?? const <Category>[];
                  return DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: _categoryId,
                    decoration: InputDecoration(labelText: l10n.filterCategory),
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
                  suffixText: widget.rule.currency,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return l10n.moneyInvalid;
                  try {
                    final n = Money.parseToMinor(
                      v,
                      context.read<LocaleController>().locale.languageCode,
                    );
                    if (n <= 0) return l10n.moneyInvalid;
                    return null;
                  } catch (_) {
                    return l10n.moneyInvalid;
                  }
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _note,
                decoration: InputDecoration(labelText: l10n.transactionNote),
                maxLines: 2,
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
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
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
