import 'package:equatable/equatable.dart';

class FinancialSummary extends Equatable {
  final double totalIncome;
  final double totalExpenses;
  final double netBalance;
  final DateTime startDate;
  final DateTime endDate;

  const FinancialSummary({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netBalance,
    required this.startDate,
    required this.endDate,
  });

  double get incomePercentage {
    final total = totalIncome + totalExpenses;
    if (total == 0) return 0;
    return totalIncome / total * 100;
  }

  double get expensePercentage {
    final total = totalIncome + totalExpenses;
    if (total == 0) return 0;
    return totalExpenses / total * 100;
  }

  bool get hasData => totalIncome > 0 || totalExpenses > 0;

  @override
  List<Object?> get props => [
        totalIncome,
        totalExpenses,
        netBalance,
        startDate,
        endDate,
      ];

  FinancialSummary copyWith({
    double? totalIncome,
    double? totalExpenses,
    double? netBalance,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return FinancialSummary(
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      netBalance: netBalance ?? this.netBalance,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}
