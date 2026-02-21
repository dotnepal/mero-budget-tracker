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

The project follows Clean Architecture with three layers per feature:

```
lib/
├── main.dart                    # App entry point, BLoC providers setup
├── core/
│   ├── database/                # SQLite database (DatabaseHelper, DatabaseService)
│   ├── router/                  # App routing (AppRouter)
│   ├── theme/                   # Material Design 3 theme (AppTheme)
│   └── widgets/                 # Shared widgets
└── features/
    ├── transaction/             # Main transaction feature
    │   ├── domain/              # Entities, repository interfaces
    │   ├── data/                # Repository implementations (SQLite)
    │   └── presentation/        # BLoC, pages, widgets
    ├── statistics/              # Charts and financial analytics
    │   ├── domain/              # FinancialSummary entity
    │   ├── data/                # StatisticsRepositoryImpl
    │   └── presentation/        # StatisticsBloc, charts (fl_chart)
    └── home/                    # Home screen with monthly summary
        ├── domain/              # MonthlySummary entity
        ├── data/                # SummaryRepositoryImpl
        └── presentation/        # SummaryBloc, summary cards
```

### Key Patterns

- **BLoC Pattern**: State management using `flutter_bloc`. Each feature has its own bloc with events/states extending `Equatable`.
- **Repository Pattern**: Abstract repositories in `domain/`, implementations in `data/`.
- **SQLite**: Persistent storage via `sqflite` package. Database schema in `core/database/database_helper.dart`.

### BLoC Structure

Each BLoC follows this pattern:
- Events: `[Feature]Event` classes extending `Equatable`
- States: `[Feature]Initial`, `[Feature]Loading`, `[Feature]Loaded`, `[Feature]Error`
- Bloc: Handles events with `on<Event>(_handler)` pattern

### Database

SQLite database with tables: `transactions`, `categories`, `budgets`, `preferences`. Database version managed in `DatabaseHelper`. Transactions use `SqliteTransactionRepository`.

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
### 1. Plan Node Default
- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions)
- If something goes sideways, STOP and re-plan immediately - don't keep pushing
- Use plan mode for verification steps, not just building
- Write detailed specs upfront to reduce ambiguity

### 2. Subagent Strategy
- Use subagents liberally to keep main context window clean
- Offload research, exploration, and parallel analysis to subagents
- For complex problems, throw more compute at it via subagents
- One tack per subagent for focused execution

### 3. Self-Improvemennt Loop
- After ANY correction from the user: update `tasks/lessons.md` with the pattern
- Write rules for yourself that prevent the same mistake
- Ruthlessly iterate on these lessons until mistake rate drops
- Review lessons at session start for relevant project

### 4. Verification Before Done
- Never mark a task complete without proving it works
- Diff behaviro between main and your changes when relevant
- Ask yourself: "Would a staff engineer approve this?"
- Run tests, check logs, demonstrate correctness

### 4. Demand Elegance (Balanced)
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
5. **Capture Lessons**: Update `tasks/lessons.md` after corrections

## Core Principles

- **Simplicity First**: Make every chagne as simple as possible. Impact minimal code.
- **No Laziness**: Find root cuases. No temporary fixes. Senior developer standards.
- **Minimal Impact**: Changes should only touch what's necessary. Avoid introducing bugs.

