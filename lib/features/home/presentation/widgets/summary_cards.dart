import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/monthly_summary.dart';
import 'month_selector.dart';
import 'income_card.dart';
import 'expense_card.dart';

class SummaryCards extends StatelessWidget {
  final MonthlySummary summary;
  final Function(DateTime) onMonthChanged;

  const SummaryCards({
    super.key,
    required this.summary,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          MonthSelector(
            selectedMonth: summary.month,
            onMonthChanged: onMonthChanged,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: IncomeCard(
                  amount: summary.totalIncome,
                  transactionCount: summary.incomeTransactionCount,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ExpenseCard(
                  amount: summary.totalExpenses,
                  transactionCount: summary.expenseTransactionCount,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
