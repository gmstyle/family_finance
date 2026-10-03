import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Shows aggregated local notifications for pending ingestion drafts.
///
/// Prefer local notifications over FCM so emulator/dev works without push.
class DraftAlertNotifications {
  DraftAlertNotifications({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  static const _channelId = 'ingestion_drafts';
  static const _notificationId = 61001;

  /// Optional tap handler (e.g. navigate to `/ingestion`).
  void Function()? onOpenInbox;

  Future<void> initialize() async {
    if (_ready) return;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      _ready = true;
      return;
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        onOpenInbox?.call();
      },
    );

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        'Review queue',
        description: 'Alerts when payment notification drafts need review',
        importance: Importance.defaultImportance,
      ),
    );
    _ready = true;
  }

  /// Shows or updates an aggregated “N drafts to review” notification.
  Future<void> showPendingDraftCount({
    required int count,
    required String title,
    required String body,
  }) async {
    if (!_ready) await initialize();
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    if (count <= 0) {
      await cancel();
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      'Review queue',
      channelDescription: 'Alerts when payment notification drafts need review',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      number: count,
      styleInformation: BigTextStyleInformation(body),
    );

    await _plugin.show(
      id: _notificationId,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(android: androidDetails),
      payload: 'ingestion',
    );
  }

  Future<void> cancel() async {
    if (!_ready) return;
    await _plugin.cancel(id: _notificationId);
  }
}
