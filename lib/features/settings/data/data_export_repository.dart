import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';

/// Builds a member-readable JSON export and shares / saves it.
class DataExportRepository {
  DataExportRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const int _pageSize = 300;

  Future<void> exportAndShare({required String? familyId}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('Sign in required to export data.');
    }

    final payload = <String, Object?>{
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'schemaVersion': 1,
      'user': await _exportUserProfile(uid),
    };

    if (familyId != null && familyId.isNotEmpty) {
      payload['family'] = await _exportFamily(familyId);
    }

    final json = const JsonEncoder.withIndent('  ').convert(payload);
    final stamp = DateTime.now()
        .toUtc()
        .toIso8601String()
        .replaceAll(':', '')
        .replaceAll('-', '')
        .split('.')
        .first;
    final fileName = 'family-finance-export-$stamp.json';
    final bytes = utf8.encode(json);

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            bytes,
            mimeType: 'application/json',
            name: fileName,
          ),
        ],
        subject: fileName,
        title: fileName,
      ),
    );
  }

  Future<Map<String, Object?>> _exportUserProfile(String uid) async {
    final snap = await _firestore.collection('users').doc(uid).get();
    final data = snap.data() ?? <String, dynamic>{};
    return {
      'id': uid,
      'email': data['email'],
      'displayName': data['displayName'],
      'familyId': data['familyId'],
      // Intentionally omit devices / FCM tokens.
    };
  }

  Future<Map<String, Object?>> _exportFamily(String familyId) async {
    final familyRef = _firestore.collection('families').doc(familyId);
    final familySnap = await familyRef.get();
    final familyData = _serializeDoc(familySnap.data());

    final members = await _readCollection(familyRef.collection('members'));
    final accounts = await _readCollection(familyRef.collection('accounts'));
    final categories = await _readCollection(familyRef.collection('categories'));
    final transactions = await _readCollection(
      familyRef.collection('transactions'),
    );
    final stats = await _readCollection(familyRef.collection('stats'));
    final ingestion = await _readCollection(familyRef.collection('ingestion'));
    final merchantRules = await _readCollection(
      familyRef.collection('merchantRules'),
    );
    final accountBindings = await _readCollection(
      familyRef.collection('accountBindings'),
    );

    final budgetsRaw = await _readCollection(familyRef.collection('budgets'));
    final budgets = <Map<String, Object?>>[];
    for (final b in budgetsRaw) {
      final id = b['id'] as String?;
      if (id == null) continue;
      final periods = await _readCollection(
        familyRef.collection('budgets').doc(id).collection('periods'),
      );
      budgets.add({...b, 'periods': periods});
    }

    final goalsRaw = await _readCollection(familyRef.collection('goals'));
    final goals = <Map<String, Object?>>[];
    for (final g in goalsRaw) {
      final id = g['id'] as String?;
      if (id == null) continue;
      final contributions = await _readCollection(
        familyRef.collection('goals').doc(id).collection('contributions'),
      );
      goals.add({...g, 'contributions': contributions});
    }

    return {
      'id': familyId,
      'document': familyData,
      'members': members,
      'accounts': accounts,
      'categories': categories,
      'transactions': transactions,
      'budgets': budgets,
      'goals': goals,
      'stats': stats,
      'ingestion': ingestion,
      'merchantRules': merchantRules,
      'accountBindings': accountBindings,
    };
  }

  Future<List<Map<String, Object?>>> _readCollection(
    CollectionReference<Map<String, dynamic>> col,
  ) async {
    final out = <Map<String, Object?>>[];
    QueryDocumentSnapshot<Map<String, dynamic>>? last;
    while (true) {
      Query<Map<String, dynamic>> q = col.orderBy(FieldPath.documentId).limit(
        _pageSize,
      );
      if (last != null) {
        q = q.startAfterDocument(last);
      }
      final snap = await q.get();
      if (snap.docs.isEmpty) break;
      for (final doc in snap.docs) {
        out.add({'id': doc.id, ..._serializeDoc(doc.data())});
      }
      if (snap.docs.length < _pageSize) break;
      last = snap.docs.last;
    }
    return out;
  }

  Map<String, Object?> _serializeDoc(Map<String, dynamic>? data) {
    if (data == null) return {};
    final out = <String, Object?>{};
    data.forEach((key, value) {
      out[key] = _serializeValue(value);
    });
    return out;
  }

  Object? _serializeValue(Object? value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate().toUtc().toIso8601String();
    if (value is GeoPoint) {
      return {'latitude': value.latitude, 'longitude': value.longitude};
    }
    if (value is DocumentReference) return value.path;
    if (value is Map) {
      return {
        for (final e in value.entries)
          e.key.toString(): _serializeValue(e.value),
      };
    }
    if (value is Iterable && value is! String) {
      return [for (final v in value) _serializeValue(v)];
    }
    if (value is num || value is bool || value is String) return value;
    return value.toString();
  }
}
