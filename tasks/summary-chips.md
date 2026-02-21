# Tasks: Replace Month Selector Chips with Dropdown

## Implementation Checklist

- [x] **1. Rewrite `MonthSelector` widget**
  - File: `lib/features/home/presentation/widgets/month_selector.dart`
  - Remove `SizedBox + ListView.builder + FilterChip` block
  - Add `DropdownButton<DateTime>` with `hint`, `value`, `isExpanded`, `items`, `onChanged`
  - Format items as `"MMMM yyyy"` using `intl` package (already imported)

- [x] **2. Update loading skeleton in `SummaryCardsLoading`**
  - File: `lib/features/home/presentation/widgets/summary_cards_loading.dart`
  - Remove horizontal shimmer chip row (`SizedBox` with `ListView.builder`, lines 13–37)
  - Replace with a single full-width shimmer `Container` (height 48, rounded corners) to match dropdown shape

## Verification

- [ ] **3. Run and verify on device**
  - Run `flutter run --flavor staging` (iOS) or `flutter run -d chrome`
  - Dropdown replaces chip row on home screen
  - All 12 months of the current year appear in the dropdown list
  - Selecting a month correctly refreshes income/expense summary cards
  - Loading state shows shimmer dropdown bar instead of shimmer chips
