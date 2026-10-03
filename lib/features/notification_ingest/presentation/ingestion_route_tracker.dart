import 'package:flutter/foundation.dart';

/// Tracks whether the user is currently on the ingestion inbox/detail route.
///
/// Used to suppress local draft alerts while reviewing the queue.
class IngestionRouteTracker extends ChangeNotifier {
  bool _onIngestionRoute = false;

  bool get isOnIngestionRoute => _onIngestionRoute;

  /// Updates from a GoRouter matched location (e.g. `/ingestion` or
  /// `/ingestion/abc`).
  void updateFromLocation(String matchedLocation) {
    final on =
        matchedLocation == '/ingestion' ||
        matchedLocation.startsWith('/ingestion/');
    if (on == _onIngestionRoute) return;
    _onIngestionRoute = on;
    notifyListeners();
  }
}
