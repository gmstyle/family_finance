import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/locale/locale_controller.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/ui/app_page.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../notification_ingest/presentation/notification_ingest_controller.dart';

/// Settings: language, account, family entry points.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  bool? _listenerEnabled;
  bool _listenerLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshListener());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshListener();
    }
  }

  Future<void> _refreshListener() async {
    final ingest = context.read<NotificationIngestController>();
    if (!ingest.isCaptureSupported) {
      if (mounted) setState(() => _listenerEnabled = null);
      return;
    }
    setState(() => _listenerLoading = true);
    try {
      final enabled = await ingest.isListenerEnabled();
      if (mounted) setState(() => _listenerEnabled = enabled);
    } finally {
      if (mounted) setState(() => _listenerLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeController = context.watch<LocaleController>();
    final auth = context.watch<AuthController>();
    final ingest = context.read<NotificationIngestController>();
    final current = localeController.locale.languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: AppPage(
        child: ListView(
          children: [
            AppSectionTitle(l10n.settingsLanguage),
            RadioGroup<String>(
              groupValue: current,
              onChanged: (value) {
                if (value == null) return;
                localeController.setLocale(Locale(value));
              },
              child: Column(
                children: [
                  RadioListTile<String>(
                    title: Text(l10n.languageEnglish),
                    value: 'en',
                  ),
                  RadioListTile<String>(
                    title: Text(l10n.languageItalian),
                    value: 'it',
                  ),
                ],
              ),
            ),
            const Divider(),
            AppSectionTitle(
              l10n.settingsAccount,
              padding: AppInsets.sectionTight,
            ),
            ListTile(
              title: Text(auth.user?.email ?? ''),
              subtitle: Text(auth.user?.displayName ?? ''),
            ),
            ListTile(
              leading: const Icon(Icons.family_restroom),
              title: Text(l10n.settingsFamily),
              onTap: () => context.push(AppRoutes.family),
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: Text(l10n.accountsTitle),
              onTap: () => context.push(AppRoutes.accounts),
            ),
            ListTile(
              leading: const Icon(Icons.category_outlined),
              title: Text(l10n.categoriesTitle),
              onTap: () => context.push(AppRoutes.categories),
            ),
            ListTile(
              leading: const Icon(Icons.inbox_outlined),
              title: Text(l10n.ingestionTitle),
              onTap: () => context.push(AppRoutes.ingestion),
            ),
            ListTile(
              leading: const Icon(Icons.document_scanner_outlined),
              title: Text(l10n.receiptScanTitle),
              onTap: () => context.push(AppRoutes.receiptScan),
            ),
            const Divider(),
            AppSectionTitle(
              l10n.notificationListenerTitle,
              padding: AppInsets.sectionTight,
            ),
            if (!ingest.isCaptureSupported)
              ListTile(
                leading: const Icon(Icons.notifications_off_outlined),
                title: Text(l10n.notificationListenerAndroidOnly),
              )
            else
              ListTile(
                leading: Icon(
                  _listenerEnabled == true
                      ? Icons.notifications_active_outlined
                      : Icons.notification_important_outlined,
                ),
                title: Text(l10n.notificationListenerTitle),
                subtitle: Text(
                  _listenerLoading
                      ? '…'
                      : _listenerEnabled == true
                      ? l10n.notificationListenerEnabled
                      : l10n.notificationListenerDisabled,
                ),
                trailing: const Icon(Icons.open_in_new),
                onTap: () async {
                  await ingest.openListenerSettings();
                  await _refreshListener();
                },
              ),
            if (ingest.isCaptureSupported)
              ListTile(
                leading: const Icon(Icons.link_outlined),
                title: Text(l10n.accountBindingsOpen),
                onTap: () => context.push(AppRoutes.accountBindings),
              ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(l10n.authSignOut),
              onTap: auth.busy ? null : () => auth.signOut(),
            ),
          ],
        ),
      ),
    );
  }
}
