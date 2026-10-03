import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/captured_notification.dart';
import '../domain/notification_capture_service.dart';

/// Android MethodChannel / EventChannel bridge to [NotificationListenerService].
class AndroidNotificationCaptureService implements NotificationCaptureService {
  AndroidNotificationCaptureService({
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
  }) : _methods =
           methodChannel ??
           const MethodChannel(
             'com.gmstyle.family_finance/notification_listener',
           ),
       _events =
           eventChannel ??
           const EventChannel('com.gmstyle.family_finance/notification_events');

  final MethodChannel _methods;
  final EventChannel _events;
  StreamSubscription<dynamic>? _sub;
  final _controller = StreamController<CapturedNotification>.broadcast();

  bool _listening = false;

  @override
  bool get isCaptureSupported => true;

  @override
  Future<bool> isListenerEnabled() async {
    try {
      final result = await _methods.invokeMethod<bool>('isListenerEnabled');
      return result ?? false;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('isListenerEnabled failed: $e');
      }
      return false;
    }
  }

  @override
  Future<void> openListenerSettings() async {
    await _methods.invokeMethod<void>('openListenerSettings');
  }

  @override
  Future<void> setAllowedPackages(List<String> packages) async {
    await _methods.invokeMethod<void>('setAllowedPackages', packages);
  }

  @override
  Stream<CapturedNotification> get notifications {
    _ensureListening();
    return _controller.stream;
  }

  void _ensureListening() {
    if (_listening) return;
    _listening = true;
    _sub = _events.receiveBroadcastStream().listen(
      (event) {
        if (event is Map) {
          final captured = CapturedNotification.fromMap(event);
          if (captured.packageName.isEmpty) return;
          if (!_controller.isClosed) {
            _controller.add(captured);
          }
        }
      },
      onError: (Object e, StackTrace st) {
        if (kDebugMode) {
          debugPrint('Notification event error: $e');
        }
      },
    );
  }

  @override
  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    _listening = false;
    await _controller.close();
  }
}
