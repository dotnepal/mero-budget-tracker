import 'package:equatable/equatable.dart';

enum CategoryType {
  income,
  expense,
}

class Category extends Equatable {
  final String id;
  final String name;
  final int icon;
  final int color;
  final CategoryType type;
  final bool isSystem;
  // Budget bucket: 'NEEDS', 'WANTS', 'SAVINGS', or null for income/unassigned
  final String? budgetBucket;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    this.isSystem = false,
    this.budgetBucket,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        icon,
        color,
        type,
        isSystem,
        budgetBucket,
      ];

  Category copyWith({
    String? id,
    String? name,
    int? icon,
    int? color,
    CategoryType? type,
    bool? isSystem,
    String? budgetBucket,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      type: type ?? this.type,
      isSystem: isSystem ?? this.isSystem,
      budgetBucket: budgetBucket ?? this.budgetBucket,
    );
  }
}
