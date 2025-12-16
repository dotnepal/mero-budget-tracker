# Coding Guidelines

## Overview

This document outlines the coding standards and best practices followed in the Mero Budget Tracker codebase. These guidelines ensure consistency, maintainability, and quality across the entire project.

## Architecture Principles

### Clean Architecture
The project follows clean architecture with clear separation of concerns:

- **Domain Layer**: Business logic and entities (pure Dart, no Flutter dependencies)
- **Data Layer**: Data sources and repository implementations
- **Presentation Layer**: UI components, widgets, and state management

### Directory Structure
```
lib/
├── app/           # Application-level configurations
├── core/          # Core utilities and shared components
├── features/      # Feature modules
│   └── [feature]/
│       ├── domain/
│       │   ├── entities/
│       │   ├── repositories/
│       │   └── usecases/
│       ├── data/
│       │   ├── datasources/
│       │   ├── models/
│       │   └── repositories/
│       └── presentation/
│           ├── bloc/
│           ├── pages/
│           └── widgets/
└── shared/        # Shared components across features
```

## Dart/Flutter Conventions

### Import Organization
Imports should be organized in the following order:
1. Dart SDK imports
2. Flutter imports
3. Package imports
4. Project imports (use relative imports within features)

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
```

### Naming Conventions

#### Files
- Use lowercase with underscores: `transaction_repository.dart`
- One class per file (exceptions: related enums, extensions)
- File name should match the main class name

#### Classes and Enums
- Use PascalCase: `TransactionBloc`, `TransactionType`
- Prefix abstract classes with their purpose: `TransactionRepository`
- Suffix implementations with `Impl`: `TransactionRepositoryImpl`

#### Variables and Methods
- Use camelCase: `totalAmount`, `calculateBalance()`
- Private members prefix with underscore: `_transactions`
- Boolean variables should be prefixed with is/has/should: `isLoading`, `hasError`

#### Constants
- Use lowerCamelCase for local constants: `const defaultPageSize = 20`
- Use SCREAMING_SNAKE_CASE for global constants (avoid when possible)

## State Management (BLoC Pattern)

### Event Classes
```dart
abstract class TransactionEvent extends Equatable {
  const TransactionEvent();

  @override
  List<Object> get props => [];
}

class LoadTransactions extends TransactionEvent {
  const LoadTransactions();
}

class AddTransaction extends TransactionEvent {
  final Transaction transaction;

  const AddTransaction(this.transaction);

  @override
  List<Object> get props => [transaction];
}
```

### State Classes
```dart
abstract class TransactionState extends Equatable {
  const TransactionState();

  @override
  List<Object> get props => [];
}

class TransactionInitial extends TransactionState {}

class TransactionLoading extends TransactionState {}

class TransactionLoaded extends TransactionState {
  final List<Transaction> transactions;

  const TransactionLoaded(this.transactions);

  @override
  List<Object> get props => [transactions];
}
```

### BLoC Implementation
```dart
class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final TransactionRepository repository;

  TransactionBloc({
    required this.repository,
  }) : super(TransactionInitial()) {
    on<LoadTransactions>(_onLoadTransactions);
    on<AddTransaction>(_onAddTransaction);
  }

  Future<void> _onLoadTransactions(
    LoadTransactions event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    try {
      final transactions = await repository.getTransactions();
      emit(TransactionLoaded(transactions));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }
}
```

## Widget Guidelines

### Stateless vs Stateful
- Prefer StatelessWidget when possible
- Use StatefulWidget only when local state is needed
- Consider BLoC for complex state management

### Widget Structure
```dart
class TransactionTile extends StatelessWidget {
  // Constructor with required/optional parameters
  const TransactionTile({
    super.key,
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
  });

  // Final fields
  final Transaction transaction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    // Get theme early
    final theme = Theme.of(context);
    
    // Build widget tree
    return Container(...);
  }
}
```

### Widget Best Practices
- Extract complex widgets into separate files
- Keep build methods concise and readable
- Use const constructors where possible
- Avoid deeply nested widget trees (extract into methods or widgets)

## Entity and Model Design

### Entity Classes
```dart
class Transaction extends Equatable {
  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final String? category;  // Nullable fields
  final String? note;

