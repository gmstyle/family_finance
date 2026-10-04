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
import 'settings_controller.dart';

/// Settings: language, account, privacy/data, family entry points.
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

  Future<void> _export() async {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.read<AuthController>();
    final settings = context.read<SettingsController>();
    try {
      await settings.exportAndShare(familyId: auth.familyId);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.settingsExportDone)));
    } catch (_) {
      if (!mounted) return;
      final msg = settings.errorMessage ?? l10n.settingsDeleteFailedGeneric;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<bool> _reauthenticate(AppLocalizations l10n) async {
    final auth = context.read<AuthController>();
    if (auth.hasPasswordProvider) {
      final password = await showDialog<String>(
        context: context,
        builder: (context) {
          final controller = TextEditingController();
          return AlertDialog(
            title: Text(l10n.settingsDeleteReauthTitle),
            content: TextField(
              controller: controller,
              obscureText: true,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.settingsDeleteReauthPassword,
              ),
              onSubmitted: (v) => Navigator.pop(context, v),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.actionCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: Text(l10n.actionContinue),
              ),
            ],
          );
        },
      );
      if (password == null || password.isEmpty || !mounted) return false;
      try {
        await auth.reauthenticateWithPassword(password);
        return true;
      } catch (_) {
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              auth.errorMessage ?? l10n.settingsDeleteFailedGeneric,
            ),
          ),
        );
        return false;
      }
    }

    if (auth.hasGoogleProvider) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.settingsDeleteReauthTitle),
          content: Text(l10n.settingsDeleteReauthGoogle),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.settingsDeleteReauthGoogle),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return false;
      try {
        await auth.reauthenticateWithGoogle();
        return true;
      } catch (_) {
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              auth.errorMessage ?? l10n.settingsDeleteFailedGeneric,
            ),
          ),
        );
        return false;
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.settingsDeleteFailedGeneric)));
    }
    return false;
  }

  String _mapDeleteError(AppLocalizations l10n, String? message) {
    final lower = (message ?? '').toLowerCase();
    if (lower.contains('promote another admin')) {
      return l10n.settingsDeleteFailedPromote;
    }
    if (lower.contains('transfer ownership')) {
      return l10n.settingsDeleteFailedTransfer;
    }
    return l10n.settingsDeleteFailedGeneric;
  }

  Future<void> _deleteAccount() async {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.read<AuthController>();
    final settings = context.read<SettingsController>();

    final sole = await settings.isSoleFamilyMember(auth.familyId);
    if (!mounted) return;

    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          sole
              ? l10n.settingsDeleteAccountSoleTitle
              : l10n.settingsDeleteAccountTitle,
        ),
        content: Text(
          sole
              ? l10n.settingsDeleteAccountSoleBody
              : l10n.settingsDeleteAccountBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.settingsDeleteAccountConfirmAction),
          ),
        ],
      ),
    );
    if (proceed != true || !mounted) return;

    final reauthed = await _reauthenticate(l10n);
    if (!reauthed || !mounted) return;

    try {
      await settings.deleteAccount(confirmFamilyWipe: sole);
      if (!mounted) return;
      context.go(AppRoutes.signIn);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_mapDeleteError(l10n, settings.errorMessage))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeController = context.watch<LocaleController>();
    final auth = context.watch<AuthController>();
    final settings = context.watch<SettingsController>();
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
              l10n.settingsPrivacyData,
              padding: AppInsets.sectionTight,
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: Text(l10n.settingsPrivacyPolicy),
              onTap: () => context.push(AppRoutes.settingsPrivacy),
            ),
            ListTile(
              leading: settings.exportBusy
                  ? const SizedBox(
                      width: AppSizes.buttonProgress,
                      height: AppSizes.buttonProgress,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_outlined),
              title: Text(l10n.settingsExportData),
              subtitle: Text(l10n.settingsExportDataHint),
              onTap: settings.busy ? null : _export,
            ),
            ListTile(
              leading: settings.deleteBusy
                  ? const SizedBox(
                      width: AppSizes.buttonProgress,
                      height: AppSizes.buttonProgress,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      Icons.delete_forever_outlined,
                      color: Theme.of(context).colorScheme.error,
                    ),
              title: Text(l10n.settingsDeleteAccount),
              subtitle: Text(l10n.settingsDeleteAccountHint),
              onTap: settings.busy || auth.busy ? null : _deleteAccount,
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
