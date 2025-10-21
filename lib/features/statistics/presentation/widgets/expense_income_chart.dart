import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/financial_summary.dart';

class ExpenseIncomeChart extends StatefulWidget {
  final FinancialSummary summary;

  const ExpenseIncomeChart({
    super.key,
    required this.summary,
  });

  @override
  State<ExpenseIncomeChart> createState() => _ExpenseIncomeChartState();
}

class _ExpenseIncomeChartState extends State<ExpenseIncomeChart> {
  int touchedIndex = -1;
  final currencyFormat = NumberFormat.currency(symbol: '\$');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!widget.summary.hasData) {
      return _buildEmptyChart(theme);
    }

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1.3,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      touchedIndex = -1;
                      return;
                    }
                    touchedIndex = pieTouchResponse
                        .touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 4,
              centerSpaceRadius: 50,
              sections: _showingSections(),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildLegend(theme),
      ],
    );
  }

  Widget _buildEmptyChart(ThemeData theme) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1.3,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.pie_chart_outline,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No data to display',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildEmptyLegend(theme),
      ],
    );
  }

  List<PieChartSectionData> _showingSections() {
    final total = widget.summary.totalIncome + widget.summary.totalExpenses;
    if (total == 0) return [];

    return List.generate(2, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 16.0 : 14.0;
      final radius = isTouched ? 65.0 : 55.0;

      switch (i) {
        case 0: // Income
          return PieChartSectionData(
            color: Colors.green,
            value: widget.summary.totalIncome,
            title: widget.summary.totalIncome > 0
                ? '${widget.summary.incomePercentage.toStringAsFixed(1)}%'
                : '',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.3),
                  offset: const Offset(1, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          );
        case 1: // Expenses
          return PieChartSectionData(
            color: Colors.red,
            value: widget.summary.totalExpenses,
            title: widget.summary.totalExpenses > 0
                ? '${widget.summary.expensePercentage.toStringAsFixed(1)}%'
                : '',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.3),
                  offset: const Offset(1, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          );
        default:
          throw Error();
      }
    });
  }

  Widget _buildLegend(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLegendItem(
          theme: theme,
          color: Colors.green,
          label: 'Income',
          amount: widget.summary.totalIncome,
          percentage: widget.summary.incomePercentage,
          isHighlighted: touchedIndex == 0,
        ),
        _buildLegendItem(
          theme: theme,
          color: Colors.red,
          label: 'Expenses',
          amount: widget.summary.totalExpenses,
          percentage: widget.summary.expensePercentage,
          isHighlighted: touchedIndex == 1,
        ),
      ],
    );
  }

  Widget _buildEmptyLegend(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLegendItem(
          theme: theme,
          color: Colors.green,
          label: 'Income',
          amount: 0,
          percentage: 0,
          isHighlighted: false,
        ),
        _buildLegendItem(
          theme: theme,
          color: Colors.red,
          label: 'Expenses',
          amount: 0,
          percentage: 0,
          isHighlighted: false,
        ),
      ],
    );
  }

  Widget _buildLegendItem({
    required ThemeData theme,
    required Color color,
    required String label,
    required double amount,
    required double percentage,
    required bool isHighlighted,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.all(isHighlighted ? 12 : 8),
      decoration: BoxDecoration(
        color: isHighlighted
            ? color.withOpacity(0.1)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHighlighted
              ? color
              : theme.colorScheme.outline.withOpacity(0.2),
          width: isHighlighted ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            currencyFormat.format(amount),
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (widget.summary.hasData)
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
