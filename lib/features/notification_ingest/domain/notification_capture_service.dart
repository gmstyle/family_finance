import 'captured_notification.dart';

/// Android notification-listener capture capability.
///
/// Android provides a real implementation; other platforms use a no-op stub.
/// Screens must branch on [isCaptureSupported] — never on `kIsWeb`.
abstract class NotificationCaptureService {
  /// Whether this platform can capture payment notifications.
  bool get isCaptureSupported;

  /// Whether the system notification-listener permission is granted.
  Future<bool> isListenerEnabled();

  /// Opens the system screen where the user enables this app as a listener.
  Future<void> openListenerSettings();

  /// Pushes the Remote Config package allowlist to the native filter.
  Future<void> setAllowedPackages(List<String> packages);

  /// Stream of structured notification events (package/title/text/postTime).
  Stream<CapturedNotification> get notifications;

  /// Releases subscriptions (no-op for stubs).
  Future<void> dispose();
}
