import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MonthSelector extends StatelessWidget {
  final DateTime selectedMonth;
  final Function(DateTime) onMonthChanged;

  const MonthSelector({
    super.key,
    required this.selectedMonth,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 12,
        itemBuilder: (context, index) {
          final month = DateTime(
            selectedMonth.year,
            index + 1,
            1,
          );
          final isSelected = month.month == selectedMonth.month &&
                            month.year == selectedMonth.year;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              selected: isSelected,
              label: Text(DateFormat('MMM').format(month)),
              onSelected: (selected) {
                if (selected) {
                  onMonthChanged(month);
                }
              },
            ),
          );
        },
      ),
    );
  }
}
