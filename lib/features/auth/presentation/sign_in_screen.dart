import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/ui/app_page.dart';
import '../../../l10n/app_localizations.dart';
import 'auth_controller.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _registerMode = false;
  final _displayName = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _displayName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthController>();
    try {
      if (_registerMode) {
        await auth.registerWithEmail(
          email: _email.text,
          password: _password.text,
          displayName: _displayName.text,
        );
      } else {
        await auth.signInWithEmail(
          email: _email.text,
          password: _password.text,
        );
      }
      if (!mounted) return;
      final next = GoRouterState.of(context).uri.queryParameters['next'];
      if (next != null && next.isNotEmpty) {
        auth.rememberPendingInvite(next);
        if (auth.isEmailVerified) {
          context.go(next);
        }
      }
    } catch (_) {
      // Error surfaced via auth.errorMessage
    }
  }

  Future<void> _google() async {
    try {
      await context.read<AuthController>().signInWithGoogle();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthController>();
    final theme = Theme.of(context);

    return Scaffold(
      body: AppPage(
        form: true,
        safeArea: true,
        child: ListView(
          padding: AppInsets.page,
          children: [
            Text(l10n.appTitle, style: theme.textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _registerMode ? l10n.authCreateAccount : l10n.authSignIn,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (auth.errorMessage != null) ...[
              Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: AppInsets.card,
                  child: Text(auth.errorMessage!),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            Form(
              key: _formKey,
              child: Column(
                children: [
                  if (_registerMode)
                    TextFormField(
                      controller: _displayName,
                      decoration: InputDecoration(
                        labelText: l10n.authDisplayName,
                      ),
                    ),
                  if (_registerMode) const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: InputDecoration(labelText: l10n.authEmail),
                    validator: (v) => (v == null || !v.contains('@'))
                        ? l10n.authEmailInvalid
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(labelText: l10n.authPassword),
                    validator: (v) => (v == null || v.length < 6)
                        ? l10n.authPasswordTooShort
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: auth.busy ? null : _submit,
              child: auth.busy
                  ? const SizedBox(
                      height: AppSizes.buttonProgress,
                      width: AppSizes.buttonProgress,
                      child: CircularProgressIndicator(
                        strokeWidth: AppSizes.progressStroke,
                      ),
                    )
                  : Text(_registerMode ? l10n.authRegister : l10n.authSignIn),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: auth.busy ? null : _google,
              icon: const Icon(Icons.g_mobiledata),
              label: Text(l10n.authContinueGoogle),
            ),
            TextButton(
              onPressed: () => setState(() {
                _registerMode = !_registerMode;
                auth.clearError();
              }),
              child: Text(
                _registerMode ? l10n.authHaveAccount : l10n.authNeedAccount,
              ),
            ),
            TextButton(
              onPressed: () => context.push(AppRoutes.forgotPassword),
              child: Text(l10n.authForgotPassword),
            ),
          ],
        ),
      ),
    );
  }
}
