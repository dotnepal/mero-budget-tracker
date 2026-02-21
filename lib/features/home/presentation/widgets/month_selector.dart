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
    final months = List.generate(
      12,
      (i) => DateTime(selectedMonth.year, i + 1, 1),
    );

    return DropdownButton<DateTime>(
      hint: const Text('Select Month'),
      value: selectedMonth,
      isExpanded: true,
      items: months.map((month) {
        return DropdownMenuItem<DateTime>(
          value: month,
          child: Text(DateFormat('MMMM yyyy').format(month)),
        );
      }).toList(),
      onChanged: (month) {
        if (month != null) onMonthChanged(month);
      },
    );
  }
}
