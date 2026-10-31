import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/firebase/firebase_bootstrap.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/ui/kinship_widgets.dart';
import '../../../l10n/app_localizations.dart';
import 'auth_controller.dart';
import 'google_gis_button.dart';

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
  bool _googleReady = false;
  String? _googleInitError;

  bool get _showGoogle => !FirebaseBootstrap.shouldUseEmulators;

  @override
  void initState() {
    super.initState();
    if (_showGoogle) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _prepareGoogle());
    }
  }

  Future<void> _prepareGoogle() async {
    final auth = context.read<AuthController>();
    try {
      await auth.ensureGoogleSignInInitialized();
      await auth.wireGoogleAuthenticationEvents();
      if (!mounted) return;
      setState(() {
        _googleReady = true;
        _googleInitError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _googleReady = false;
        _googleInitError = e.toString();
      });
    }
  }

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

  Widget _buildGoogleSection(AuthController auth, AppLocalizations l10n) {
    if (_googleInitError != null) {
      return Text(
        _googleInitError!,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      );
    }
    if (!_googleReady) {
      return const Center(
        child: SizedBox(
          width: AppSizes.buttonProgress,
          height: AppSizes.buttonProgress,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    // Web: official GIS button. Other platforms: authenticate() via our pill.
    if (!auth.googleSupportsAuthenticate) {
      final gis = buildGoogleGisSignInButton();
      if (gis != null) {
        return Center(child: gis);
      }
      if (kIsWeb) {
        return Text(
          'Google Sign-In is unavailable in this browser build.',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        );
      }
    }

    return KinshipSecondaryPillButton(
      onPressed: auth.busy ? null : _google,
      icon: const Icon(Icons.g_mobiledata),
      child: Text(l10n.authContinueGoogle),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthController>();
    final wide = AppBreakpoints.isWide(context);

    return KinshipAuthScaffold(
      brandPanel: KinshipAuthBrandPanel(title: l10n.appTitle),
      body: SingleChildScrollView(
        child: KinshipAuthPanel(
          showCard: !wide,
          brandName: l10n.appTitle,
          headline: _registerMode ? l10n.authCreateAccount : l10n.authSignIn,
          footer: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (auth.errorMessage != null) ...[
                _AuthErrorBanner(message: auth.errorMessage!),
                const SizedBox(height: AppSpacing.sm),
              ],
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (_registerMode)
                      TextFormField(
                        controller: _displayName,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: l10n.authDisplayName,
                        ),
                      ),
                    if (_registerMode) const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
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
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) {
                        if (!auth.busy) _submit();
                      },
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
              KinshipPrimaryPillButton(
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
              if (_showGoogle) ...[
                const SizedBox(height: AppSpacing.sm),
                _buildGoogleSection(auth, l10n),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthErrorBanner extends StatelessWidget {
  const _AuthErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: AppRadius.mdAll,
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: scheme.onErrorContainer),
      ),
    );
  }
}
