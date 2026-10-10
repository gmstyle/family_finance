import 'package:flutter/foundation.dart';

/// Production HTTPS origin for universal invite links (web + Android App Links).
const String kInviteLinkHost = 'family-finance-gmstyle-app.web.app';

const String _productionInviteBaseUrl = 'https://$kInviteLinkHost';

/// Invite URL for sharing. Uses [Uri.base] on local dev; production host in release.
String inviteUrlForToken(String token) {
  final trimmed = token.trim();
  if (trimmed.isEmpty) return _productionInviteBaseUrl;

  if (kDebugMode) {
    final host = Uri.base.host;
    if (host == 'localhost' || host == '127.0.0.1') {
      return Uri.base.replace(path: '/invite/$trimmed', query: '').toString();
    }
  }

  return '$_productionInviteBaseUrl/invite/$trimmed';
}
