import '../domain/captured_notification.dart';
import '../domain/notification_capture_service.dart';

/// No-op capture for web / non-Android — review queue still works.
class StubNotificationCaptureService implements NotificationCaptureService {
  @override
  bool get isCaptureSupported => false;

  @override
  Future<bool> isListenerEnabled() async => false;

  @override
  Future<void> openListenerSettings() async {}

  @override
  Future<void> setAllowedPackages(List<String> packages) async {}

  @override
  Stream<CapturedNotification> get notifications => const Stream.empty();

  @override
  Future<void> dispose() async {}
}
