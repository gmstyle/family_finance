import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/ui/app_page.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/ledger_async_body.dart';
import '../../accounts/domain/account.dart';
import '../../auth/presentation/auth_controller.dart';
import 'account_bindings_controller.dart';
import 'notification_ingest_controller.dart';

/// Map allowlisted notification packages → suggested ledger accounts.
class AccountBindingsScreen extends StatefulWidget {
  const AccountBindingsScreen({super.key});

  @override
  State<AccountBindingsScreen> createState() => _AccountBindingsScreenState();
}

class _AccountBindingsScreenState extends State<AccountBindingsScreen> {
  String? _boundFamilyId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final familyId = context.watch<AuthController>().familyId;
    if (familyId != _boundFamilyId) {
      _boundFamilyId = familyId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<AccountBindingsController>().bindFamily(familyId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final familyId = context.select((AuthController c) => c.familyId);
    final ingest = context.read<NotificationIngestController>();
    final ctrl = context.watch<AccountBindingsController>();

    if (familyId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.accountBindingsTitle)),
        body: Center(child: Text(l10n.familyMissing)),
      );
    }

    final packages = ingest.allowedPackages;
    final accounts = ctrl.accounts;
    final bindingsByPackage = ctrl.bindingsByPackage;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountBindingsTitle)),
      body: AppPage(
        child: LedgerAsyncBody(
          isLoading: ctrl.loading,
          errorMessage: ctrl.errorMessage,
          isEmpty: packages.isEmpty,
          emptyMessage: l10n.accountBindingsEmpty,
          child: ListView(
            padding: AppInsets.pageCompact,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(
                  l10n.accountBindingsHint,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              for (final package in packages)
                _BindingTile(
                  packageName: package,
                  accounts: accounts,
                  selectedAccountId: _selectedAccountId(
                    bindingsByPackage[package]?.accountId,
                    accounts,
                  ),
                  noneLabel: l10n.accountBindingsNone,
                  onChanged: (accountId) async {
                    if (accountId == null || accountId.isEmpty) {
                      await ctrl.clearBinding(package);
                    } else {
                      await ctrl.setBinding(
                        packageName: package,
                        accountId: accountId,
                      );
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  String? _selectedAccountId(String? accountId, List<Account> accounts) {
    if (accountId == null || accountId.isEmpty) return null;
    final exists = accounts.any((a) => a.id == accountId);
    return exists ? accountId : null;
  }
}

class _BindingTile extends StatelessWidget {
  const _BindingTile({
    required this.packageName,
    required this.accounts,
    required this.selectedAccountId,
    required this.noneLabel,
    required this.onChanged,
  });

  final String packageName;
  final List<Account> accounts;
  final String? selectedAccountId;
  final String noneLabel;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        title: Text(_packageLabel(packageName)),
        subtitle: Text(packageName),
        trailing: DropdownButton<String?>(
          value: selectedAccountId,
          hint: Text(noneLabel),
          underline: const SizedBox.shrink(),
          items: [
            DropdownMenuItem<String?>(value: null, child: Text(noneLabel)),
            for (final a in accounts)
              DropdownMenuItem<String?>(value: a.id, child: Text(a.name)),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  String _packageLabel(String package) {
    if (package == 'com.google.android.apps.walletnfcrel') {
      return 'Google Wallet';
    }
    final parts = package.split('.');
    return parts.isNotEmpty ? parts.last : package;
  }
}
