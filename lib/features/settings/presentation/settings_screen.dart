import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/locale/locale_controller.dart';
import '../../../l10n/app_localizations.dart';

/// Settings: language preference (persisted).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeController = context.watch<LocaleController>();
    final current = localeController.locale.languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l10n.settingsLanguage,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
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
        ],
      ),
    );
  }
}
