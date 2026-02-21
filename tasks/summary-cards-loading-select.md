# Plan: Replace Month Selector Chips with Dropdown

## Context
The home screen currently shows a horizontally scrollable row of `FilterChip` widgets for selecting months (Jan–Dec of the current year). The user wants this replaced with a `DropdownButton` that shows a "Select Month" hint and lets the user pick a month from a list. Income/expense summary cards must update identically on selection — only the UI control changes.

## Files to Modify

### 1. `lib/features/home/presentation/widgets/month_selector.dart`
Replace the `SizedBox + ListView.builder + FilterChip` block with a `DropdownButton<DateTime>`:

```dart
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
```

Key points:
- `hint: const Text('Select Month')` — shown when no value is selected (edge case)
- `value: selectedMonth` — reflects current selection
- `isExpanded: true` — stretches to fill available width
- Items: 12 months of the selected year formatted as `"MMMM yyyy"` (e.g., "January 2025")
- `onChanged` calls existing `onMonthChanged` callback — no BLoC changes needed

### 2. `lib/features/home/presentation/widgets/summary_cards_loading.dart`
Replace the horizontal shimmer chip row (lines 13–37) with a shimmer skeleton shaped like a dropdown:

```dart
// Replace the SizedBox(height: 50, child: ListView.builder(...)) block with:
Shimmer.fromColors(
  baseColor: Colors.grey[300]!,
  highlightColor: Colors.grey[100]!,
  child: Container(
    height: 48,
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(4),
    ),
  ),
),
```

## Files NOT Modified
- `summary_cards.dart` — passes `onMonthChanged` through unchanged; no interface change
- `home_page.dart` — BLoC wiring unchanged; `LoadMonthlySummary` dispatched same as before
- `summary_bloc.dart`, `summary_event.dart`, `summary_state.dart` — no changes needed

## Verification
1. Run `flutter run --flavor staging` (iOS) or `flutter run -d chrome`
2. Home screen shows a full-width dropdown where the chip row used to be
3. Tapping the dropdown lists all 12 months of the current year (e.g., "January 2025" … "December 2025")
4. Selecting a month updates the income/expense cards correctly
5. Loading skeleton shows a single shimmer bar (dropdown shape) instead of chips
