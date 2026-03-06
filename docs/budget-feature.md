Budget in Flutter App (Offline-First)

### Drift Database Schema

```dart
class BudgetPlans extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get periodMonth => integer()();
  IntColumn get periodYear => integer()();
  IntColumn get totalIncome => integer()();
  TextColumn get ruleType => text().withDefault(const Constant('50-30-20'))();
  IntColumn get needsPct => integer().withDefault(const Constant(50))();
  IntColumn get wantsPct => integer().withDefault(const Constant(30))();
  IntColumn get savingsPct => integer().withDefault(const Constant(20))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get hlcTimestamp => text().withDefault(const Constant(''))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  IntColumn get syncStatus => integer().withDefault(const Constant(1))();
  // syncStatus: 0=SYNCED, 1=PENDING, 2=CONFLICT

  @override
  Set<Column> get primaryKey => {id};
}
```

### Budget Rule Engine (Dart)

```dart
abstract class BudgetRule {
  String get name;
  Map<String, int> allocate(int totalIncome);
}

class FiftyThirtyTwenty implements BudgetRule {
  @override String get name => '50-30-20';

  @override
  Map<String, int> allocate(int totalIncome) {
    final needs = totalIncome * 50 ~/ 100;
    final wants = totalIncome * 30 ~/ 100;
    return {'NEEDS': needs, 'WANTS': wants, 'SAVINGS': totalIncome - needs - wants};
  }
}
```

### BudgetService (Flutter local)

- Create budget: validate percentages, compute allocations
- Get status: aggregate local expenses per bucket

### BudgetRepository (Flutter local)

Same sync pattern as other repositories:
- `insert(plan)` → write to local DB, set `syncStatus = PENDING`, generate HLC, enqueue to `SyncQueue`
- `update(plan)` → update local DB, set `syncStatus = PENDING`, advance HLC, enqueue to `SyncQueue`
- `delete(id)` → set `isDeleted = true` + `syncStatus = PENDING`, advance HLC, enqueue to `SyncQueue`

### State Management

```dart
// budgetProvider - budget creation and status via local BudgetService
final budgetProvider = ...
```

### Budget-Related Files (Flutter)

```
lib/
├── models/
│   └── budget_plan.dart
├── repositories/
│   └── budget_repository.dart
├── services/
│   ├── budget_service.dart
│   └── budget_rule_engine.dart
├── providers/
│   └── budget_provider.dart
└── screens/
    └── budget/
        ├── budget_form_screen.dart
        └── budget_status_screen.dart
```

---

## 6. Budget Screens (Flutter UI)

### Budget Form Screen

- Month/Year picker (defaults to current month)
- Total income field (auto-filled from local income transactions, editable)
- Rule selector: "50-30-20" (more rules in the future)
- Preview allocation before saving:
  ```
  Needs:   $2,900 (50%)
  Wants:   $1,740 (30%)
  Savings: $1,160 (20%)
  ```
- Save button → writes to local SQLite

### Budget Status Screen

- Per-bucket card (data aggregated from local DB):
    - Bucket name (Needs / Wants / Savings)
    - Progress bar (spent / allocated)
    - Amounts: spent, remaining, allocated
    - Health badge (Under Budget / On Track / Over Budget)
- Overall summary at top
- Layout prepared for Phase 4 pie charts

### Budget Status Screen Wireframe

```
┌─────────────────────────┐
│    March 2026 Budget    │
│    Income: $5,800.00    │
│                         │
│  ┌─ NEEDS (50%) ──────┐ │
│  │ ████████░░ 81%     │ │
│  │ $2,352 / $2,900    │ │
│  │ $548 remaining     │ │
│  └────────────────────┘ │
│                         │
│  ┌─ WANTS (30%) ──────┐ │
│  │ ██░░░░░░░░ 16%     │ │
│  │ $285 / $1,740      │ │
│  │ $1,455 remaining   │ │
│  └────────────────────┘ │
│                         │
│  ┌─ SAVINGS (20%) ────┐ │
│  │ ████████░░ 78%     │ │
│  │ $900 / $1,160      │ │
│  │ $260 remaining     │ │
│  └────────────────────┘ │
└─────────────────────────┘
```

---

## 7. Dummy Seed Data (March 2026)

### Dummy Budget Plan

| Field         | Value            |
|---------------|------------------|
| Period        | March 2026       |
| Rule          | 50-30-20         |
| Total Income  | $5,800           |
| Needs (50%)   | $2,900 allocated |
| Wants (30%)   | $1,740 allocated |
| Savings (20%) | $1,160 allocated |

### Resulting Budget Status (from dummy transactions)

| Bucket  | Spent  | Allocated | % Used | Health       |
|---------|--------|-----------|--------|--------------|
| Needs   | $2,352 | $2,900    | 81%    | ON_TRACK     |
| Wants   | $285   | $1,740    | 16%    | UNDER_BUDGET |
| Savings | $900   | $1,160    | 78%    | ON_TRACK     |

### Default Categories (budget bucket assignments)

| Name             | Type    | Budget Bucket |
|------------------|---------|---------------|
| Salary           | INCOME  | -             |
| Freelance        | INCOME  | -             |
| Investments      | INCOME  | -             |
| Gifts            | INCOME  | -             |
| Other Income     | INCOME  | -             |
| Rent             | EXPENSE | NEEDS         |
| Utilities        | EXPENSE | NEEDS         |
| Groceries        | EXPENSE | NEEDS         |
| Insurance        | EXPENSE | NEEDS         |
| Transportation   | EXPENSE | NEEDS         |
| Healthcare       | EXPENSE | NEEDS         |
| Dining Out       | EXPENSE | WANTS         |
| Entertainment    | EXPENSE | WANTS         |
| Shopping         | EXPENSE | WANTS         |
| Travel           | EXPENSE | WANTS         |
| Subscriptions    | EXPENSE | WANTS         |
| Emergency Fund   | EXPENSE | SAVINGS       |
| Retirement       | EXPENSE | SAVINGS       |
| Investments Out  | EXPENSE | SAVINGS       |
| Debt Repayment   | EXPENSE | SAVINGS       |

---

## 8. Phase 4: Budget Visualization (Reports)

### Backend additions

- `report.proto`: budget breakdown + expense breakdown RPCs
- `ReportRepository`: aggregate queries per bucket/category
- `ReportService`: monthly summary, budget breakdown, expense breakdown
- Color assignment: bucket colors + category color palette

### Flutter additions

- `fl_chart` dependency for pie charts
- `PieChartWidget`: colored segments, center text, legend
- Report screen tabs: Budget Overview, Expense Breakdown, Income Breakdown
- `HealthBadge` widget: `UNDER_BUDGET` (green), `ON_TRACK` (yellow), `OVER_BUDGET` (red)
- Mini summary card with small pie chart on Home screen
- Navigation: Home | Transactions | Budget | Reports

### Budget-Related Report Files (Flutter)

```
lib/
├── providers/
│   └── report_provider.dart
├── screens/
│   └── reports/
│       ├── report_screen.dart
│       ├── budget_pie_chart.dart
│       └── expense_breakdown_chart.dart
└── widgets/
    ├── pie_chart_widget.dart
    └── health_badge.dart
```

---

## 9. Navigation Routes (Budget)

| Route         | Screen               |
|---------------|----------------------|
| `/budget`     | Budget Status        |
| `/budget/new` | Budget Form (create) |

---