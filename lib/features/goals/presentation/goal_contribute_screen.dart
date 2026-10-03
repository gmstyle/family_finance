import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/locale/locale_controller.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/ui/app_page.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../ledger/ledger_labels.dart';
import '../domain/goal.dart';
import 'goals_controller.dart';

class GoalContributeScreen extends StatefulWidget {
  const GoalContributeScreen({super.key, required this.goalId});

  final String goalId;

  @override
  State<GoalContributeScreen> createState() => _GoalContributeScreenState();
}

class _GoalContributeScreenState extends State<GoalContributeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  bool _isDeposit = true;
  String _bookingDate = '';
  bool _saving = false;
  String? _error;
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
        context.read<GoalsController>().bindFamily(familyId);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;
    final locale = context.read<LocaleController>().locale.languageCode;

    late final int absMinor;
    try {
      absMinor = Money.parseToMinor(_amount.text, locale);
    } catch (_) {
      setState(() => _error = l10n.moneyInvalid);
      return;
    }
    if (absMinor <= 0) {
      setState(() => _error = l10n.moneyInvalid);
      return;
    }
    final signed = _isDeposit ? absMinor : -absMinor;

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await context.read<GoalsController>().addContribution(
        goalId: widget.goalId,
        amountMinor: signed,
        bookingDate: _bookingDate,
      );
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = context.watch<LocaleController>().locale.languageCode;
    final goalsCtrl = context.watch<GoalsController>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.goalContributeTitle)),
      body: AppPage(
        form: true,
        padding: AppInsets.page,
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (goalsCtrl.familyId != null)
                StreamBuilder<Goal?>(
                  stream: goalsCtrl.watchGoal(widget.goalId),
                  builder: (context, snap) {
                    final goal = snap.data;
                    if (goal == null) {
                      return Text(l10n.ledgerNotFound);
                    }
                    return Text(
                      l10n.goalProgressLabel(
                        Money.formatFromMinor(
                          goal.accumulatedAmountMinor,
                          locale,
                        ),
                        Money.formatFromMinor(goal.targetAmountMinor, locale),
                      ),
                      style: theme.textTheme.titleMedium,
                    );
                  },
                ),
              const SizedBox(height: AppSpacing.md),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(
                    value: true,
                    label: Text(l10n.goalDeposit),
                    icon: const Icon(Icons.add),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text(l10n.goalWithdraw),
                    icon: const Icon(Icons.remove),
                  ),
                ],
                selected: {_isDeposit},
                onSelectionChanged: (s) => setState(() => _isDeposit = s.first),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _amount,
                decoration: InputDecoration(labelText: l10n.transactionAmount),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return l10n.moneyInvalid;
                  try {
                    final n = Money.parseToMinor(v, locale);
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
                  final picked = await pickBookingDate(
                    context,
                    initial: _bookingDate,
                  );
                  if (picked == null) return;
                  setState(() => _bookingDate = picked);
                },
              ),
              Text(l10n.goalContributeHint, style: theme.textTheme.bodySmall),
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
            ],
          ),
        ),
      ),
    );
  }
}
