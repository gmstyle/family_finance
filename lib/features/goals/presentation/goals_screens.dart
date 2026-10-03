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
import '../../family/data/family_repository.dart';
import '../../ledger/ledger_labels.dart';
import '../data/goals_repository.dart';

class GoalsListScreen extends StatelessWidget {
  const GoalsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthController>();
    final familyId = auth.familyId;
    final locale = context.watch<LocaleController>().locale.languageCode;
    final repo = context.read<GoalsRepository>();
    final familyRepo = context.read<FamilyController>().repository;

    if (familyId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.goalsTitle)),
        body: Center(child: Text(l10n.familyMissing)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.goalsTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.goalNew),
        child: const Icon(Icons.add),
      ),
      body: AppPage(
        child: StreamBuilder<FamilyInfo?>(
          stream: familyRepo.watchFamily(familyId),
          builder: (context, familySnap) {
            final currency = familySnap.data?.currency ?? 'EUR';
            return StreamBuilder<List<Goal>>(
              stream: repo.watchGoals(familyId),
              builder: (context, snap) {
                final error = snap.hasError ? snap.error.toString() : null;
                final goals = snap.data;

                return LedgerAsyncBody(
                  isLoading:
                      snap.connectionState == ConnectionState.waiting &&
                      goals == null,
                  errorMessage: error,
                  isEmpty: goals != null && goals.isEmpty,
                  emptyMessage: l10n.goalsEmpty,
                  child: ListView(
                    padding: AppInsets.pageCompact,
                    children: [
                      for (final goal in goals ?? const <Goal>[])
                        _GoalTile(
                          goal: goal,
                          currency: currency,
                          locale: locale,
                          onTap: () =>
                              context.push(AppRoutes.goalEditPath(goal.id)),
                          onContribute: () => context.push(
                            AppRoutes.goalContributePath(goal.id),
                          ),
                          onDelete: () => repo.deleteGoal(
                            familyId: familyId,
                            goalId: goal.id,
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({
    required this.goal,
    required this.currency,
    required this.locale,
    required this.onTap,
    required this.onContribute,
    required this.onDelete,
  });

  final Goal goal;
  final String currency;
  final String locale;
  final VoidCallback onTap;
  final VoidCallback onContribute;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final extras = AppExtraColors.of(context);
    final accumulated = Money.formatFromMinor(
      goal.accumulatedAmountMinor,
      locale,
    );
    final target = Money.formatFromMinor(goal.targetAmountMinor, locale);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        borderRadius: AppRadius.mdAll,
        onTap: onTap,
        child: Padding(
          padding: AppInsets.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(goal.name, style: theme.textTheme.titleMedium),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'contribute') onContribute();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'contribute',
                        child: Text(l10n.goalContributeAction),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(l10n.actionDelete),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                l10n.goalProgressLabel(
                  '$accumulated $currency',
                  '$target $currency',
                ),
                style: theme.textTheme.bodyMedium,
              ),
              if (goal.dueDate != null && goal.dueDate!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  l10n.goalDueDateLabel(goal.dueDate!),
                  style: theme.textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: AppSpacing.xs),
              ClipRRect(
                borderRadius: AppRadius.fullAll,
                child: LinearProgressIndicator(
                  value: goal.progress,
                  minHeight: AppSizes.progressBarHeight,
                  color: extras.income,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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

  bool get _isEdit => widget.goalId != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final familyId = context.read<AuthController>().familyId;
    final locale = context.read<LocaleController>().locale.languageCode;
    if (familyId == null || widget.goalId == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final goal = await context.read<GoalsRepository>().getGoal(
        familyId,
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
    final familyId = context.read<AuthController>().familyId;
    if (familyId == null) return;
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
      final repo = context.read<GoalsRepository>();
      if (_isEdit) {
        await repo.updateGoal(
          familyId: familyId,
          goalId: widget.goalId!,
          name: _name.text,
          targetAmountMinor: targetMinor,
          dueDate: _dueDate,
        );
      } else {
        await repo.createGoal(
          familyId: familyId,
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
    final familyId = context.watch<AuthController>().familyId;
    final locale = context.watch<LocaleController>().locale.languageCode;

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
                    if (_isEdit && familyId != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      StreamBuilder<Goal?>(
                        stream: context.read<GoalsRepository>().watchGoal(
                          familyId,
                          widget.goalId!,
                        ),
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
                        stream: context
                            .read<GoalsRepository>()
                            .watchContributions(familyId, widget.goalId!),
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

  @override
  void initState() {
    super.initState();
    _bookingDate = formatBookingDate(DateTime.now());
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;
    final familyId = context.read<AuthController>().familyId;
    if (familyId == null) return;
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
      await context.read<GoalsRepository>().addContribution(
        familyId: familyId,
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
    final familyId = context.watch<AuthController>().familyId;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.goalContributeTitle)),
      body: AppPage(
        form: true,
        padding: AppInsets.page,
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (familyId != null)
                StreamBuilder<Goal?>(
                  stream: context.read<GoalsRepository>().watchGoal(
                    familyId,
                    widget.goalId,
                  ),
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
