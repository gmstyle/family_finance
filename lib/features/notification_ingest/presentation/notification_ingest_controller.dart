import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../auth/presentation/auth_controller.dart';
import '../../receipt_ocr/data/ingestion_repository.dart';
import '../data/draft_alert_notifications.dart';
import '../data/notification_remote_config.dart';
import '../domain/bank_notification_parser.dart';
import '../domain/captured_notification.dart';
import '../domain/notification_capture_service.dart';
import 'ingestion_route_tracker.dart';

/// Bootstraps Android notification capture → Ingestion drafts → local alerts.
///
/// Never creates ledger transactions — only drafts via [IngestionRepository].
class NotificationIngestController {
  NotificationIngestController({
    required this.auth,
    required this.ingestion,
    required this.capture,
    required this.routeTracker,
    NotificationRemoteConfig? remoteConfig,
    DraftAlertNotifications? alerts,
    FirebaseAuth? firebaseAuth,
  }) : _remoteConfig = remoteConfig ?? NotificationRemoteConfig(),
       _alerts = alerts ?? DraftAlertNotifications(),
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final AuthController auth;
  final IngestionRepository ingestion;
  final NotificationCaptureService capture;
  final IngestionRouteTracker routeTracker;
  final NotificationRemoteConfig _remoteConfig;
  final DraftAlertNotifications _alerts;
  final FirebaseAuth _firebaseAuth;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<dynamic>? _notifSub;
  StreamSubscription<List<IngestionDraft>>? _queueSub;
  VoidCallback? _authListener;
  VoidCallback? _routeListener;

  NotificationIngestConfig _config = NotificationIngestConfig.defaults();
  BankNotificationParser _parser = BankNotificationParser();
  bool _started = false;
  int _lastAlertedPending = -1;

  /// Localized strings for the aggregated alert (set from UI / main).
  String Function(int count)? titleForCount;
  String Function(int count)? bodyForCount;
  void Function()? onOpenInbox;

  /// Call once from app bootstrap. No-op when capture is unsupported.
  void start() {
    if (_started) return;
    _started = true;

    if (!capture.isCaptureSupported) return;

    _alerts.onOpenInbox = () => onOpenInbox?.call();
    unawaited(_alerts.initialize());

    _authListener = () => unawaited(_syncSession());
    auth.addListener(_authListener!);

    _routeListener = () {
      if (routeTracker.isOnIngestionRoute) {
        unawaited(_alerts.cancel());
      }
    };
    routeTracker.addListener(_routeListener!);

    _authSub = _firebaseAuth.authStateChanges().listen((_) {
      unawaited(_syncSession());
    });
    unawaited(_syncSession());
  }

  Future<void> _syncSession() async {
    final uid = _firebaseAuth.currentUser?.uid;
    final familyId = auth.familyId;
    if (uid == null || familyId == null || familyId.isEmpty) {
      await _stopListening();
      return;
    }
    await _startListening(familyId);
  }

  Future<void> _startListening(String familyId) async {
    await _stopListening(keepAlerts: true);

    try {
      _config = await _remoteConfig.load();
      _parser = BankNotificationParser(patterns: _config.patterns);
      await capture.setAllowedPackages(_config.allowedPackages);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Notification ingest config failed: $e');
      }
      _config = NotificationIngestConfig.defaults();
      _parser = BankNotificationParser(patterns: _config.patterns);
    }

    _notifSub = capture.notifications.listen((captured) {
      unawaited(_handleCaptured(familyId, captured));
    });

    _queueSub = ingestion.watchPendingQueue(familyId).listen((drafts) {
      unawaited(_maybeAlert(drafts.length));
    });
  }

  Future<void> _handleCaptured(
    String familyId,
    CapturedNotification captured,
  ) async {
    try {
      if (!_config.allowedPackages.contains(captured.packageName)) {
        return;
      }
      final parsed = _parser.parse(captured);
      if (!parsed.hasAnyField) {
        if (kDebugMode) {
          debugPrint(
            'Notification parse produced no fields '
            '(package=${captured.packageName})',
          );
        }
        return;
      }

      final result = await ingestion.createDraftFromNotification(
        familyId: familyId,
        parsed: parsed,
      );

      if (kDebugMode) {
        debugPrint(
          'Notification draft ${result.created ? 'created' : 'exists'}: '
          '${result.dedupKey} status=${result.status.name}',
        );
      }

      // Fresh drafts bump the pending queue stream → aggregated alert.
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Notification draft create failed: $e\n$st');
      }
    }
  }

  Future<void> _maybeAlert(int pendingCount) async {
    if (routeTracker.isOnIngestionRoute) {
      await _alerts.cancel();
      _lastAlertedPending = pendingCount;
      return;
    }
    if (pendingCount <= 0) {
      await _alerts.cancel();
      _lastAlertedPending = 0;
      return;
    }
    if (pendingCount == _lastAlertedPending) return;
    _lastAlertedPending = pendingCount;

    final title =
        titleForCount?.call(pendingCount) ?? '$pendingCount drafts to review';
    final body =
        bodyForCount?.call(pendingCount) ??
        'Open the review queue to confirm or discard.';
    await _alerts.showPendingDraftCount(
      count: pendingCount,
      title: title,
      body: body,
    );
  }

  Future<void> _stopListening({bool keepAlerts = false}) async {
    await _notifSub?.cancel();
    _notifSub = null;
    await _queueSub?.cancel();
    _queueSub = null;
    if (!keepAlerts) {
      await _alerts.cancel();
      _lastAlertedPending = -1;
    }
  }

  /// Refreshes listener-enabled state for settings UI.
  Future<bool> isListenerEnabled() => capture.isListenerEnabled();

  Future<void> openListenerSettings() => capture.openListenerSettings();

  bool get isCaptureSupported => capture.isCaptureSupported;

  List<String> get allowedPackages => _config.allowedPackages;

  Future<void> dispose() async {
    if (_authListener != null) {
      auth.removeListener(_authListener!);
      _authListener = null;
    }
    if (_routeListener != null) {
      routeTracker.removeListener(_routeListener!);
      _routeListener = null;
    }
    await _authSub?.cancel();
    await _stopListening();
    await capture.dispose();
    _started = false;
  }
}
