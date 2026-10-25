import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/ui/kinship_widgets.dart';
import '../../../l10n/app_localizations.dart';
import 'auth_controller.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _sendReset(AuthController auth) async {
    try {
      await auth.sendPasswordReset(_email.text);
      setState(() => _sent = true);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthController>();
    final scheme = Theme.of(context).colorScheme;
    final wide = AppBreakpoints.isWide(context);

    return KinshipAuthScaffold(
      brandPanel: KinshipAuthBrandPanel(
        title: l10n.appTitle,
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
            Icons.lock_reset_outlined,
            size: 32,
            color: scheme.primaryContainer,
          ),
          headline: l10n.authForgotPassword,
          footer: TextButton(
            onPressed: () => context.pop(),
            child: Text(l10n.authBackToSignIn),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_sent)
                Text(
                  l10n.authResetSent,
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(color: scheme.onSurfaceVariant),
                )
              else ...[
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.email],
                  decoration: InputDecoration(labelText: l10n.authEmail),
                  onFieldSubmitted: (_) {
                    if (!auth.busy) _sendReset(auth);
                  },
                ),
                if (auth.errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    auth.errorMessage!,
                    style: TextStyle(color: scheme.error),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                KinshipPrimaryPillButton(
                  onPressed: auth.busy ? null : () => _sendReset(auth),
                  child: auth.busy
                      ? const SizedBox(
                          height: AppSizes.buttonProgress,
                          width: AppSizes.buttonProgress,
                          child: CircularProgressIndicator(
                            strokeWidth: AppSizes.progressStroke,
                          ),
                        )
                      : Text(l10n.authSendReset),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
