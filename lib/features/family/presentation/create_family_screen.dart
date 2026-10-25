import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/ui/kinship_widgets.dart';
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final token = context.read<AuthController>().pendingInviteToken;
      if (token != null && token.isNotEmpty) {
        context.go(AppRoutes.invitePath(token));
      }
    });
  }

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
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final wide = AppBreakpoints.isWide(context);

    return KinshipAuthScaffold(
      brandPanel: KinshipAuthBrandPanel(
        title: l10n.appTitle,
        subtitle: l10n.familyCreateBody,
        logo: Icon(
          Icons.account_balance_wallet_outlined,
          size: 40,
          color: scheme.onPrimary,
        ),
      ),
      body: SingleChildScrollView(
        child: KinshipAuthPanel(
          showCard: !wide,
          brandName: l10n.appTitle,
          logo: Icon(
            Icons.groups_outlined,
            size: 32,
            color: scheme.primaryContainer,
          ),
          headline: l10n.familyCreateTitle,
          body: l10n.familyCreateBody,
          footer: Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: auth.busy ? null : () => auth.signOut(),
              child: Text(l10n.authSignOut),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (family.errorMessage != null) ...[
                Text(
                  family.errorMessage!,
                  style: TextStyle(color: scheme.error),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _name,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(labelText: l10n.familyName),
                  validator: (v) => (v == null || v.trim().length < 2)
                      ? l10n.familyNameInvalid
                      : null,
                  onFieldSubmitted: (_) {
                    if (!family.busy) _create(family, auth);
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.familyCurrencyHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              KinshipPrimaryPillButton(
                onPressed: family.busy ? null : () => _create(family, auth),
                child: family.busy
                    ? const SizedBox(
                        height: AppSizes.buttonProgress,
                        width: AppSizes.buttonProgress,
                        child: CircularProgressIndicator(
                          strokeWidth: AppSizes.progressStroke,
                        ),
                      )
                    : Text(l10n.familyCreateAction),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.familyOrAcceptInvite,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if (auth.pendingInviteToken != null) ...[
                const SizedBox(height: AppSpacing.sm),
                KinshipSecondaryPillButton(
                  onPressed: () {
                    context.go(AppRoutes.invitePath(auth.pendingInviteToken!));
                  },
                  child: Text(l10n.inviteAcceptAction),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _create(FamilyController family, AuthController auth) async {
    if (!_formKey.currentState!.validate()) return;
    try {
      final familyId = await family.createFamily(name: _name.text.trim());
      auth.applyFamilyId(familyId);
      if (mounted) context.go(AppRoutes.home);
    } catch (_) {}
  }
}
