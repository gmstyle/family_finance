import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as google_sign_in_web;

/// Official GIS button required on web (authenticate() is unsupported).
Widget? buildGoogleGisSignInButton({Key? key}) {
  return KeyedSubtree(key: key, child: google_sign_in_web.renderButton());
}
