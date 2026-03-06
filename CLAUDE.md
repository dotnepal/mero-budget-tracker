# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Mero Budget Tracker is a Flutter budget tracking app using Clean Architecture and BLoC pattern. ~90% of the code is AI-generated (experimental project, not for production).

## Build Commands

```bash
# Install dependencies
flutter pub get

# Run the app (Chrome recommended for development)
flutter run -d chrome

# Run tests
flutter test

# Run a single test file
flutter test test/path/to/test_file.dart

# Analyze code (lint check)
flutter analyze

# Format code
dart format .

# Build release
flutter build apk --release
flutter build ios --release
```

## Architecture

The project follows Clean Architecture with three layers per feature. **There is no use case layer** — BLoCs call repositories directly.

```
lib/
├── main.dart                    # App entry point, all BLoC providers setup
├── core/
│   ├── database/                # DatabaseHelper (singleton, schema/migrations) + DatabaseService (export/import/backup)
│   ├── router/                  # AppRouter — static Navigator.pushNamed routes
│   ├── theme/                   # Material Design 3 light/dark AppTheme
│   └── widgets/                 # Shared widgets
└── features/
    ├── transaction/             # CRUD for income/expense transactions
    │   ├── domain/              # Transaction entity, TransactionRepository interface
    │   ├── data/                # SqliteTransactionRepository, InMemoryTransactionRepository (for tests)
    │   └── presentation/        # TransactionBloc, pages, widgets
    ├── category/                # Category management (system + user-defined)
    │   ├── domain/              # Category entity (name, icon, color, type), CategoryRepository interface
    │   ├── data/                # SqliteCategoryRepository
    │   └── presentation/        # CategoryBloc, category_form_dialog, category_chip_selector
    ├── statistics/              # Charts and financial analytics
    │   ├── domain/              # FinancialSummary entity
    │   ├── data/                # StatisticsRepositoryImpl
    │   └── presentation/        # StatisticsBloc, fl_chart widgets, date_range_selector
    ├── home/                    # Monthly summary dashboard
    │   ├── domain/              # MonthlySummary entity (with computed savingsRate etc.)
    │   ├── data/                # SummaryRepositoryImpl
    │   └── presentation/        # SummaryBloc, summary_cards, month_selector
    └── settings/                # App configuration — presentation layer only (no BLoC/domain)
        └── presentation/        # settings_page, database_settings_page, category_settings_page
```

### Key Patterns

- **BLoC Pattern**: State management using `flutter_bloc`. Each feature has its own bloc with events/states extending `Equatable`. BLoCs are provided globally in `main.dart`.
- **Repository Pattern**: Abstract repositories in `domain/`, SQLite implementations in `data/`. In-memory implementations exist in `transaction/` and `home/` for testing.
- **Routing**: Simple static `MaterialPageRoute` via `Navigator.pushNamed`. Routes: `/`, `/statistics`, `/settings`, `/settings/categories`, `/settings/database`.

### BLoC Structure

Each BLoC follows this pattern:
- Events: `[Feature]Event` classes extending `Equatable`
- States: `[Feature]Initial`, `[Feature]Loading`, `[Feature]Loaded`, `[Feature]Error`
- Bloc: Handles events with `on<Event>(_handler)` pattern

### Database

SQLite (`mero_budget_tracker.db`) managed by `DatabaseHelper` singleton. Active tables: `transactions`, `categories`. Defined but unused: `budgets`, `preferences`. Foreign keys enabled. `DatabaseService` wraps `DatabaseHelper` and adds export/import JSON, backup/restore, and sample data insertion.

## Coding Conventions

- **Files**: `snake_case.dart`
- **Classes**: `PascalCase`, suffix implementations with `Impl`
- **Variables**: `camelCase`, prefix booleans with `is/has/should`
- **Imports**: Dart SDK → Flutter → Packages → Project (relative within features)
- **Widgets**: Prefer `StatelessWidget`, use `const` constructors, extract complex widgets
- **Entities**: Extend `Equatable`, include `copyWith` for immutability

## Commit Message Format

```
feat: Add budget calculation feature
fix: Resolve total calculation error
docs: Update README
refactor: Restructure budget model
```

### Workflow Orchestration

### 1. Plan Mode Default
- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions)
- If something goes sideways, STOP and re-plan immediately - don't keep pushing
- Use plan mode for verification steps, not just building
- Write detailed specs upfront to reduce ambiguity

### 2. Subagent Strategy
- Use subagents liberally to keep main context window clean
- Offload research, exploration, and parallel analysis to subagents
- For complex problems, throw more compute at it via subagents
- One tack per subagent for focused execution

### 3. Self-Improvement Loop
- After ANY correction from the user: update `tasks/lessons.md` with the pattern
- Write rules for yourself that prevent the same mistake
- Ruthlessly iterate on these lessons until mistake rate drops
- Review lessons at session start for relevant project

### 4. Verification Before Done
- Never mark a task complete without proving it works
- Diff behavior between main and your changes when relevant
- Ask yourself: "Would a staff engineer approve this?"
- Run tests, check logs, demonstrate correctness

### 5. Demand Elegance (Balanced)
- For non-trivial changes: pause and ask "is there a more elegant way?"
- If a fix feels hacky: "Knowing everything I know now, implement the elegant solution"
- Skip this for simple, obvious fixes - don't over-engineer
- Challenge your own work before presenting it

### 6. Autonomous Bug Fixing
- When given a bug report: just fix it. Don't ask for hand-holding
- Point at logs, errors, failing tests - then resolve them
- Zero context switching required from the user
- Go fix failing CI tests without being told how

### Task Management
1. **Plan First**: Write plan to `tasks/todo.md` with checkable items
2. **Verify Plan**: Check in before starting implementation
3. **Track Progress**: Mark items complete as you go
4. **Explain Changes**: High-level summary at each step
5. **Document Result**: Add review section to `tasks/todo.md`
6. **Capture Lessons**: Update `tasks/lessons.md` after corrections

## Core Principles

- **Simplicity First**: Make every change as simple as possible. Impact minimal code.
- **No Laziness**: Find root causes. No temporary fixes. Senior developer standards.
- **Minimal Impact**: Changes should only touch what's necessary. Avoid introducing bugs.

