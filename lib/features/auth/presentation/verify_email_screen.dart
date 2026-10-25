import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/ui/kinship_widgets.dart';
import '../../../l10n/app_localizations.dart';
import 'auth_controller.dart';

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

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
            Icons.mark_email_unread_outlined,
            size: 32,
            color: scheme.primaryContainer,
          ),
          headline: l10n.authVerifyEmailTitle,
          body: l10n.authVerifyEmailBody(auth.user?.email ?? ''),
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
              if (auth.errorMessage != null) ...[
                Text(
                  auth.errorMessage!,
                  style: TextStyle(color: scheme.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              KinshipPrimaryPillButton(
                onPressed: auth.busy
                    ? null
                    : () async {
                        await auth.reloadUser();
                        if (auth.isEmailVerified && context.mounted) {
                          final next = GoRouterState.of(context)
                              .uri
                              .queryParameters['next'];
                          if (next != null && next.isNotEmpty) {
                            auth.rememberPendingInvite(next);
                            context.go(next);
                          } else if (auth.pendingInvitePath != null) {
                            context.go(auth.pendingInvitePath!);
                          } else {
                            context.go(AppRoutes.home);
                          }
                        }
                      },
                child: Text(l10n.authIVerified),
              ),
              const SizedBox(height: AppSpacing.sm),
              KinshipSecondaryPillButton(
                onPressed: auth.busy
                    ? null
                    : () => auth.sendEmailVerification(),
                child: Text(l10n.authResendVerification),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
