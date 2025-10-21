import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/financial_summary.dart';

class FinancialSummaryCards extends StatelessWidget {
  final FinancialSummary summary;

  const FinancialSummaryCards({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            context: context,
            title: 'Income',
            amount: summary.totalIncome,
            color: Colors.green,
            icon: Icons.trending_up,
            formatter: currencyFormat,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            context: context,
            title: 'Expenses',
            amount: summary.totalExpenses,
            color: Colors.red,
            icon: Icons.trending_down,
            formatter: currencyFormat,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            context: context,
            title: 'Balance',
            amount: summary.netBalance,
            color: summary.netBalance >= 0 ? Colors.green : Colors.red,
            icon: summary.netBalance >= 0 ? Icons.account_balance_wallet : Icons.warning,
            formatter: currencyFormat,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required BuildContext context,
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
    required NumberFormat formatter,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              formatter.format(amount),
              style: theme.textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
