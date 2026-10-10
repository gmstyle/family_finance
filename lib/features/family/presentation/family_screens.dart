import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/invite/invite_links.dart';
import '../../../core/invite/pending_invite_store.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/ui/app_page.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/auth_controller.dart';
import 'family_controller.dart';

class AcceptInviteScreen extends StatefulWidget {
  const AcceptInviteScreen({super.key, required this.token});

  final String token;

  @override
  State<AcceptInviteScreen> createState() => _AcceptInviteScreenState();
}

class _AcceptInviteScreenState extends State<AcceptInviteScreen> {
  String? _localError;
  bool _done = false;
  String get _invitePath => AppRoutes.invitePath(widget.token);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthController>().rememberPendingInvite(_invitePath);
    });
  }

  Future<void> _accept() async {
    setState(() => _localError = null);
    final auth = context.read<AuthController>();
    auth.rememberPendingInvite(_invitePath);
    await auth.reloadUser();
    if (!mounted) return;
    if (!auth.isSignedIn) {
      context.go(
        '${AppRoutes.signIn}?next=${Uri.encodeComponent(_invitePath)}',
      );
      return;
    }
    if (!auth.isEmailVerified) {
      context.go(
        '${AppRoutes.verifyEmail}?next=${Uri.encodeComponent(_invitePath)}',
      );
      return;
    }
    try {
      final familyId = await context.read<FamilyController>().acceptInvite(
        widget.token,
      );
      auth.applyFamilyId(familyId);
      await PendingInviteStore.clear();
      setState(() => _done = true);
      if (mounted) context.go(AppRoutes.home);
    } catch (e) {
      setState(() => _localError = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthController>();
    final family = context.watch<FamilyController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.inviteAcceptTitle)),
      body: AppPage(
        form: true,
        padding: AppInsets.page,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(l10n.inviteAcceptBody, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.inviteAcceptUseInvitedEmail,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            if (auth.isSignedIn && auth.user?.email != null)
              Text(
                l10n.inviteAcceptSignedInAs(auth.user!.email!),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            const SizedBox(height: AppSpacing.lg),
            if (_localError != null || family.errorMessage != null)
              Text(
                _localError ?? family.errorMessage!,
                style: TextStyle(color: theme.colorScheme.error),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: family.busy || _done ? null : _accept,
              child: Text(l10n.inviteAcceptAction),
            ),
          ],
        ),
      ),
    );
  }
}

/// Family management: members + invites (admin copy-link for emulator).
class FamilyManageScreen extends StatefulWidget {
  const FamilyManageScreen({super.key});

  @override
  State<FamilyManageScreen> createState() => _FamilyManageScreenState();
}

class _FamilyManageScreenState extends State<FamilyManageScreen> {
  final _inviteEmail = TextEditingController();

