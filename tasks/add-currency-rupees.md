# Feature: Multi-currency support — Add ₹ (INR), preserve $ (USD)

## Status: Completed ✅

## Overview

Add Indian Rupee (INR) as a selectable currency alongside USD. The selected currency persists in SQLite and propagates to all display widgets without a restart.

---

## Step-by-step implementation

### Step 1 — Currency formatter utility ✅
**File:** `lib/core/utils/currency_formatter.dart` (new)

Central `NumberFormat` factory used by all 8 display widgets.
- `getFormatter(code)` → returns `NumberFormat` for the given currency code
- `format(amount, code)` → formats amount directly
- `getSymbol(code)` → returns the symbol string for `prefixText` fields

INR uses `NumberFormat.currency(locale: 'hi_IN', symbol: '₹')` for Indian number grouping (`₹ 1,00,000.00`).

---

### Step 2 — Settings domain layer ✅
**Files (new):**
- `lib/features/settings/domain/entities/app_settings.dart` — `AppSettings` entity with `currencyCode` field, `Equatable`, `copyWith`
- `lib/features/settings/domain/repositories/settings_repository.dart` — abstract `SettingsRepository` with `loadSettings()` and `saveCurrencyCode()`

---

### Step 3 — Settings data layer ✅
**File:** `lib/features/settings/data/repositories/settings_repository_impl.dart` (new)

Reads/writes `preferences` SQLite table:
- key = `'currency_code'`, value = `'USD'` or `'INR'`
- Defaults to `'USD'` if no row exists
- Uses `ConflictAlgorithm.replace` for upsert

---

### Step 4 — SettingsBloc ✅
**Files (new):**
- `lib/features/settings/presentation/bloc/settings_event.dart` — `LoadSettings`, `UpdateCurrencyCode(code)`
- `lib/features/settings/presentation/bloc/settings_state.dart` — `SettingsInitial`, `SettingsLoading`, `SettingsLoaded(settings)`, `SettingsError(message)`
- `lib/features/settings/presentation/bloc/settings_bloc.dart` — handles both events, emits `SettingsLoaded` on success

---

### Step 5 — Wire SettingsBloc into app root ✅
**File modified:** `lib/main.dart`

Added imports for `SettingsBloc`, `SettingsEvent`, `SettingsRepositoryImpl`, `DatabaseHelper`.
Added `BlocProvider` inside the `MultiBlocProvider` that creates `SettingsBloc` and immediately dispatches `LoadSettings`.

---

### Step 6 — Updated all 8 display locations ✅

All widgets now read currency from `SettingsBloc` via `context.select` for efficient rebuilds:

| File | Change |
|------|--------|
| `lib/features/home/presentation/widgets/expense_card.dart` | `context.select` → `CurrencyFormatter.getFormatter` |
| `lib/features/home/presentation/widgets/income_card.dart` | same |
| `lib/features/transaction/presentation/widgets/transaction_tile.dart` | same (TransactionTile + TransactionDetailsSheet) |
| `lib/features/statistics/presentation/widgets/financial_summary_cards.dart` | same |
| `lib/features/statistics/presentation/widgets/expense_income_chart.dart` | `currencyFormat` moved from field to `build()`, passed to helper methods |
| `lib/features/home/presentation/screens/home_screen.dart` | `context.select` in `itemBuilder` |
| `lib/features/home/presentation/widgets/add_transaction_form.dart` | `prefixText` uses `context.select` + `CurrencyFormatter.getSymbol` |
| `lib/features/transaction/presentation/widgets/edit_transaction_sheet.dart` | same |

---

### Step 7 — Currency picker UI in Settings ✅
**File modified:** `lib/features/settings/presentation/pages/settings_page.dart`

- Converted to use `BlocBuilder<SettingsBloc, SettingsState>` for dynamic subtitle
- Added `_showCurrencyPicker()` dialog with `RadioListTile` for USD and INR
- On selection, dispatches `UpdateCurrencyCode(code)` to `SettingsBloc`
- New tile placed first in the **General** section with `Icons.currency_rupee`

---

## Verification checklist

- [x] `flutter analyze` — no new errors (pre-existing deprecation infos only)
- [ ] Run app on Chrome: default shows `$` formatting everywhere
- [ ] Settings → General → Currency → select `₹ Indian Rupee`
- [ ] All screens (Home, Statistics, Transaction list) immediately show `₹ 1,00,000.00` style
- [ ] Restart app — `₹` persists (loaded from SQLite `preferences` table)
- [ ] Switch back to `$` — USD formatting resumes
- [ ] `flutter test` — existing tests pass

---

## Files created/modified

### New files
- `lib/core/utils/currency_formatter.dart`
- `lib/features/settings/domain/entities/app_settings.dart`
- `lib/features/settings/domain/repositories/settings_repository.dart`
- `lib/features/settings/data/repositories/settings_repository_impl.dart`
- `lib/features/settings/presentation/bloc/settings_event.dart`
- `lib/features/settings/presentation/bloc/settings_state.dart`
- `lib/features/settings/presentation/bloc/settings_bloc.dart`

### Modified files
- `lib/main.dart`
- `lib/features/settings/presentation/pages/settings_page.dart`
- `lib/features/home/presentation/widgets/expense_card.dart`
- `lib/features/home/presentation/widgets/income_card.dart`
- `lib/features/transaction/presentation/widgets/transaction_tile.dart`
- `lib/features/statistics/presentation/widgets/financial_summary_cards.dart`
- `lib/features/statistics/presentation/widgets/expense_income_chart.dart`
- `lib/features/home/presentation/screens/home_screen.dart`
- `lib/features/home/presentation/widgets/add_transaction_form.dart`
- `lib/features/transaction/presentation/widgets/edit_transaction_sheet.dart`