  const Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.type,
    this.category,
    this.note,
  });

  @override
  List<Object?> get props => [
    id,
    description,
    amount,
    date,
    type,
    category,
    note,
  ];

  // Include copyWith for immutable updates
  Transaction copyWith({
    String? id,
    String? description,
    // ... other fields
  }) {
    return Transaction(
      id: id ?? this.id,
      description: description ?? this.description,
      // ... other fields
    );
  }
}
```

## Repository Pattern

### Abstract Repository
```dart
abstract class TransactionRepository {
  Future<List<Transaction>> getTransactions({
    int? offset,
    int? limit,
  });
  
  Future<Transaction> addTransaction(Transaction transaction);
  
  Future<Transaction> updateTransaction(Transaction transaction);
  
  Future<void> deleteTransaction(String id);
}
```

### Repository Implementation
```dart
class InMemoryTransactionRepository implements TransactionRepository {
  final List<Transaction> _transactions = [];

  @override
  Future<List<Transaction>> getTransactions({
    int? offset,
    int? limit,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Return paginated results
    final start = offset ?? 0;
    final end = limit != null ? start + limit : _transactions.length;
    
    return _transactions
        .skip(start)
        .take(end - start)
        .toList();
  }
}
```

## Error Handling

### Try-Catch Blocks
```dart
Future<void> _onLoadTransactions(
  LoadTransactions event,
  Emitter<TransactionState> emit,
) async {
  emit(TransactionLoading());
  try {
    final transactions = await repository.getTransactions();
    emit(TransactionLoaded(transactions));
  } catch (e) {
    // Log error for debugging
    debugPrint('Error loading transactions: $e');
    
    // Emit user-friendly error state
    emit(TransactionError('Failed to load transactions'));
  }
}
```

### Error Widgets
```dart
class TransactionErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const TransactionErrorView({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48),
          SizedBox(height: 16),
          Text(message),
          if (onRetry != null)
            ElevatedButton(
              onPressed: onRetry,
              child: Text('Retry'),
            ),
        ],
      ),
    );
  }
}
```

## Documentation

### Class Documentation
```dart
/// Handles all transaction-related state management.
/// 
/// This BLoC manages the loading, adding, updating, and deleting
/// of transactions in the application.
class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  /// The repository for transaction data operations
  final TransactionRepository repository;
  
  // ...
}
```

### Method Documentation
```dart
/// Loads transactions from the repository.
/// 
/// Emits [TransactionLoading] while fetching data,
/// then [TransactionLoaded] on success or [TransactionError] on failure.
Future<void> _onLoadTransactions(
  LoadTransactions event,
  Emitter<TransactionState> emit,
) async {
  // Implementation
}
```

## Testing Guidelines

### Unit Tests
- Test all business logic in BLoCs
- Test repository implementations
- Mock external dependencies

### Widget Tests
- Test widget rendering
- Test user interactions
- Verify state changes

### Test File Organization
```
test/
├── features/
│   └── transaction/
│       ├── domain/
│       │   └── entities/
│       ├── data/
│       │   └── repositories/
│       └── presentation/
│           ├── bloc/
│           └── widgets/
└── core/
```

## Performance Best Practices

### Widget Optimization
- Use `const` constructors where possible
- Implement `ListView.builder` for long lists
- Avoid rebuilding entire widget trees

### State Management
- Keep states immutable
- Use Equatable for efficient state comparisons
- Avoid unnecessary state emissions

### Memory Management
- Dispose controllers and streams properly
- Use weak references where appropriate
- Implement pagination for large data sets

## Code Quality Tools

### Linting
The project uses `flutter_lints` package. Run analysis with:
```bash
flutter analyze
```

### Formatting
Format code before committing:
```bash
dart format .
```

## Version Control Practices

### Commit Messages
- Use present tense: "Add feature" not "Added feature"
- Keep first line under 50 characters
- Reference issue numbers when applicable

### Branch Naming
- Feature branches: `feature/transaction-filtering`
- Bug fixes: `fix/transaction-deletion-error`
- Refactoring: `refactor/bloc-structure`

## Accessibility

### Widget Accessibility
- Provide semantic labels for icons
- Include tooltips for icon buttons
- Ensure sufficient color contrast
- Support screen readers

```dart
IconButton(
  icon: const Icon(Icons.add),
  tooltip: 'Add Transaction',
  onPressed: () {},
)
```

## Security Considerations

### Data Handling
- Never log sensitive information
- Sanitize user inputs
- Use secure storage for sensitive data
- Implement proper authentication (when added)

### API Keys
- Store API keys in environment variables
- Never commit API keys to version control
- Use different keys for development/production

## Conclusion

These guidelines are living documentation and should be updated as the project evolves. All contributors should familiarize themselves with these standards and follow them consistently to maintain code quality and project maintainability.