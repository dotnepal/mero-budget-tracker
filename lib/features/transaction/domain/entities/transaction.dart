import 'package:equatable/equatable.dart';

enum TransactionType {
  income,
  expense,
}

class Transaction extends Equatable {
  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final String? category;
  final String? note;

  const Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.type,
    this.category,
    this.note,
  });

  @override
  List<Object?> get props => [
        id,
        description,
        amount,
        date,
        type,
        category,
        note,
      ];

  Transaction copyWith({
    String? id,
    String? description,
    double? amount,
    DateTime? date,
    TransactionType? type,
    String? category,
    String? note,
  }) {
    return Transaction(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      type: type ?? this.type,
      category: category ?? this.category,
      note: note ?? this.note,
    );
  }
}