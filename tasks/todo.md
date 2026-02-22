# Task: Change FAB to "+ Add New"

## Plan
- [x] Locate the correct FAB in `lib/features/transaction/presentation/pages/home_page.dart`
- [x] Replace `FloatingActionButton` with `FloatingActionButton.extended`
- [x] Add `icon: const Icon(Icons.add)` and `label: const Text('Add New')`
- [x] Revert incorrect change to `lib/features/home/presentation/screens/home_screen.dart`

## Change Summary

**File modified:** `lib/features/transaction/presentation/pages/home_page.dart` (line 155)

```dart
// Before
floatingActionButton: FloatingActionButton(
  onPressed: () { ... },
  child: const Icon(Icons.add),
),

// After
floatingActionButton: FloatingActionButton.extended(
  onPressed: () { ... },
  icon: const Icon(Icons.add),
  label: const Text('Add New'),
),
```

## Review

### Result
Change applied correctly in the actual home screen rendered by the router.

### Root Cause of First Mistake
The initial edit targeted `lib/features/home/presentation/screens/home_screen.dart` which is **not routed** — the app's `AppRouter` maps `/` to `HomePage` in `lib/features/transaction/presentation/pages/home_page.dart`. The router must be checked to identify the actual rendered screen before making UI changes.

### Verification Steps
1. Run `flutter run --flavor staging` (iOS) or `flutter run -d chrome`
2. Observe the home screen
3. Confirm the FAB shows `+ Add New` (pill-shaped extended button) instead of a plain round add icon
