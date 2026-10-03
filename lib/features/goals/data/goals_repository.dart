import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../ledger/ledger_labels.dart';

/// Goal document. [accumulatedAmountMinor] is function-derived.
class Goal {
  const Goal({
    required this.id,
    required this.name,
    required this.targetAmountMinor,
    required this.accumulatedAmountMinor,
    this.dueDate,
  });

  final String id;
  final String name;
  final int targetAmountMinor;
  final int accumulatedAmountMinor;
  final String? dueDate;

  double get progress {
    if (targetAmountMinor <= 0) return 0;
    return (accumulatedAmountMinor / targetAmountMinor).clamp(0.0, 1.0);
  }

  factory Goal.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return Goal(
      id: doc.id,
      name: d['name'] as String? ?? '',
      targetAmountMinor: (d['targetAmountMinor'] as num?)?.toInt() ?? 0,
      accumulatedAmountMinor:
          (d['accumulatedAmountMinor'] as num?)?.toInt() ?? 0,
      dueDate: d['dueDate'] as String?,
    );
  }
}

/// Virtual contribution — positive = deposit, negative = withdraw.
class GoalContribution {
  const GoalContribution({
    required this.id,
    required this.amountMinor,
    required this.bookingDate,
    required this.createdByUserId,
  });

  final String id;
  final int amountMinor;
  final String bookingDate;
  final String createdByUserId;

  bool get isDeposit => amountMinor > 0;

  factory GoalContribution.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return GoalContribution(
      id: doc.id,
      amountMinor: (d['amountMinor'] as num?)?.toInt() ?? 0,
      bookingDate: d['bookingDate'] as String? ?? '',
      createdByUserId: d['createdByUserId'] as String? ?? '',
    );
  }
}

/// Firestore CRUD for goals + contribution subcollection writes.
class GoalsRepository {
  GoalsRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> _col(String familyId) =>
      _firestore.collection('families').doc(familyId).collection('goals');

  Stream<List<Goal>> watchGoals(String familyId) {
    return _col(familyId).snapshots().map((snap) {
      final list = snap.docs.map(Goal.fromDoc).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    });
  }

  Stream<Goal?> watchGoal(String familyId, String goalId) {
    return _col(familyId).doc(goalId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Goal.fromDoc(doc);
    });
  }

  Stream<List<GoalContribution>> watchContributions(
    String familyId,
    String goalId,
  ) {
    return _col(familyId)
        .doc(goalId)
        .collection('contributions')
        .orderBy('bookingDate', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(GoalContribution.fromDoc).toList());
  }

  Future<Goal?> getGoal(String familyId, String goalId) async {
    final doc = await _col(familyId).doc(goalId).get();
    if (!doc.exists) return null;
    return Goal.fromDoc(doc);
  }

  Future<String> createGoal({
    required String familyId,
    required String name,
    required int targetAmountMinor,
    String? dueDate,
  }) async {
    final ref = _col(familyId).doc();
    final data = <String, dynamic>{
      'name': name.trim(),
      'targetAmountMinor': targetAmountMinor,
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (dueDate != null && dueDate.isNotEmpty) {
      data['dueDate'] = dueDate;
    }
    await ref.set(data);
    return ref.id;
  }

  Future<void> updateGoal({
    required String familyId,
    required String goalId,
    required String name,
    required int targetAmountMinor,
    String? dueDate,
  }) {
    final data = <String, dynamic>{
      'name': name.trim(),
      'targetAmountMinor': targetAmountMinor,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (dueDate != null && dueDate.isNotEmpty) {
      data['dueDate'] = dueDate;
    } else {
      data['dueDate'] = FieldValue.delete();
    }
    return _col(familyId).doc(goalId).update(data);
  }

  Future<void> deleteGoal({required String familyId, required String goalId}) {
    return _col(familyId).doc(goalId).delete();
  }

  /// Writes a contribution; function updates [Goal.accumulatedAmountMinor].
  Future<String> addContribution({
    required String familyId,
    required String goalId,
    required int amountMinor,
    String? bookingDate,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('Sign in required to contribute to a goal.');
    }
    if (amountMinor == 0) {
      throw ArgumentError.value(amountMinor, 'amountMinor', 'must be non-zero');
    }
    final ref = _col(familyId).doc(goalId).collection('contributions').doc();
    await ref.set({
      'amountMinor': amountMinor,
      'bookingDate': bookingDate ?? formatBookingDate(DateTime.now()),
      'createdByUserId': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }
}
