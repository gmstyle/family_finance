import 'package:cloud_firestore/cloud_firestore.dart';

/// Category types — immutable after create.
enum CategoryType {
  expense,
  income;

  static CategoryType fromString(String raw) {
    return CategoryType.values.firstWhere(
      (t) => t.name == raw,
      orElse: () => CategoryType.expense,
    );
  }
}

class Category {
  const Category({
    required this.id,
    required this.type,
    required this.archived,
    this.nameKey,
    this.name,
    this.icon,
    this.color,
  });

  final String id;
  final CategoryType type;
  final bool archived;
  final String? nameKey;
  final String? name;
  final String? icon;
  final String? color;

  bool get isSystem => nameKey != null && nameKey!.isNotEmpty;

  factory Category.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return Category(
      id: doc.id,
      type: CategoryType.fromString(d['type'] as String? ?? 'expense'),
      archived: d['archived'] as bool? ?? false,
      nameKey: d['nameKey'] as String?,
      name: d['name'] as String?,
      icon: d['icon'] as String?,
      color: d['color'] as String?,
    );
  }
}

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
