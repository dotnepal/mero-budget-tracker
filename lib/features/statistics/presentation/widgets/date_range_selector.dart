import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum DateRangeOption {
  currentMonth,
  last3Months,
  last6Months,
  lastYear,
  allTime,
  custom,
}

class DateRangeSelector extends StatelessWidget {
  final DateTimeRange selectedRange;
  final Function(DateTimeRange) onRangeChanged;

  const DateRangeSelector({
    super.key,
    required this.selectedRange,
    required this.onRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date Range',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildChip(
                context: context,
                label: 'This Month',
                option: DateRangeOption.currentMonth,
                isSelected: _isCurrentMonth(),
              ),
              const SizedBox(width: 8),
              _buildChip(
                context: context,
                label: 'Last 3 Months',
                option: DateRangeOption.last3Months,
                isSelected: _isLast3Months(),
              ),
              const SizedBox(width: 8),
              _buildChip(
                context: context,
                label: 'Last 6 Months',
                option: DateRangeOption.last6Months,
                isSelected: _isLast6Months(),
              ),
              const SizedBox(width: 8),
              _buildChip(
                context: context,
                label: 'Last Year',
                option: DateRangeOption.lastYear,
                isSelected: _isLastYear(),
              ),
              const SizedBox(width: 8),
              _buildChip(
                context: context,
                label: 'All Time',
                option: DateRangeOption.allTime,
                isSelected: _isAllTime(),
              ),
              const SizedBox(width: 8),
              _buildCustomChip(context),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildSelectedRangeDisplay(theme),
      ],
    );
  }

  Widget _buildChip({
    required BuildContext context,
    required String label,
    required DateRangeOption option,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          _selectPredefinedRange(option);
        }
      },
      selectedColor: theme.colorScheme.primaryContainer,
      checkmarkColor: theme.colorScheme.onPrimaryContainer,
    );
  }

  Widget _buildCustomChip(BuildContext context) {
    final theme = Theme.of(context);
    final isCustom = !_isCurrentMonth() &&
                    !_isLast3Months() &&
                    !_isLast6Months() &&
                    !_isLastYear() &&
                    !_isAllTime();

    return FilterChip(
      label: const Text('Custom'),
      selected: isCustom,
      onSelected: (selected) {
        if (selected) {
          _showCustomDatePicker(context);
        }
      },
      selectedColor: theme.colorScheme.primaryContainer,
      checkmarkColor: theme.colorScheme.onPrimaryContainer,
    );
  }

  Widget _buildSelectedRangeDisplay(ThemeData theme) {
    final formatter = DateFormat('MMM dd, yyyy');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.date_range,
            color: theme.colorScheme.onSurfaceVariant,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${formatter.format(selectedRange.start)} - ${formatter.format(selectedRange.end)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isCurrentMonth() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    return _isSameDay(selectedRange.start, startOfMonth) &&
           _isSameDay(selectedRange.end, endOfMonth);
  }

  bool _isLast3Months() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - 2, 1);
    final end = DateTime(now.year, now.month + 1, 0);

    return _isSameDay(selectedRange.start, start) &&
           _isSameDay(selectedRange.end, end);
  }

  bool _isLast6Months() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - 5, 1);
    final end = DateTime(now.year, now.month + 1, 0);

    return _isSameDay(selectedRange.start, start) &&
           _isSameDay(selectedRange.end, end);
  }

  bool _isLastYear() {
    final now = DateTime.now();
    final start = DateTime(now.year - 1, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0);

    return _isSameDay(selectedRange.start, start) &&
           _isSameDay(selectedRange.end, end);
  }

  bool _isAllTime() {
    final start = DateTime(2020, 1, 1); // Reasonable start date
    final now = DateTime.now();
    final end = DateTime(now.year, now.month + 1, 0);

    return _isSameDay(selectedRange.start, start) &&
           _isSameDay(selectedRange.end, end);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _selectPredefinedRange(DateRangeOption option) {
    final now = DateTime.now();
    DateTime start;
    DateTime end;

    switch (option) {
      case DateRangeOption.currentMonth:
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0);
        break;
      case DateRangeOption.last3Months:
        start = DateTime(now.year, now.month - 2, 1);
        end = DateTime(now.year, now.month + 1, 0);
        break;
      case DateRangeOption.last6Months:
        start = DateTime(now.year, now.month - 5, 1);
        end = DateTime(now.year, now.month + 1, 0);
        break;
      case DateRangeOption.lastYear:
        start = DateTime(now.year - 1, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0);
        break;
      case DateRangeOption.allTime:
        start = DateTime(2020, 1, 1);
        end = DateTime(now.year, now.month + 1, 0);
        break;
      case DateRangeOption.custom:
        return; // Handled separately
    }

    onRangeChanged(DateTimeRange(start: start, end: end));
  }

  Future<void> _showCustomDatePicker(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: selectedRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onRangeChanged(picked);
    }
  }
}
