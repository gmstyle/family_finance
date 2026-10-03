import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/category.dart';

/// Firestore reads + custom category create / archive.
class CategoriesRepository {
  CategoriesRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _col(String familyId) =>
      _firestore.collection('families').doc(familyId).collection('categories');

  Stream<List<Category>> watchCategories(
    String familyId, {
    bool includeArchived = false,
    CategoryType? type,
  }) {
    return _col(familyId).snapshots().map((snap) {
      var list = snap.docs.map(Category.fromDoc).toList();
      if (!includeArchived) {
        list = list.where((c) => !c.archived).toList();
      }
      if (type != null) {
        list = list.where((c) => c.type == type).toList();
      }
      list.sort((a, b) {
        final aSys = a.isSystem ? 0 : 1;
        final bSys = b.isSystem ? 0 : 1;
        if (aSys != bSys) return aSys - bSys;
        final aLabel = a.nameKey ?? a.name ?? '';
        final bLabel = b.nameKey ?? b.name ?? '';
        return aLabel.compareTo(bLabel);
      });
      return list;
    });
  }

  Future<String> createCustomCategory({
    required String familyId,
    required String name,
    required CategoryType type,
    String? icon,
    String? color,
  }) async {
    final ref = _col(familyId).doc();
    await ref.set({
      'name': name.trim(),
      'type': type.name,
      'icon': icon ?? 'label',
      'color': color ?? '#607D8B',
      'archived': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> archiveCategory({
    required String familyId,
    required String categoryId,
    bool archived = true,
  }) {
    return _col(familyId).doc(categoryId).update({
      'archived': archived,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
