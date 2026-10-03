import '../domain/notification_capture_service.dart';
import 'notification_capture_factory_stub.dart'
    if (dart.library.io) 'notification_capture_factory_io.dart'
    as impl;

/// Platform-selected notification capture (Android listener, stub elsewhere).
NotificationCaptureService createNotificationCaptureService() =>
    impl.createNotificationCaptureService();
