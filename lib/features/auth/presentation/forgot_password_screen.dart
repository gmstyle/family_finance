import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/ui/app_page.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthController>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.authForgotPassword)),
      body: AppPage(
        form: true,
        padding: AppInsets.page,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_sent)
              Text(l10n.authResetSent, textAlign: TextAlign.center)
            else ...[
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: l10n.authEmail),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: auth.busy
                    ? null
                    : () async {
                        try {
                          await auth.sendPasswordReset(_email.text);
                          setState(() => _sent = true);
                        } catch (_) {}
                      },
                child: Text(l10n.authSendReset),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: () => context.pop(),
              child: Text(l10n.authBackToSignIn),
            ),
          ],
        ),
      ),
    );
  }
}
