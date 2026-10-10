import 'package:flutter/foundation.dart';

import '../../features/auth/presentation/auth_controller.dart';

/// Reads `/invite/<token>` from the browser address bar (web deep links).
void bootstrapInviteFromBrowserUrl(AuthController auth) {
  if (!kIsWeb) return;
  final path = Uri.base.path;
  final match = RegExp(r'^/invite/([^/]+)/?$').firstMatch(path);
  if (match == null) return;
  final token = Uri.decodeComponent(match.group(1)!);
  if (token.isEmpty) return;
  auth.restorePendingInviteFromToken(token);
}
