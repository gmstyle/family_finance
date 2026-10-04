import 'package:flutter/foundation.dart';

import '../data/account_lifecycle_repository.dart';
import '../data/data_export_repository.dart';

/// Settings privacy/data orchestration — screens never touch repositories.
class SettingsController extends ChangeNotifier {
  SettingsController({
    AccountLifecycleRepository? accountLifecycle,
    DataExportRepository? dataExport,
  }) : _lifecycle = accountLifecycle ?? AccountLifecycleRepository(),
       _export = dataExport ?? DataExportRepository();

  final AccountLifecycleRepository _lifecycle;
  final DataExportRepository _export;

  bool _exportBusy = false;
  bool _deleteBusy = false;
  String? _errorMessage;

  bool get exportBusy => _exportBusy;
  bool get deleteBusy => _deleteBusy;
  bool get busy => _exportBusy || _deleteBusy;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> isSoleFamilyMember(String? familyId) {
    return _lifecycle.isSoleFamilyMember(familyId);
  }

  Future<void> exportAndShare({required String? familyId}) async {
    _exportBusy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _export.exportAndShare(familyId: familyId);
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _exportBusy = false;
      notifyListeners();
    }
  }

  Future<void> deleteAccount({required bool confirmFamilyWipe}) async {
    _deleteBusy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _lifecycle.deleteAccount(confirmFamilyWipe: confirmFamilyWipe);
    } on FirebaseFunctionsException catch (e) {
      _errorMessage = e.message ?? e.code;
      rethrow;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _deleteBusy = false;
      notifyListeners();
    }
  }
}
