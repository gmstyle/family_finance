import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/locale/locale_controller.dart';
import '../../../core/money/money.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/ui/kinship_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/ledger_async_body.dart';
import '../../accounts/domain/account.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../categories/domain/category.dart';
import '../../categories/presentation/categories_controller.dart';
import '../../ledger/ledger_labels.dart';
import '../domain/ingestion.dart';
import '../domain/receipt_ocr_service.dart';
import 'ingestion_controller.dart';
import 'ingestion_detail_screen.dart';

enum _IngestionFilter { all, notification, ocr, duplicates }

/// Inbox of pending Ingestion drafts — Stitch mobile card stack / web 5+7.
class IngestionInboxScreen extends StatefulWidget {
  const IngestionInboxScreen({super.key});

  @override
  State<IngestionInboxScreen> createState() => _IngestionInboxScreenState();
}

class _IngestionInboxScreenState extends State<IngestionInboxScreen> {
  String? _boundFamilyId;
  _IngestionFilter _filter = _IngestionFilter.all;
  String? _selectedId;

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
      });
    }
  }

  List<IngestionDraft> _applyFilter(List<IngestionDraft> pending) {
    return switch (_filter) {
      _IngestionFilter.all => pending,
      _IngestionFilter.notification =>
        pending.where((d) => d.source == IngestionSource.notification).toList(),
      _IngestionFilter.ocr =>
        pending.where((d) => d.source == IngestionSource.receiptOcr).toList(),
      _IngestionFilter.duplicates =>
        pending
            .where((d) => d.status == IngestionStatus.possibleDuplicate)
            .toList(),
    };
  }

  void _ensureSelection(List<IngestionDraft> filtered, {required bool wide}) {
    if (!wide) return;
    if (filtered.isEmpty) {
      if (_selectedId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _selectedId = null);
        });
      }
      return;
    }
    final stillValid = filtered.any((d) => d.id == _selectedId);
    if (!stillValid) {
      final next = filtered.first.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedId = next);
      });
    }
  }

  Future<void> _discardDraft(IngestionDraft draft) async {
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
    try {
      await context.read<IngestionController>().discardDraft(draft.id);
      if (_selectedId == draft.id && mounted) {
        setState(() => _selectedId = null);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _openReview(IngestionDraft draft, {required bool wide}) {
    if (wide) {
      setState(() => _selectedId = draft.id);
    } else {
      context.push(AppRoutes.ingestionDetailPath(draft.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final familyId = context.select((AuthController c) => c.familyId);
    final locale = context.watch<LocaleController>().locale.languageCode;
    final ocr = context.read<ReceiptOcrService>();
    final ctrl = context.watch<IngestionController>();
    final categoriesCtrl = context.watch<CategoriesController>();
    final wide = AppBreakpoints.isWide(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (familyId == null) {
      return Center(child: Text(l10n.familyMissing));
    }

    final pending = ctrl.pending;
    final filtered = _applyFilter(pending);
    _ensureSelection(filtered, wide: wide);

    final notifCount = pending
        .where((d) => d.source == IngestionSource.notification)
        .length;
    final ocrCount = pending
        .where((d) => d.source == IngestionSource.receiptOcr)
        .length;
    final dupCount = pending
        .where((d) => d.status == IngestionStatus.possibleDuplicate)
        .length;

    Account? accountFor(String? id) {
      if (id == null) return null;
      for (final a in ctrl.accounts) {
        if (a.id == id) return a;
      }
      return null;
    }

    Category? categoryFor(String? id) {
      if (id == null) return null;
      for (final c in categoriesCtrl.items) {
        if (c.id == id) return c;
      }
      return null;
    }

    return ColoredBox(
      color: scheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              wide ? AppSpacing.xl : AppSpacing.margin,
              wide ? AppSpacing.lg : AppSpacing.sm,
              wide ? AppSpacing.xl : AppSpacing.margin,
              AppSpacing.xs,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (wide) ...[
                  Text(
                    l10n.ingestionWebEyebrow.toUpperCase(),
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                ],
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.ingestionTitle,
                        style:
                            (wide
                                    ? textTheme.headlineLarge
                                    : textTheme.headlineMedium)
                                ?.copyWith(
                                  color: wide
                                      ? scheme.onSurface
                                      : scheme.primary,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                ),
                      ),
                    ),
                    if (!wide && pending.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: AppPalette.tertiaryFixed,
                          borderRadius: AppRadius.fullAll,
                        ),
                        child: Text(
                          l10n.ingestionPendingCount(pending.length),
                          style: textTheme.labelMedium?.copyWith(
                            color: AppPalette.onTertiaryFixed,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    if (wide)
                      KinshipSecondaryPillButton(
                        onPressed: () =>
                            context.push(AppRoutes.accountBindings),
                        icon: Icon(Icons.tune, size: 18, color: scheme.primary),
                        child: Text(l10n.ingestionSettingsCapture),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (!ocr.isCaptureSupported)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: wide ? AppSpacing.xl : AppSpacing.margin,
                vertical: AppSpacing.xs,
              ),
              child: Material(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
                borderRadius: AppRadius.mdAll,
                child: Padding(
                  padding: AppInsets.card,
                  child: Row(
                    children: [
                      Icon(Icons.phone_android_outlined, color: scheme.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          l10n.receiptScanAndroidOnlyBanner,
                          style: textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.only(
              left: wide ? AppSpacing.xl : AppSpacing.margin,
              right: wide ? AppSpacing.xl : AppSpacing.margin,
              bottom: AppSpacing.sm,
              top: AppSpacing.xs,
            ),
            child: KinshipFilterChips(
              children: [
                KinshipFilterChip(
                  label: l10n.ingestionFilterAll(pending.length),
                  selected: _filter == _IngestionFilter.all,
                  onSelected: (_) =>
                      setState(() => _filter = _IngestionFilter.all),
                ),
                KinshipFilterChip(
                  label: l10n.ingestionFilterNotification(notifCount),
                  selected: _filter == _IngestionFilter.notification,
                  leading: Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 14,
                    color: scheme.tertiary,
                  ),
                  onSelected: (_) =>
                      setState(() => _filter = _IngestionFilter.notification),
                ),
                KinshipFilterChip(
                  label: l10n.ingestionFilterOcr(ocrCount),
                  selected: _filter == _IngestionFilter.ocr,
                  leading: Icon(
                    Icons.receipt_long,
                    size: 14,
                    color: scheme.primary,
                  ),
                  onSelected: (_) =>
                      setState(() => _filter = _IngestionFilter.ocr),
                ),
                if (wide)
                  KinshipFilterChip(
                    label: l10n.ingestionFilterDuplicates(dupCount),
                    selected: _filter == _IngestionFilter.duplicates,
                    showCheckWhenSelected: false,
                    leading: Icon(
                      Icons.warning_amber_rounded,
                      size: 14,
                      color: scheme.secondary,
                    ),
                    onSelected: (_) =>
                        setState(() => _filter = _IngestionFilter.duplicates),
                  ),
              ],
            ),
          ),
          Expanded(
            child: LedgerAsyncBody(
              isLoading: ctrl.loading,
              errorMessage: ctrl.errorMessage,
              isEmpty: false,
              emptyMessage: l10n.ingestionEmpty,
              child: wide
                  ? _WideMasterDetail(
                      filtered: filtered,
                      pendingEmpty: pending.isEmpty,
                      selectedId: _selectedId,
                      currency: ctrl.currency,
                      locale: locale,
                      onSelect: (d) => _openReview(d, wide: true),
                      onDetailCompleted: () =>
                          setState(() => _selectedId = null),
                    )
                  : _MobileCardStack(
                      filtered: filtered,
                      pendingEmpty: pending.isEmpty,
                      currency: ctrl.currency,
                      locale: locale,
                      accountFor: accountFor,
                      categoryFor: categoryFor,
                      onReview: (d) => _openReview(d, wide: false),
                      onDiscard: _discardDraft,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileCardStack extends StatelessWidget {
  const _MobileCardStack({
    required this.filtered,
    required this.pendingEmpty,
    required this.currency,
    required this.locale,
    required this.accountFor,
    required this.categoryFor,
    required this.onReview,
    required this.onDiscard,
  });

  final List<IngestionDraft> filtered;
  final bool pendingEmpty;
  final String currency;
  final String locale;
  final Account? Function(String?) accountFor;
  final Category? Function(String?) categoryFor;
  final ValueChanged<IngestionDraft> onReview;
  final ValueChanged<IngestionDraft> onDiscard;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (pendingEmpty || filtered.isEmpty) {
      return _EmptyDoneState(
        message: pendingEmpty ? null : l10n.ingestionEmpty,
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.margin,
        0,
        AppSpacing.margin,
        AppSpacing.xxl,
      ),
      children: [
        for (final draft in filtered) ...[
          _DraftReviewCard(
            draft: draft,
            currency: currency,
            locale: locale,
            account: accountFor(draft.accountId),
            category: categoryFor(draft.categoryId),
            onConfirm: () => onReview(draft),
            onDiscard: () => onDiscard(draft),
            onTap: () => onReview(draft),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: TextButton.icon(
            onPressed: () => context.push(AppRoutes.accountBindings),
            icon: const Icon(Icons.tune, size: 18),
            label: Text(l10n.ingestionSettingsCapture),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              shape: const StadiumBorder(),
            ),
          ),
        ),
      ],
    );
  }
}

class _WideMasterDetail extends StatelessWidget {
  const _WideMasterDetail({
    required this.filtered,
    required this.pendingEmpty,
    required this.selectedId,
    required this.currency,
    required this.locale,
    required this.onSelect,
    required this.onDetailCompleted,
  });

  final List<IngestionDraft> filtered;
  final bool pendingEmpty;
  final String? selectedId;
  final String currency;
  final String locale;
  final ValueChanged<IngestionDraft> onSelect;
  final VoidCallback onDetailCompleted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (pendingEmpty) {
      return const _EmptyDoneState();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.lg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KinshipSectionHeader(
                  title: l10n.ingestionUnreconciledTitle,
                  action: Text(
                    l10n.ingestionSortedByDate,
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            l10n.ingestionEmpty,
                            style: textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            final draft = filtered[index];
                            return _MasterListTile(
                              draft: draft,
                              currency: currency,
                              locale: locale,
                              selected: draft.id == selectedId,
                              onTap: () => onSelect(draft),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            flex: 7,
            child: selectedId == null
                ? KinshipCard(
                    elevated: true,
                    borderRadius: AppRadius.xxlAll,
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Center(
                      child: Text(
                        l10n.ingestionSelectDraftHint,
                        style: textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : IngestionDetailScreen(
                    key: ValueKey(selectedId),
                    dedupKey: selectedId!,
                    embedded: true,
                    onCompleted: onDetailCompleted,
                  ),
          ),
        ],
      ),
    );
  }
}

class _MasterListTile extends StatelessWidget {
  const _MasterListTile({
    required this.draft,
    required this.currency,
    required this.locale,
    required this.selected,
    required this.onTap,
  });

  final IngestionDraft draft;
  final String currency;
  final String locale;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDup = draft.status == IngestionStatus.possibleDuplicate;
    final isNotif = draft.source == IngestionSource.notification;

    final amount = draft.amountMinor == null
        ? '—'
        : '-${Money.formatFromMinor(draft.amountMinor!, locale)} $currency';

    final sourceLabel = isDup
        ? l10n.ingestionStatusPossibleDuplicate
        : isNotif
        ? l10n.ingestionSourceNotification
        : l10n.ingestionSourceReceiptOcr;

    final statusLabel = isDup
        ? l10n.ingestionStatusPossibleDuplicate
        : selected
        ? l10n.ingestionInReview
        : l10n.ingestionToConfirm;

    final iconBg = isDup
        ? AppPalette.secondaryFixed
        : isNotif
        ? AppPalette.primaryFixed
        : AppPalette.tertiaryFixed;
    final iconFg = isDup
        ? scheme.secondary
        : isNotif
        ? AppPalette.onPrimaryFixedVariant
        : scheme.tertiary;
    final icon = isDup
        ? Icons.content_copy_outlined
        : isNotif
        ? Icons.contactless_outlined
        : Icons.receipt_outlined;

    return KinshipCard(
      elevated: selected,
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.sm),
      borderRadius: AppRadius.lgAll,
      child: DecoratedBox(
        decoration: selected
            ? BoxDecoration(
                border: Border(
                  left: BorderSide(color: scheme.primaryContainer, width: 4),
                ),
              )
            : const BoxDecoration(),
        child: Padding(
          padding: EdgeInsets.only(left: selected ? AppSpacing.xs : 0),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: AppRadius.mdAll,
                ),
                child: Icon(icon, size: 20, color: iconFg),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      draft.merchant?.isNotEmpty == true
                          ? draft.merchant!
                          : l10n.ingestionUnknownMerchant,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text.rich(
                      TextSpan(
                        style: textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        children: [
                          TextSpan(
                            text: sourceLabel,
                            style: TextStyle(
                              color: isDup
                                  ? scheme.secondary
                                  : isNotif
                                  ? scheme.primary
                                  : scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (draft.bookingDate != null &&
                              draft.bookingDate!.isNotEmpty) ...[
                            const TextSpan(text: ' · '),
                            TextSpan(text: draft.bookingDate!),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amount,
                    style: AppTextStyles.tabularAmountMd(context)
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  if (isDup)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppPalette.secondaryFixed,
                        borderRadius: AppRadius.fullAll,
                      ),
                      child: Text(
                        statusLabel,
                        style: textTheme.labelSmall?.copyWith(
                          color: AppPalette.onSecondaryFixedVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    Text(
                      statusLabel,
                      style: textTheme.labelSmall?.copyWith(
                        color: selected
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DraftReviewCard extends StatelessWidget {
  const _DraftReviewCard({
    required this.draft,
    required this.currency,
    required this.locale,
    required this.account,
    required this.category,
    required this.onConfirm,
    required this.onDiscard,
    required this.onTap,
  });

  final IngestionDraft draft;
  final String currency;
  final String locale;
  final Account? account;
  final Category? category;
  final VoidCallback onConfirm;
  final VoidCallback onDiscard;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDup = draft.status == IngestionStatus.possibleDuplicate;
    final isNotif = draft.source == IngestionSource.notification;

    final amount = draft.amountMinor == null
        ? '—'
        : '- ${Money.formatFromMinor(draft.amountMinor!, locale)} $currency';

    final sourceChipBg = isDup
        ? AppPalette.secondaryFixed
        : isNotif
        ? AppPalette.tertiaryFixed
        : AppPalette.primaryFixed;
    final sourceChipFg = isDup
        ? AppPalette.onSecondaryFixedVariant
        : isNotif
        ? AppPalette.onTertiaryFixed
        : AppPalette.onPrimaryFixed;
    final sourceLabel = isDup
        ? l10n.ingestionStatusPossibleDuplicate
        : isNotif
        ? l10n.ingestionSourceNotification
        : l10n.ingestionSourceReceiptOcr;
    final sourceIcon = isDup
        ? Icons.warning_amber_rounded
        : isNotif
        ? Icons.account_balance_wallet
        : Icons.document_scanner_outlined;

    return KinshipCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: sourceChipBg,
                  borderRadius: AppRadius.fullAll,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(sourceIcon, size: 15, color: sourceChipFg),
                    const SizedBox(width: AppSpacing.xxs),
                    Text(
                      sourceLabel,
                      style: textTheme.labelSmall?.copyWith(
                        color: sourceChipFg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (draft.bookingDate != null && draft.bookingDate!.isNotEmpty)
                Text(
                  draft.bookingDate!,
                  style: textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                )
              else if (!isDup)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    borderRadius: AppRadius.fullAll,
                  ),
                  child: Text(
                    l10n.ingestionStatusNeedsReview,
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDup
                      ? AppPalette.secondaryFixed.withValues(alpha: 0.5)
                      : scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isDup
                      ? Icons.bakery_dining_outlined
                      : isNotif
                      ? Icons.shopping_cart_outlined
                      : Icons.storefront_outlined,
                  size: 26,
                  color: isDup ? scheme.secondary : scheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      draft.merchant?.isNotEmpty == true
                          ? draft.merchant!
                          : l10n.ingestionUnknownMerchant,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isNotif
                          ? l10n.ingestionSourceNotification
                          : l10n.ingestionSourceReceiptOcr,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                amount,
                style: AppTextStyles.tabularAmountMd(context)
                    ?.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          if (isDup) ...[
            const SizedBox(height: AppSpacing.sm),
            Material(
              color: scheme.errorContainer.withValues(alpha: 0.4),
              borderRadius: AppRadius.mdAll,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 18,
                      color: scheme.secondary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        l10n.ingestionPossibleDuplicateHint,
                        style: textTheme.labelSmall?.copyWith(
                          color: scheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (account != null || category != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: AppRadius.mdAll,
              ),
              child: Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  if (account != null)
                    _MetaPill(icon: Icons.credit_card, label: account!.name),
                  if (category != null)
                    _MetaPill(
                      icon: Icons.storefront,
                      label: categoryLabel(l10n, category!),
                      emphasize: true,
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              FilledButton(
                onPressed: onDiscard,
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.surfaceContainer,
                  foregroundColor: scheme.onSurface,
                  minimumSize: const Size(0, AppSizes.minTapTarget),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  shape: const StadiumBorder(),
                ),
                child: Text(l10n.ingestionDiscardAction),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: isDup
                    ? KinshipDestructivePillButton(
                        onPressed: onConfirm,
                        icon: const Icon(Icons.merge_type, size: 18),
                        child: Text(l10n.ingestionConfirmLedger),
                      )
                    : KinshipPrimaryPillButton(
                        onPressed: onConfirm,
                        icon: const Icon(Icons.check_circle, size: 18),
                        child: Text(l10n.ingestionConfirmLedger),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    this.emphasize = false,
  });

  final IconData icon;
  final String label;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: emphasize ? null : scheme.surfaceContainer,
        borderRadius: AppRadius.fullAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: emphasize ? scheme.primary : scheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDoneState extends StatelessWidget {
  const _EmptyDoneState({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: AppInsets.page,
        child: KinshipCard(
          color: scheme.surfaceContainerLow,
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppPalette.primaryFixed,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.task_alt,
                  size: 36,
                  color: AppPalette.onPrimaryFixed,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.ingestionEmptyDoneTitle,
                style: textTheme.headlineSmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                message ?? l10n.ingestionEmptyDoneBody,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              KinshipPrimaryPillButton(
                onPressed: () => context.go(AppRoutes.home),
                icon: const Icon(Icons.arrow_forward, size: 18),
                child: Text(l10n.ingestionEmptyGoDashboard),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
