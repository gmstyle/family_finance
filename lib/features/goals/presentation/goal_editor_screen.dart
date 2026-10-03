import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/locale/locale_controller.dart';
import '../../../core/money/money.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/ui/app_page.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../ledger/ledger_labels.dart';
import '../domain/goal.dart';
import 'goals_controller.dart';

class GoalEditorScreen extends StatefulWidget {
  const GoalEditorScreen({super.key, this.goalId});

  final String? goalId;

  @override
  State<GoalEditorScreen> createState() => _GoalEditorScreenState();
}

class _GoalEditorScreenState extends State<GoalEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _target = TextEditingController();
  String? _dueDate;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _boundFamilyId;

  bool get _isEdit => widget.goalId != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final familyId = context.watch<AuthController>().familyId;
    if (familyId != _boundFamilyId) {
      _boundFamilyId = familyId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<GoalsController>().bindFamily(familyId);
        if (_loading) _load();
      });
    }
  }

  Future<void> _load() async {
    final locale = context.read<LocaleController>().locale.languageCode;
    if (widget.goalId == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final goal = await context.read<GoalsController>().getGoal(
        widget.goalId!,
      );
      if (goal == null) {
        setState(() {
          _error = AppLocalizations.of(context)!.ledgerNotFound;
          _loading = false;
        });
        return;
      }
      _name.text = goal.name;
      _target.text = Money.formatFromMinor(goal.targetAmountMinor, locale);
      _dueDate = goal.dueDate;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;
    final locale = context.read<LocaleController>().locale.languageCode;

    late final int targetMinor;
    try {
      targetMinor = Money.parseToMinor(_target.text, locale);
    } catch (_) {
      setState(() => _error = l10n.moneyInvalid);
      return;
    }
    if (targetMinor <= 0) {
      setState(() => _error = l10n.moneyInvalid);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final ctrl = context.read<GoalsController>();
      if (_isEdit) {
        await ctrl.updateGoal(
          goalId: widget.goalId!,
          name: _name.text,
          targetAmountMinor: targetMinor,
          dueDate: _dueDate,
        );
      } else {
        await ctrl.createGoal(
          name: _name.text,
          targetAmountMinor: targetMinor,
          dueDate: _dueDate,
        );
      }
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = context.watch<LocaleController>().locale.languageCode;
    final goalsCtrl = context.watch<GoalsController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? l10n.goalEditTitle : l10n.goalCreateTitle),
        actions: [
          if (_isEdit)
            IconButton(
              tooltip: l10n.goalContributeAction,
              onPressed: () =>
                  context.push(AppRoutes.goalContributePath(widget.goalId!)),
              icon: const Icon(Icons.savings_outlined),
            ),
        ],
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
                    TextFormField(
                      controller: _name,
                      decoration: InputDecoration(labelText: l10n.goalName),
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.trim().length < 2)
                          ? l10n.goalNameInvalid
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _target,
                      decoration: InputDecoration(
                        labelText: l10n.goalTargetAmount,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return l10n.moneyInvalid;
                        }
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
                      title: Text(l10n.goalDueDate),
                      subtitle: Text(
                        _dueDate == null || _dueDate!.isEmpty
                            ? l10n.goalDueDateOptional
                            : _dueDate!,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_dueDate != null && _dueDate!.isNotEmpty)
                            IconButton(
                              onPressed: () => setState(() => _dueDate = null),
                              icon: const Icon(Icons.clear),
                            ),
                          const Icon(Icons.calendar_today_outlined),
                        ],
                      ),
                      onTap: () async {
                        final picked = await pickBookingDate(
                          context,
                          initial: _dueDate,
                        );
                        if (picked == null) return;
                        setState(() => _dueDate = picked);
                      },
                    ),
                    if (_isEdit && goalsCtrl.familyId != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      StreamBuilder<Goal?>(
                        stream: goalsCtrl.watchGoal(widget.goalId!),
                        builder: (context, snap) {
                          final goal = snap.data;
                          if (goal == null) return const SizedBox.shrink();
                          return Text(
                            l10n.goalAccumulatedHint(
                              Money.formatFromMinor(
                                goal.accumulatedAmountMinor,
                                locale,
                              ),
                            ),
                            style: theme.textTheme.bodyMedium,
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppSectionTitle(
                        l10n.goalContributionsTitle,
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      StreamBuilder<List<GoalContribution>>(
                        stream: goalsCtrl.watchContributions(widget.goalId!),
                        builder: (context, snap) {
                          final list = snap.data ?? const <GoalContribution>[];
                          if (list.isEmpty) {
                            return Text(
                              l10n.goalContributionsEmpty,
                              style: theme.textTheme.bodySmall,
                            );
                          }
                          return Column(
                            children: [
                              for (final c in list.take(20))
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  title: Text(
                                    '${c.isDeposit ? '+' : '-'}'
                                    '${Money.formatFromMinor(c.amountMinor.abs(), locale)}',
                                    style: TextStyle(
                                      color: c.isDeposit
                                          ? AppExtraColors.of(context).income
                                          : AppExtraColors.of(context).expense,
                                    ),
                                  ),
                                  subtitle: Text(c.bookingDate),
                                ),
                            ],
                          );
                        },
                      ),
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
