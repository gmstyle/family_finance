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
import '../domain/ingestion.dart';
import '../domain/receipt_ocr_service.dart';
import 'ingestion_controller.dart';

/// Inbox of pending Ingestion drafts (Android + web).
class IngestionInboxScreen extends StatefulWidget {
  const IngestionInboxScreen({super.key});

  @override
  State<IngestionInboxScreen> createState() => _IngestionInboxScreenState();
}

class _IngestionInboxScreenState extends State<IngestionInboxScreen> {
  String? _boundFamilyId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final familyId = context.watch<AuthController>().familyId;
    if (familyId != _boundFamilyId) {
      _boundFamilyId = familyId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<IngestionController>().bindFamily(familyId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final familyId = context.select((AuthController c) => c.familyId);
    final locale = context.watch<LocaleController>().locale.languageCode;
    final ocr = context.read<ReceiptOcrService>();
    final ctrl = context.watch<IngestionController>();

    if (familyId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.ingestionTitle)),
        body: Center(child: Text(l10n.familyMissing)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.ingestionTitle)),
      floatingActionButton: ocr.isCaptureSupported
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.receiptScan),
              icon: const Icon(Icons.document_scanner_outlined),
              label: Text(l10n.receiptScanAction),
            )
          : null,
      body: AppPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!ocr.isCaptureSupported)
              Padding(
                padding: AppInsets.pageCompact,
                child: Material(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.55),
                  borderRadius: AppRadius.mdAll,
                  child: Padding(
                    padding: AppInsets.card,
                    child: Row(
                      children: [
                        Icon(
                          Icons.phone_android_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            l10n.receiptScanAndroidOnlyBanner,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Expanded(
              child: LedgerAsyncBody(
                isLoading: ctrl.loading,
                errorMessage: ctrl.errorMessage,
                isEmpty: ctrl.isEmpty,
                emptyMessage: l10n.ingestionEmpty,
                child: ListView(
                  padding: AppInsets.pageCompact,
                  children: [
                    for (final draft in ctrl.pending)
                      _IngestionTile(
                        draft: draft,
                        currency: ctrl.currency,
                        locale: locale,
                        onTap: () => context.push(
                          AppRoutes.ingestionDetailPath(draft.id),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IngestionTile extends StatelessWidget {
  const _IngestionTile({
    required this.draft,
    required this.currency,
    required this.locale,
    required this.onTap,
  });

  final IngestionDraft draft;
  final String currency;
  final String locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final amount = draft.amountMinor == null
        ? '—'
        : '${Money.formatFromMinor(draft.amountMinor!, locale)} $currency';
    final statusLabel = draft.status == IngestionStatus.possibleDuplicate
        ? l10n.ingestionStatusPossibleDuplicate
        : l10n.ingestionStatusNeedsReview;
    final sourceLabel = draft.source == IngestionSource.receiptOcr
        ? l10n.ingestionSourceReceiptOcr
        : l10n.ingestionSourceNotification;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          draft.status == IngestionStatus.possibleDuplicate
              ? Icons.copy_all_outlined
              : draft.source == IngestionSource.notification
              ? Icons.notifications_outlined
              : Icons.inbox_outlined,
        ),
        title: Text(
          draft.merchant?.isNotEmpty == true
              ? draft.merchant!
              : l10n.ingestionUnknownMerchant,
        ),
        subtitle: Text(
          [
            amount,
            if (draft.bookingDate != null && draft.bookingDate!.isNotEmpty)
              draft.bookingDate!,
            sourceLabel,
            statusLabel,
          ].join(' · '),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
