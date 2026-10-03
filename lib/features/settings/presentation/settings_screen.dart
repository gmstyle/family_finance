import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/locale/locale_controller.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/ui/app_page.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/auth_controller.dart';

/// Settings: language, account, family entry points.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeController = context.watch<LocaleController>();
    final auth = context.watch<AuthController>();
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
