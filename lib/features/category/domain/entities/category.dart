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

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    this.isSystem = false,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        icon,
        color,
        type,
        isSystem,
      ];

  Category copyWith({
    String? id,
    String? name,
    int? icon,
    int? color,
    CategoryType? type,
    bool? isSystem,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      type: type ?? this.type,
      isSystem: isSystem ?? this.isSystem,
    );
  }
}
