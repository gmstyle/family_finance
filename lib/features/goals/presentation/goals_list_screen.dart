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
import '../domain/goal.dart';
import 'goals_controller.dart';

class GoalsListScreen extends StatefulWidget {
  const GoalsListScreen({super.key});

  @override
  State<GoalsListScreen> createState() => _GoalsListScreenState();
}

class _GoalsListScreenState extends State<GoalsListScreen> {
  String? _boundFamilyId;

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final familyId = context.select((AuthController c) => c.familyId);
    final locale = context.watch<LocaleController>().locale.languageCode;
    final ctrl = context.watch<GoalsController>();

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
        child: LedgerAsyncBody(
          isLoading: ctrl.loading,
          errorMessage: ctrl.errorMessage,
          isEmpty: ctrl.isEmpty,
          emptyMessage: l10n.goalsEmpty,
          child: ListView(
            padding: AppInsets.pageCompact,
            children: [
              for (final goal in ctrl.items)
                _GoalTile(
                  goal: goal,
                  currency: ctrl.currency,
                  locale: locale,
                  onTap: () => context.push(AppRoutes.goalEditPath(goal.id)),
                  onContribute: () =>
                      context.push(AppRoutes.goalContributePath(goal.id)),
                  onDelete: () => ctrl.deleteGoal(goal.id),
                ),
            ],
          ),
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
