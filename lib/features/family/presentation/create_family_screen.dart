import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/ui/app_page.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/auth_controller.dart';
import 'family_controller.dart';

class CreateFamilyScreen extends StatefulWidget {
  const CreateFamilyScreen({super.key});

  @override
  State<CreateFamilyScreen> createState() => _CreateFamilyScreenState();
}

class _CreateFamilyScreenState extends State<CreateFamilyScreen> {
  final _name = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final family = context.watch<FamilyController>();
    final auth = context.watch<AuthController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.familyCreateTitle),
        actions: [
          TextButton(
            onPressed: auth.busy ? null : () => auth.signOut(),
            child: Text(l10n.authSignOut),
          ),
        ],
      ),
      body: AppPage(
        form: true,
        child: ListView(
          padding: AppInsets.page,
          children: [
            Text(l10n.familyCreateBody),
            const SizedBox(height: AppSpacing.md),
            if (family.errorMessage != null) ...[
              Text(
                family.errorMessage!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _name,
                decoration: InputDecoration(labelText: l10n.familyName),
                validator: (v) => (v == null || v.trim().length < 2)
                    ? l10n.familyNameInvalid
                    : null,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.familyCurrencyHint, style: theme.textTheme.bodySmall),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: family.busy
                  ? null
                  : () async {
                      if (!_formKey.currentState!.validate()) return;
                      try {
                        await family.createFamily(name: _name.text.trim());
                        if (context.mounted) context.go(AppRoutes.home);
                      } catch (_) {}
                    },
              child: Text(l10n.familyCreateAction),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.familyOrAcceptInvite,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
