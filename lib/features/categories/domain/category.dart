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
