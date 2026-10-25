import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/locale/locale_controller.dart';
import '../../../core/money/money.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/ui/app_page.dart';
import '../../../core/ui/kinship_budget_meter.dart';
import '../../../core/ui/kinship_card.dart';
import '../../../core/ui/kinship_section_header.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/ledger_async_body.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../categories/domain/category.dart';
import '../../goals/domain/goal.dart';
import '../../goals/presentation/goals_controller.dart';
import '../../ledger/ledger_labels.dart';
import '../domain/budget.dart';
import 'budgets_controller.dart';

/// Unified Budget & Goals shell destination (Stitch segmented tabs).
///
/// KinshipScaffold wraps this — no nested bottom nav / app bar.
class BudgetGoalsScreen extends StatefulWidget {
  const BudgetGoalsScreen({super.key, this.initialShowGoals = false});

  final bool initialShowGoals;

  @override
  State<BudgetGoalsScreen> createState() => _BudgetGoalsScreenState();
}

class _BudgetGoalsScreenState extends State<BudgetGoalsScreen> {
  late int _tabIndex;
  String? _boundFamilyId;

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialShowGoals ? 1 : 0;
  }

  @override
  void didUpdateWidget(covariant BudgetGoalsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialShowGoals != widget.initialShowGoals) {
      _tabIndex = widget.initialShowGoals ? 1 : 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final familyId = context.watch<AuthController>().familyId;
    if (familyId != _boundFamilyId) {
      _boundFamilyId = familyId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<BudgetsController>().bindFamily(familyId);
        context.read<GoalsController>().bindFamily(familyId);
      });
    }
  }

  void _selectTab(int index) {
    if (_tabIndex == index) return;
    setState(() => _tabIndex = index);
    final loc = index == 1
        ? '${AppRoutes.budgets}?tab=goals'
        : AppRoutes.budgets;
    context.go(loc);
  }

  Future<void> _showCreateSheet() async {
    final l10n = AppLocalizations.of(context)!;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.pie_chart_outline),
                title: Text(l10n.budgetCreateBudgetChoice),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push(AppRoutes.budgetNew);
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: Text(l10n.budgetCreateGoalChoice),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push(AppRoutes.goalNew);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final familyId = context.select((AuthController c) => c.familyId);
    final localeTag = context.watch<LocaleController>().locale.toLanguageTag();
    final localeCode = context.watch<LocaleController>().locale.languageCode;
    final budgets = context.watch<BudgetsController>();
    final goals = context.watch<GoalsController>();
    final wide = AppBreakpoints.isWide(context);

    if (familyId == null) {
      return Center(child: Text(l10n.familyMissing));
    }

    return AppPage(
      padding: EdgeInsets.fromLTRB(
        wide ? AppSpacing.xl : AppSpacing.margin,
        AppSpacing.md,
        wide ? AppSpacing.xl : AppSpacing.margin,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PageHeader(
            wide: wide,
            periodId: budgets.periodId,
            localeTag: localeTag,
            onPrevious: () => budgets.shiftPeriod(-1),
            onNext: () => budgets.shiftPeriod(1),
            onReset: budgets.periodId == currentBudgetPeriodId()
                ? null
                : () => budgets.resetPeriodToCurrent(),
            onCreate: _showCreateSheet,
            onEditLimits: () {
              if (budgets.items.isEmpty) {
                context.push(AppRoutes.budgetNew);
              } else {
                context.push(
                  AppRoutes.budgetEditPath(budgets.items.first.budget.id),
                );
              }
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _SegmentedTabs(index: _tabIndex, onChanged: _selectTab),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: IndexedStack(
              index: _tabIndex,
              children: [
                _BudgetsTab(
                  ctrl: budgets,
                  locale: localeCode,
                  wide: wide,
                  onCreate: () => context.push(AppRoutes.budgetNew),
                  onEditLimits: () {
                    if (budgets.items.isEmpty) {
                      context.push(AppRoutes.budgetNew);
                    } else {
                      context.push(
                        AppRoutes.budgetEditPath(budgets.items.first.budget.id),
                      );
                    }
                  },
                ),
                _GoalsTab(
                  ctrl: goals,
                  locale: localeCode,
                  onCreate: () => context.push(AppRoutes.goalNew),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: _showCreateSheet,
            icon: const Icon(Icons.add_circle_outline),
            label: Text(l10n.budgetCreateBudgetOrGoal),
          ),
        ],
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.wide,
    required this.periodId,
    required this.localeTag,
    required this.onPrevious,
    required this.onNext,
    required this.onReset,
    required this.onCreate,
    required this.onEditLimits,
  });

  final bool wide;
  final String periodId;
  final String localeTag;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback? onReset;
  final VoidCallback onCreate;
  final VoidCallback onEditLimits;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final periodLabel = _formatPeriodLabel(periodId, localeTag);

    final titles = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          wide ? l10n.budgetGoalsEyebrowWeb : l10n.budgetGoalsEyebrow,
          style: textTheme.labelSmall?.copyWith(
            color: wide ? scheme.primaryContainer : scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          wide ? l10n.budgetGoalsHeadlineWeb : l10n.budgetGoalsHeadline,
          style: (wide ? textTheme.headlineLarge : textTheme.headlineSmall)
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );

    final periodPill = Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: AppRadius.fullAll,
      child: InkWell(
        borderRadius: AppRadius.fullAll,
        onTap: onReset,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: l10n.budgetPeriodPrevious,
                onPressed: onPrevious,
                icon: Icon(Icons.chevron_left, size: 20, color: scheme.primary),
              ),
              Icon(Icons.calendar_month, size: 18, color: scheme.primary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                periodLabel,
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: l10n.budgetPeriodNext,
                onPressed: onNext,
                icon: Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: titles),
          periodPill,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: titles),
        const SizedBox(width: AppSpacing.md),
        periodPill,
        const SizedBox(width: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: onEditLimits,
          icon: const Icon(Icons.tune, size: 18),
          label: Text(l10n.budgetEditLimits),
        ),
        const SizedBox(width: AppSpacing.sm),
        FilledButton.tonalIcon(
          onPressed: onCreate,
          icon: const Icon(Icons.add, size: 20),
          label: Text(l10n.budgetCreateBudgetOrGoal),
        ),
      ],
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Widget tab({
      required int value,
      required String label,
      required IconData icon,
    }) {
      final selected = index == value;
      return Expanded(
        child: Material(
          color: selected ? scheme.surfaceContainerLowest : Colors.transparent,
          borderRadius: AppRadius.fullAll,
          elevation: selected ? 1 : 0,
          shadowColor: AppPalette.primaryContainer.withValues(alpha: 0.12),
          child: InkWell(
            borderRadius: AppRadius.fullAll,
            onTap: () => onChanged(value),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm,
                horizontal: AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: selected ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelMedium?.copyWith(
                        color: selected
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: AppRadius.fullAll,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxs),
        child: Row(
          children: [
            tab(
              value: 0,
              label: l10n.budgetGoalsTabBudgets,
              icon: Icons.pie_chart_outline,
            ),
            tab(
              value: 1,
              label: l10n.budgetGoalsTabGoals,
              icon: Icons.flag_outlined,
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetsTab extends StatelessWidget {
  const _BudgetsTab({
    required this.ctrl,
    required this.locale,
    required this.wide,
    required this.onCreate,
    required this.onEditLimits,
  });

  final BudgetsController ctrl;
  final String locale;
  final bool wide;
  final VoidCallback onCreate;
  final VoidCallback onEditLimits;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return LedgerAsyncBody(
      isLoading: ctrl.loading,
      errorMessage: ctrl.errorMessage,
      isEmpty: false,
      emptyMessage: '',
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _CapacityHero(
              items: ctrl.items,
              currency: ctrl.currency,
              locale: locale,
              periodId: ctrl.periodId,
              wide: wide,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
          SliverToBoxAdapter(
            child: KinshipSectionHeader(
              title: wide
                  ? l10n.budgetCategoriesSectionWeb
                  : l10n.budgetCategoriesSection,
              actionLabel: l10n.budgetEditLimits,
              onAction: onEditLimits,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
          if (ctrl.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Text(
                  l10n.budgetsEmpty,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            )
          else if (wide)
            SliverToBoxAdapter(
              child: _BudgetCategoryGrid(
                items: ctrl.items,
                categoriesById: ctrl.categoriesById,
                currency: ctrl.currency,
                locale: locale,
                onCreate: onCreate,
                onTap: (id) => context.push(AppRoutes.budgetEditPath(id)),
                onDelete: ctrl.deleteBudget,
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final item = ctrl.items[index];
                final cat = ctrl.categoriesById[item.budget.categoryId];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _BudgetCategoryCard(
                    item: item,
                    categoryLabel: cat == null
                        ? item.budget.categoryId
                        : categoryLabel(l10n, cat),
                    category: cat,
                    currency: ctrl.currency,
                    locale: locale,
                    accentIndex: index,
                    onTap: () =>
                        context.push(AppRoutes.budgetEditPath(item.budget.id)),
                    onDelete: () => ctrl.deleteBudget(item.budget.id),
                  ),
                );
              }, childCount: ctrl.items.length),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
        ],
      ),
    );
  }
}

class _GoalsTab extends StatelessWidget {
  const _GoalsTab({
    required this.ctrl,
    required this.locale,
    required this.onCreate,
  });

  final GoalsController ctrl;
  final String locale;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return LedgerAsyncBody(
      isLoading: ctrl.loading,
      errorMessage: ctrl.errorMessage,
      isEmpty: false,
      emptyMessage: '',
      child: ListView(
        children: [
          KinshipCard(
            color: scheme.primaryFixed.withValues(alpha: 0.3),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(Icons.savings_outlined, color: scheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.goalsSavingBanner,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: scheme.onPrimaryFixedVariant),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (ctrl.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Text(
                l10n.goalsEmpty,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            )
          else
            for (final goal in ctrl.items) ...[
              _GoalCard(
                goal: goal,
                currency: ctrl.currency,
                locale: locale,
                onTap: () => context.push(AppRoutes.goalEditPath(goal.id)),
                onContribute: () =>
                    context.push(AppRoutes.goalContributePath(goal.id)),
                onDelete: () => ctrl.deleteGoal(goal.id),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          _NextGoalPrompt(onExplore: onCreate),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _CapacityHero extends StatelessWidget {
  const _CapacityHero({
    required this.items,
    required this.currency,
    required this.locale,
    required this.periodId,
    required this.wide,
  });

  final List<BudgetWithPeriod> items;
  final String currency;
  final String locale;
  final String periodId;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final totalSpent = items.fold<int>(
      0,
      (sum, i) => sum + i.period.spentAmountMinor,
    );
    final totalLimit = items.fold<int>(
      0,
      (sum, i) => sum + i.budget.limitAmountMinor,
    );
    final remaining = totalLimit - totalSpent;
    final progress = totalLimit <= 0 ? 0.0 : totalSpent / totalLimit;
    final percent = (progress * 100).round().clamp(0, 999);
    final daysLeft = _daysRemainingInPeriod(periodId);
    final nearLimit = items.where((i) {
      final state = i.period.thresholdState(i.budget.limitAmountMinor);
      return state != BudgetThresholdState.ok;
    }).length;

    final spentText = '${Money.formatFromMinor(totalSpent, locale)} $currency';
    final limitText = '${Money.formatFromMinor(totalLimit, locale)} $currency';
    final remainingText =
        '${Money.formatFromMinor(remaining.clamp(0, 1 << 62), locale)} $currency';
    final daily = daysLeft > 0 && remaining > 0
        ? (remaining / daysLeft).round()
        : 0;
    final dailyText =
        '${Money.formatFromMinor(daily.clamp(0, 1 << 62), locale)} $currency';

    final headerRow = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.budgetTotalHouseholdSpend,
                style: textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: spentText,
                      style: AppTextStyles.tabularAmountLg(context)
                          ?.copyWith(color: scheme.onSurface),
                    ),
                    TextSpan(
                      text: ' / $limitText',
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xxs,
          ),
          decoration: BoxDecoration(
            color: scheme.primaryFixed,
            borderRadius: AppRadius.fullAll,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                l10n.budgetPercentUsed(percent),
                style: textTheme.labelSmall?.copyWith(
                  color: scheme.onPrimaryFixed,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final meter = KinshipBudgetMeter(progress: progress, height: 10);
    final footer = Row(
      children: [
        Expanded(
          child: Text(
            l10n.budgetAvailableLabel(remainingText),
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          l10n.budgetDaysRemaining(daysLeft),
          style: textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );

    final capacityColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: scheme.primaryFixed,
                borderRadius: AppRadius.fullAll,
              ),
              child: Text(
                l10n.budgetPercentUsed(percent),
                style: textTheme.labelSmall?.copyWith(
                  color: scheme.onPrimaryFixed,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            Text(
              l10n.budgetDaysRemaining(daysLeft),
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (nearLimit > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: scheme.errorContainer.withValues(alpha: 0.4),
                  borderRadius: AppRadius.fullAll,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notification_important_outlined,
                      size: 16,
                      color: scheme.secondary,
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                    Text(
                      l10n.budgetNearLimitCount(nearLimit),
                      style: textTheme.labelSmall?.copyWith(
                        color: scheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: spentText,
                style: AppTextStyles.tabularAmountLg(context),
              ),
              TextSpan(
                text: ' ${l10n.budgetOfLimitSuffix(limitText)}',
                style: textTheme.titleMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        meter,
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Text(
              l10n.budgetPercentUtilized(percent),
              style: textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Text(
              l10n.budgetMarginRemaining(
                remainingText,
                (100 - percent).clamp(0, 100),
              ),
              style: textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );

    if (!wide) {
      return KinshipCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        elevated: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            headerRow,
            const SizedBox(height: AppSpacing.md),
            meter,
            const SizedBox(height: AppSpacing.sm),
            footer,
          ],
        ),
      );
    }

    return KinshipCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      elevated: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: 7, child: capacityColumn),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Expanded(
                  child: _HeroStatTile(
                    label: l10n.budgetResidueMonth,
                    value: remainingText,
                    caption: l10n.budgetResidueAvailable,
                    icon: Icons.savings_outlined,
                    iconBg: scheme.primaryFixed,
                    iconColor: scheme.primary,
                    valueColor: scheme.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _HeroStatTile(
                    label: l10n.budgetDailyAllowance,
                    value: l10n.budgetDailyPerDay(dailyText),
                    caption: l10n.budgetDailyTarget,
                    icon: Icons.speed_outlined,
                    iconBg: scheme.tertiaryFixed,
                    iconColor: scheme.tertiary,
                    valueColor: scheme.tertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStatTile extends StatelessWidget {
  const _HeroStatTile({
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.valueColor,
  });

  final String label;
  final String value;
  final String caption;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: AppRadius.mdAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTextStyles.tabularAmountMd(context)
                ?.copyWith(color: valueColor, fontWeight: FontWeight.w700),
          ),
          Text(
            caption,
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetCategoryGrid extends StatelessWidget {
  const _BudgetCategoryGrid({
    required this.items,
    required this.categoriesById,
    required this.currency,
    required this.locale,
    required this.onCreate,
    required this.onTap,
    required this.onDelete,
  });

  final List<BudgetWithPeriod> items;
  final Map<String, Category> categoriesById;
  final String currency;
  final String locale;
  final VoidCallback onCreate;
  final ValueChanged<String> onTap;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 560
            ? 2
            : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length + 1,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: AppSpacing.lg,
            crossAxisSpacing: AppSpacing.lg,
            mainAxisExtent: 220,
          ),
          itemBuilder: (context, index) {
            if (index == items.length) {
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: AppRadius.mdAll,
                  onTap: onCreate,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.mdAll,
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHigh,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          l10n.budgetNewCategoryTitle,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          l10n.budgetNewCategoryBody,
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${l10n.budgetCreateNow} →',
                          style: textTheme.labelMedium?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final item = items[index];
            final cat = categoriesById[item.budget.categoryId];
            return _BudgetCategoryCard(
              item: item,
              categoryLabel: cat == null
                  ? item.budget.categoryId
                  : categoryLabel(l10n, cat),
              category: cat,
              currency: currency,
              locale: locale,
              accentIndex: index,
              dense: false,
              onTap: () => onTap(item.budget.id),
              onDelete: () => onDelete(item.budget.id),
            );
          },
        );
      },
    );
  }
}

class _BudgetCategoryCard extends StatelessWidget {
  const _BudgetCategoryCard({
    required this.item,
    required this.categoryLabel,
    required this.category,
    required this.currency,
    required this.locale,
    required this.accentIndex,
    required this.onTap,
    required this.onDelete,
    this.dense = true,
  });

  final BudgetWithPeriod item;
  final String categoryLabel;
  final Category? category;
  final String currency;
  final String locale;
  final int accentIndex;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final extras = AppExtraColors.of(context);

    final limit = item.budget.limitAmountMinor;
    final spent = item.period.spentAmountMinor;
    final remaining = limit - spent;
    final progress = limit <= 0 ? 0.0 : spent / limit;
    final percent = (progress * 100).round().clamp(0, 999);
    final state = item.period.thresholdState(limit);
    final accent = _accentFor(accentIndex, scheme);
    final remainingColor = switch (state) {
      BudgetThresholdState.atOrOver100 => extras.expense,
      BudgetThresholdState.atOrOver80 => scheme.secondary,
      BudgetThresholdState.ok => scheme.onSurface,
    };

    final spentText = '${Money.formatFromMinor(spent, locale)} $currency';
    final limitText = '${Money.formatFromMinor(limit, locale)} $currency';
    final remainingText =
        '${Money.formatFromMinor(remaining.clamp(0, 1 << 62), locale)} $currency';

    return KinshipCard(
      onTap: onTap,
      padding: EdgeInsets.all(dense ? AppSpacing.md : AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: dense ? 40 : 48,
                height: dense ? 40 : 48,
                decoration: BoxDecoration(
                  color: accent.$1,
                  borderRadius: AppRadius.mdAll,
                ),
                child: Icon(
                  _iconForCategory(category),
                  color: accent.$2,
                  size: dense ? 20 : 24,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  categoryLabel,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (dense)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      spentText,
                      style: AppTextStyles.tabularAmountMd(context),
                    ),
                    Text(
                      l10n.budgetOfLimitSuffix(limitText),
                      style: textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                )
              else
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(l10n.actionDelete),
                    ),
                  ],
                ),
            ],
          ),
          if (!dense) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Text(spentText, style: AppTextStyles.tabularAmountMd(context)),
                Text(
                  ' / $limitText',
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  l10n.budgetRemainingLabel(remainingText),
                  style: textTheme.labelSmall?.copyWith(
                    color: remainingColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          KinshipBudgetMeter(progress: progress, height: 8),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text(
                l10n.budgetSpentPercent(percent),
                style: textTheme.labelSmall?.copyWith(
                  color: state == BudgetThresholdState.ok
                      ? scheme.onSurfaceVariant
                      : remainingColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (dense)
                Text(
                  l10n.budgetRemainingLabel(remainingText),
                  style: textTheme.labelSmall?.copyWith(
                    color: remainingColor,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
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
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final percent = (goal.progress * 100).round();
    final accumulated =
        '${Money.formatFromMinor(goal.accumulatedAmountMinor, locale)} $currency';
    final target =
        '${Money.formatFromMinor(goal.targetAmountMinor, locale)} $currency';

    return KinshipCard(
      onTap: onTap,
      elevated: true,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.primaryFixed.withValues(alpha: 0.5),
                  borderRadius: AppRadius.lgAll,
                ),
                child: Icon(Icons.flag_outlined, color: scheme.primary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (goal.dueDate != null && goal.dueDate!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xxs),
                        child: Row(
                          children: [
                            Icon(
                              Icons.event,
                              size: 14,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: AppSpacing.xxs),
                            Text(
                              l10n.goalDueDateLabel(goal.dueDate!),
                              style: textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
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
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(accumulated, style: AppTextStyles.tabularAmountLg(context)),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                '/ $target',
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                l10n.goalProgressPercent(percent),
                style: textTheme.labelLarge?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          KinshipBudgetMeter(progress: goal.progress),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onContribute,
              child: Text(l10n.goalAddFunds),
            ),
          ),
        ],
      ),
    );
  }
}

class _NextGoalPrompt extends StatelessWidget {
  const _NextGoalPrompt({required this.onExplore});

  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.4),
        borderRadius: AppRadius.mdAll,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.add_task, color: scheme.primary, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.goalsNextPromptTitle,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  l10n.goalsNextPromptBody,
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.tonal(
            onPressed: onExplore,
            child: Text(l10n.goalsExplore),
          ),
        ],
      ),
    );
  }
}

(Color, Color) _accentFor(int index, ColorScheme scheme) {
  final accents = <(Color, Color)>[
    (scheme.primaryFixed.withValues(alpha: 0.4), scheme.primary),
    (scheme.secondaryFixed.withValues(alpha: 0.5), scheme.secondary),
    (scheme.tertiaryFixed.withValues(alpha: 0.6), scheme.tertiary),
    (scheme.primaryFixed, scheme.primary),
  ];
  return accents[index % accents.length];
}

IconData _iconForCategory(Category? category) {
  return switch (category?.nameKey) {
    'categoryFood' => Icons.shopping_cart_outlined,
    'categoryHousing' => Icons.roofing_outlined,
    'categoryUtilities' => Icons.bolt_outlined,
    'categoryEntertainment' => Icons.local_cafe_outlined,
    'categoryEducation' => Icons.backpack_outlined,
    'categoryTransport' => Icons.directions_car_outlined,
    'categoryHealth' => Icons.medical_services_outlined,
    'categoryShopping' => Icons.shopping_bag_outlined,
    'categoryOtherExpense' => Icons.category_outlined,
    _ => Icons.pie_chart_outline,
  };
}

String _formatPeriodLabel(String periodId, String localeTag) {
  final parts = periodId.split('-');
  if (parts.length < 2) return periodId;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  if (year == null || month == null) return periodId;
  final date = DateTime(year, month, 1);
  return DateFormat.yMMMM(localeTag).format(date);
}

int _daysRemainingInPeriod(String periodId) {
  final parts = periodId.split('-');
  if (parts.length < 2) return 0;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  if (year == null || month == null) return 0;
  final lastDay = DateTime(year, month + 1, 0);
  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);
  if (todayDate.isAfter(lastDay)) return 0;
  if (today.year != year || today.month != month) {
    return lastDay.day;
  }
  return lastDay.difference(todayDate).inDays;
}
