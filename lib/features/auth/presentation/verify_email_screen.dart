import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/ui/app_page.dart';
import '../../../l10n/app_localizations.dart';
import 'auth_controller.dart';

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.authVerifyEmailTitle),
        actions: [
          TextButton(
            onPressed: auth.busy ? null : () => auth.signOut(),
            child: Text(l10n.authSignOut),
          ),
        ],
      ),
      body: AppPage(
        form: true,
        padding: AppInsets.page,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.authVerifyEmailBody(auth.user?.email ?? ''),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (auth.errorMessage != null) ...[
              Text(
                auth.errorMessage!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            FilledButton(
              onPressed: auth.busy
                  ? null
                  : () async {
                      await auth.reloadUser();
                      if (auth.isEmailVerified && context.mounted) {
                        final next = GoRouterState.of(
                          context,
                        ).uri.queryParameters['next'];
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
            OutlinedButton(
              onPressed: auth.busy ? null : () => auth.sendEmailVerification(),
              child: Text(l10n.authResendVerification),
            ),
          ],
        ),
      ),
    );
  }
}
