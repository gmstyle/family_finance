import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/ui/app_page.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/italian_receipt_parser.dart';
import '../domain/receipt_ocr_service.dart';
import 'ingestion_controller.dart';

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

  Future<void> _scan(ImageSource source) async {
    final l10n = AppLocalizations.of(context)!;
    final ocr = context.read<ReceiptOcrService>();
    if (!ocr.isCaptureSupported) {
      setState(() => _error = l10n.receiptScanAndroidOnlyBody);
      return;
    }

    final familyId = context.read<AuthController>().familyId;
    if (familyId == null) return;
    final ingestionCtrl = context.read<IngestionController>();

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
      final accounts = ingestionCtrl.accounts.isNotEmpty
          ? ingestionCtrl.accounts
          : await ingestionCtrl.watchAccounts().first;
      if (accounts.isNotEmpty) {
        defaultAccountId = accounts.first.id;
      }

      final dedupKey = await ingestionCtrl.createDraftFromOcr(
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
