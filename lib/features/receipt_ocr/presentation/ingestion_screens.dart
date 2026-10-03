import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/locale/locale_controller.dart';
import '../../../core/money/money.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/ui/app_page.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/ledger_async_body.dart';
import '../../accounts/data/accounts_repository.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../categories/data/categories_repository.dart';
import '../../family/data/family_repository.dart';
import '../../ledger/ledger_labels.dart';
import '../data/ingestion_repository.dart';
import '../domain/italian_receipt_parser.dart';
import '../domain/receipt_ocr_service.dart';

/// Inbox of pending Ingestion drafts (Android + web).
class IngestionInboxScreen extends StatelessWidget {
  const IngestionInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthController>();
    final familyId = auth.familyId;
    final locale = context.watch<LocaleController>().locale.languageCode;
    final repo = context.read<IngestionRepository>();
    final ocr = context.read<ReceiptOcrService>();
    final familyRepo = context.read<FamilyController>().repository;

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
              child: StreamBuilder<FamilyInfo?>(
                stream: familyRepo.watchFamily(familyId),
                builder: (context, familySnap) {
                  final currency = familySnap.data?.currency ?? 'EUR';
                  return StreamBuilder<List<IngestionDraft>>(
                    stream: repo.watchPendingQueue(familyId),
                    builder: (context, snap) {
                      final error = snap.hasError
                          ? snap.error.toString()
                          : null;
                      final drafts = snap.data;

                      return LedgerAsyncBody(
                        isLoading:
                            snap.connectionState == ConnectionState.waiting &&
                            drafts == null,
                        errorMessage: error,
                        isEmpty: drafts != null && drafts.isEmpty,
                        emptyMessage: l10n.ingestionEmpty,
                        child: ListView(
                          padding: AppInsets.pageCompact,
                          children: [
                            for (final draft
                                in drafts ?? const <IngestionDraft>[])
                              _IngestionTile(
                                draft: draft,
                                currency: currency,
                                locale: locale,
                                onTap: () => context.push(
                                  AppRoutes.ingestionDetailPath(draft.id),
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

  @override
  void initState() {
    super.initState();
    _bookingDate = formatBookingDate(DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final familyId = context.read<AuthController>().familyId;
    final locale = context.read<LocaleController>().locale.languageCode;
    final familyRepo = context.read<FamilyController>().repository;
    final repo = context.read<IngestionRepository>();
    final notFound = AppLocalizations.of(context)!.ledgerNotFound;

    if (familyId == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final family = await familyRepo.watchFamily(familyId).first;
      _currency = family?.currency ?? 'EUR';
      final draft = await repo.getDraft(familyId, widget.dedupKey);
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
    final familyId = context.read<AuthController>().familyId;
    final update = _validatedUpdate(l10n);
    if (familyId == null || update == null) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<IngestionRepository>().confirmDraft(
        familyId: familyId,
        dedupKey: widget.dedupKey,
        update: update,
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
    final familyId = context.read<AuthController>().familyId;
    if (familyId == null) return;

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
      await context.read<IngestionRepository>().discardDraft(
        familyId: familyId,
        dedupKey: widget.dedupKey,
      );
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
    final familyId = context.watch<AuthController>().familyId;
    final theme = Theme.of(context);

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
                    StreamBuilder(
                      stream: context.read<AccountsRepository>().watchAccounts(
                        familyId,
                      ),
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
                      stream: context
                          .read<CategoriesRepository>()
                          .watchCategories(
                            familyId,
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

/// Capture / pick receipt image → OCR → Ingestion draft (Android only).
///
/// On unsupported platforms shows a localized Android-only explanation and
/// a link to the review queue — no `kIsWeb` checks.
class ReceiptScanScreen extends StatefulWidget {
  const ReceiptScanScreen({super.key});

  @override
  State<ReceiptScanScreen> createState() => _ReceiptScanScreenState();
}

class _ReceiptScanScreenState extends State<ReceiptScanScreen> {
  final _picker = ImagePicker();
  final _parser = const ItalianReceiptParser();
  bool _busy = false;
  String? _error;

  Future<void> _scan(ImageSource source) async {
    final l10n = AppLocalizations.of(context)!;
    final ocr = context.read<ReceiptOcrService>();
    if (!ocr.isCaptureSupported) {
      setState(() => _error = l10n.receiptScanAndroidOnlyBody);
      return;
    }

    final familyId = context.read<AuthController>().familyId;
    if (familyId == null) return;
    final accountsRepo = context.read<AccountsRepository>();
    final ingestionRepo = context.read<IngestionRepository>();

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 2000,
      );
      if (file == null) {
        if (mounted) setState(() => _busy = false);
        return;
      }

      final lines = await ocr.recognizeLines(file.path);
      final parsed = _parser.parse(lines);

      String? defaultAccountId;
      final accounts = await accountsRepo.watchAccounts(familyId).first;
      if (accounts.isNotEmpty) {
        defaultAccountId = accounts.first.id;
      }

      final dedupKey = await ingestionRepo.createDraftFromOcr(
        familyId: familyId,
        parsed: parsed,
        defaultAccountId: defaultAccountId,
      );

      if (!mounted) return;
      context.pushReplacement(AppRoutes.ingestionDetailPath(dedupKey));
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ocr = context.watch<ReceiptOcrService>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.receiptScanTitle)),
      body: AppPage(
        padding: AppInsets.page,
        child: ocr.isCaptureSupported
            ? ListView(
                children: [
                  Text(l10n.receiptScanBody, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.icon(
                    onPressed: _busy ? null : () => _scan(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: Text(l10n.receiptScanCamera),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _scan(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(l10n.receiptScanGallery),
                  ),
                  if (_busy) ...[
                    const SizedBox(height: AppSpacing.lg),
                    const Center(child: CircularProgressIndicator()),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.receiptScanProcessing,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      _error!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                ],
              )
            : ListView(
                children: [
                  Icon(
                    Icons.phone_android_outlined,
                    size: 56,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.receiptScanAndroidOnlyTitle,
                    style: theme.textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.receiptScanAndroidOnlyBody,
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    onPressed: () => context.go(AppRoutes.ingestion),
                    child: Text(l10n.ingestionOpenQueue),
                  ),
                ],
              ),
      ),
    );
  }
}