  @override
  void dispose() {
    _inviteEmail.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthController>();
    final familyCtrl = context.watch<FamilyController>();
    final familyId = auth.familyId;
    final theme = Theme.of(context);

    if (familyId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.familyTitle)),
        body: Center(child: Text(l10n.familyMissing)),
      );
    }

    final uid = auth.user?.uid;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.familyTitle)),
      body: AppPage(
        child: ListView(
          padding: AppInsets.pageCompact,
          children: [
            StreamBuilder(
              stream: familyCtrl.watchFamily(familyId),
              builder: (context, snap) {
                final family = snap.data;
                if (family == null) {
                  return const LinearProgressIndicator();
                }
                return ListTile(
                  title: Text(family.name),
                  subtitle: Text('${family.currency} · ${family.timezone}'),
                );
              },
            ),
            const Divider(),
            AppSectionTitle(
              l10n.familyMembers,
              padding: AppInsets.sectionTight,
            ),
            StreamBuilder(
              stream: familyCtrl.watchMembers(familyId),
              builder: (context, snap) {
                final members = snap.data ?? const <FamilyMember>[];
                final me = members.cast<FamilyMember?>().firstWhere(
                  (m) => m?.userId == uid,
                  orElse: () => null,
                );
                final amAdmin = me?.isAdmin ?? false;
                return Column(
                  children: members.map((m) {
                    return ListTile(
                      title: Text(m.displayName),
                      subtitle: Text(m.role),
                      trailing: amAdmin && m.userId != uid
                          ? PopupMenuButton<String>(
                              onSelected: (value) async {
                                try {
                                  if (value == 'admin' || value == 'member') {
                                    await familyCtrl.updateMemberRole(
                                      userId: m.userId,
                                      role: value,
                                    );
                                  } else if (value == 'remove') {
                                    await familyCtrl.removeMember(m.userId);
                                  } else if (value == 'owner') {
                                    await familyCtrl.transferOwnership(
                                      m.userId,
                                    );
                                  }
                                } catch (_) {}
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'admin',
                                  child: Text(l10n.familyMakeAdmin),
                                ),
                                PopupMenuItem(
                                  value: 'member',
                                  child: Text(l10n.familyMakeMember),
                                ),
                                PopupMenuItem(
                                  value: 'owner',
                                  child: Text(l10n.familyTransferOwnership),
                                ),
                                PopupMenuItem(
                                  value: 'remove',
                                  child: Text(l10n.familyRemoveMember),
                                ),
                              ],
                            )
                          : null,
                    );
                  }).toList(),
                );
              },
            ),
            const Divider(),
            AppSectionTitle(
              l10n.familyInvites,
              padding: AppInsets.sectionTight,
            ),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _inviteEmail,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: l10n.familyInviteEmail,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: familyCtrl.busy
                      ? null
                      : () async {
                          try {
                            final invite = await familyCtrl.createInvite(
                              _inviteEmail.text.trim(),
                            );
                            _inviteEmail.clear();
                            if (!context.mounted) return;
                            final link =
                                invite.inviteLink ??
                                inviteUrlForToken(invite.token);
                            await Clipboard.setData(ClipboardData(text: link));
                            if (!context.mounted) return;
                            final msg = invite.emailQueued
                                ? l10n.familyInviteEmailSent
                                : l10n.familyInviteCreatedCopyLink;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(msg)),
                            );
                          } catch (_) {}
                        },
                ),
              ),
            ),
            if (familyCtrl.lastCreatedInvite != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Card(
                child: ListTile(
                  title: Text(l10n.familyInviteLinkHint),
                  subtitle: SelectableText(
                    familyCtrl.lastCreatedInvite!.inviteLink ??
                        inviteUrlForToken(
                          familyCtrl.lastCreatedInvite!.token,
                        ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () async {
                      final inv = familyCtrl.lastCreatedInvite!;
                      final link =
                          inv.inviteLink ?? inviteUrlForToken(inv.token);
                      await Clipboard.setData(ClipboardData(text: link));
                    },
                  ),
                ),
              ),
            ],
            StreamBuilder(
              stream: familyCtrl.watchPendingInvites(familyId),
              builder: (context, snap) {
                final invites = snap.data ?? const <FamilyInvite>[];
                return Column(
                  children: invites
                      .map(
                        (i) => ListTile(
                          title: Text(i.invitedEmail),
                          subtitle: Text(i.status),
                          trailing: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => familyCtrl.revokeInvite(i.id),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(
              onPressed: familyCtrl.busy
                  ? null
                  : () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(l10n.familyLeaveTitle),
                          content: Text(l10n.familyLeaveBody),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(l10n.actionCancel),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(l10n.familyLeaveAction),
                            ),
                          ],
                        ),
                      );
                      if (ok == true) {
                        try {
                          await familyCtrl.leaveFamily();
                          if (context.mounted) {
                            context.go(AppRoutes.onboardingFamily);
                          }
                        } catch (_) {}
                      }
                    },
              child: Text(l10n.familyLeaveAction),
            ),
            if (familyCtrl.errorMessage != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                familyCtrl.errorMessage!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
