import 'package:equatable/equatable.dart';

class MonthlySummary extends Equatable {
  final double totalIncome;
  final double totalExpenses;
  final double netBalance;
  final DateTime month;
  final int transactionCount;
  final int incomeTransactionCount;
  final int expenseTransactionCount;

  const MonthlySummary({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netBalance,
    required this.month,
    required this.transactionCount,
    required this.incomeTransactionCount,
    required this.expenseTransactionCount,
  });

  double get savingsRate => totalIncome > 0
      ? ((totalIncome - totalExpenses) / totalIncome) * 100
      : 0;

  bool get hasData => totalIncome > 0 || totalExpenses > 0;

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

  @override
  List<Object?> get props => [
        totalIncome,
        totalExpenses,
        netBalance,
        month,
        transactionCount,
        incomeTransactionCount,
        expenseTransactionCount,
      ];

  MonthlySummary copyWith({
    double? totalIncome,
    double? totalExpenses,
    double? netBalance,
    DateTime? month,
    int? transactionCount,
    int? incomeTransactionCount,
    int? expenseTransactionCount,
  }) {
    return MonthlySummary(
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      netBalance: netBalance ?? this.netBalance,
      month: month ?? this.month,
      transactionCount: transactionCount ?? this.transactionCount,
      incomeTransactionCount: incomeTransactionCount ?? this.incomeTransactionCount,
      expenseTransactionCount: expenseTransactionCount ?? this.expenseTransactionCount,
    );
  }
}
