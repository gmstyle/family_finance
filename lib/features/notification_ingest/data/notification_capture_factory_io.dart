import 'dart:io' show Platform;

import '../domain/notification_capture_service.dart';
import 'notification_capture_service_android.dart';
import 'notification_capture_service_stub.dart';

NotificationCaptureService createNotificationCaptureService() {
  if (Platform.isAndroid) {
    return AndroidNotificationCaptureService();
  }
  return StubNotificationCaptureService();
}
