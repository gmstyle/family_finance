import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/locale/locale_controller.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/ui/app_page.dart';
import '../../../l10n/app_localizations.dart';

/// In-app privacy policy — presentation only (asset text by locale).
class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  Future<String>? _load;
  String? _loadedLanguage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final code = context.watch<LocaleController>().locale.languageCode;
    if (_loadedLanguage == code && _load != null) return;
    _loadedLanguage = code;
    final asset = code == 'it'
        ? 'assets/legal/privacy_it.md'
        : 'assets/legal/privacy_en.md';
    _load = rootBundle.loadString(asset);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsPrivacyPolicy)),
      body: AppPage(
        child: FutureBuilder<String>(
          future: _load,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError || snap.data == null) {
              return Center(child: Text(l10n.settingsPrivacyLoadError));
            }
            return SingleChildScrollView(
              padding: AppInsets.pageCompact,
              child: SelectableText(
                snap.data!,
                style: theme.textTheme.bodyMedium,
              ),
            );
          },
        ),
      ),
    );
  }
}
