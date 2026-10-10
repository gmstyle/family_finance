import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../router/app_router.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/family/presentation/family_controller.dart';
import 'pending_invite_store.dart';

/// Accepts a stored invite as soon as auth is ready (any route — e.g. after
/// email verification reload landed on `/`).
class PendingInviteAcceptListener extends StatefulWidget {
  const PendingInviteAcceptListener({super.key, required this.child});

  final Widget child;

  @override
  State<PendingInviteAcceptListener> createState() =>
      _PendingInviteAcceptListenerState();
}

class _PendingInviteAcceptListenerState
    extends State<PendingInviteAcceptListener> {
  bool _running = false;
  String? _lastFailedToken;
  bool _lastEmailVerified = false;

  void _showError(String message) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 8)),
    );
  }

  Future<void> _maybeAccept(String token) async {
    if (_running || token == _lastFailedToken) return;
    final auth = context.read<AuthController>();
    if (!auth.isSignedIn || !auth.profileReady || auth.hasFamily) {
      return;
    }

    _running = true;
    try {
      await auth.reloadUser();
      if (!mounted) return;
      if (!auth.isEmailVerified) {
        return;
      }

      final familyId = await context.read<FamilyController>().acceptInvite(
        token,
      );
      if (!mounted) return;
      auth.applyFamilyId(familyId);
      await PendingInviteStore.clear();
      if (mounted) context.go(AppRoutes.home);
    } catch (_) {
      if (!mounted) return;
      final synced = await auth.syncFamilyIdFromServer();
      if (!mounted) return;
      if (synced) {
        await PendingInviteStore.clear();
        if (mounted) context.go(AppRoutes.home);
        return;
      }
      _lastFailedToken = token;
      final family = context.read<FamilyController>();
      _showError(family.errorMessage ?? 'Could not accept invite.');
    } finally {
      _running = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final family = context.watch<FamilyController>();
    final token = auth.pendingInviteToken;

    if (auth.isEmailVerified && !_lastEmailVerified) {
      _lastFailedToken = null;
    }
    _lastEmailVerified = auth.isEmailVerified;

    if (token != null &&
        token.isNotEmpty &&
        !family.busy &&
        !_running &&
        token != _lastFailedToken &&
        auth.isSignedIn &&
        auth.profileReady &&
        !auth.hasFamily) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAccept(token));
    }

    return widget.child;
  }
}
