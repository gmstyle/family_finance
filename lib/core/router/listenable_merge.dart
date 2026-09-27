import 'package:flutter/foundation.dart';

/// Notifies when any of [listenables] notifies.
class ListenableMerge extends ChangeNotifier {
  ListenableMerge(List<Listenable> listenables) : _listenables = listenables {
    for (final l in _listenables) {
      l.addListener(_onChange);
    }
  }

  final List<Listenable> _listenables;

  void _onChange() => notifyListeners();

  @override
  void dispose() {
    for (final l in _listenables) {
      l.removeListener(_onChange);
    }
    super.dispose();
  }
}
