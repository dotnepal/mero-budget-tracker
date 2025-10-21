# Basic BLoC Implementation Guide

This document outlines the basic BLoC (Business Logic Component) implementation in the Mero Budget Tracker app.

## Overview

BLoC pattern is implemented to manage the state of transactions in the application. The implementation follows a clean architecture approach with clear separation of concerns.

## Structure

```
lib/features/home/presentation/bloc/
├── transaction_bloc.dart     # Main BLoC implementation
├── transaction_event.dart    # Events that can be dispatched
└── transaction_state.dart    # Possible states of the application
```

## Implementation Steps

### 1. Dependencies

Add the following dependencies to `pubspec.yaml`:

```yaml
dependencies:
  flutter_bloc: ^8.1.3
  bloc: ^8.1.2
  equatable: ^2.0.5
```

### 2. Events (`transaction_event.dart`)

Events represent actions that can occur in the application:

```dart
abstract class TransactionEvent extends Equatable {
  const TransactionEvent();

  @override
  List<Object?> get props => [];
}

class LoadTransactions extends TransactionEvent {}
class AddTransaction extends TransactionEvent {
  const AddTransaction(this.transaction);
  final Transaction transaction;
  @override
  List<Object?> get props => [transaction];
}
class UpdateTransaction extends TransactionEvent {...}
class DeleteTransaction extends TransactionEvent {...}
```

### 3. States (`transaction_state.dart`)

States represent the different states the UI can be in:

```dart
abstract class TransactionState extends Equatable {
  const TransactionState();
  @override
  List<Object?> get props => [];
}

class TransactionInitial extends TransactionState {}
class TransactionLoading extends TransactionState {}
class TransactionLoaded extends TransactionState {
  const TransactionLoaded(this.transactions);
  final List<Transaction> transactions;
  @override
  List<Object?> get props => [transactions];
}
class TransactionError extends TransactionState {...}
```

### 4. BLoC (`transaction_bloc.dart`)

The BLoC handles the business logic:

```dart
class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  TransactionBloc({required TransactionRepository repository})
      : _repository = repository,
        super(TransactionInitial()) {
    on<LoadTransactions>(_onLoadTransactions);
    on<AddTransaction>(_onAddTransaction);
    on<UpdateTransaction>(_onUpdateTransaction);
    on<DeleteTransaction>(_onDeleteTransaction);
  }

  final TransactionRepository _repository;

  Future<void> _onLoadTransactions(
    LoadTransactions event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    try {
      final transactions = await _repository.getTransactions();
      emit(TransactionLoaded(transactions));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }
  // ... other event handlers
}
```

### 5. Provider Setup (`main.dart`)

Provide the BLoC to the widget tree:

```dart
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TransactionBloc(
        repository: InMemoryTransactionRepository(),
      )..add(LoadTransactions()),
      child: MaterialApp(
        // ... app configuration
      ),
    );
  }
}
```

### 6. UI Integration (`home_screen.dart`)

Use BlocBuilder to respond to state changes:

```dart
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<TransactionBloc, TransactionState>(
        builder: (context, state) {
          if (state is TransactionLoading) {
            return const CircularProgressIndicator();
          }
          if (state is TransactionLoaded) {
            return ListView.builder(
              itemBuilder: (context, index) {
                // Build transaction list item
              },
            );
          }
          // ... handle other states
        },
      ),
    );
  }
}
```

## Usage

1. **Dispatching Events**:
```dart
context.read<TransactionBloc>().add(LoadTransactions());
// or
context.read<TransactionBloc>().add(AddTransaction(newTransaction));
```

2. **Listening to States**:
```dart
BlocListener<TransactionBloc, TransactionState>(
  listener: (context, state) {
    if (state is TransactionError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message)),
      );
    }
  },
  child: YourWidget(),
);
```

## Best Practices

1. Always extend `Equatable` for Events and States
2. Keep Events and States immutable
3. Handle all possible states in the UI
4. Use `BlocConsumer` when you need both builder and listener
5. Keep BLoC business logic pure and testable
6. Use repository pattern for data operations
7. Handle errors appropriately

## Testing

Example of testing the BLoC:

```dart
void main() {
  group('TransactionBloc', () {
    late TransactionBloc bloc;
    late MockTransactionRepository repository;

    setUp(() {
      repository = MockTransactionRepository();
      bloc = TransactionBloc(repository: repository);
    });

    test('initial state is TransactionInitial', () {
      expect(bloc.state, isA<TransactionInitial>());
    });

    blocTest<TransactionBloc, TransactionState>(
      'emits [Loading, Loaded] when LoadTransactions is added',
      build: () => bloc,
      act: (bloc) => bloc.add(LoadTransactions()),
      expect: () => [
        isA<TransactionLoading>(),
        isA<TransactionLoaded>(),
      ],
    );
  });
}
```

## Next Steps

1. Implement proper error handling
2. Add loading indicators
3. Implement transaction form
4. Add filtering and sorting
5. Implement data persistence
6. Add unit and widget tests

This implementation provides a solid foundation for state management in the app. The BLoC pattern helps maintain clean architecture and makes the code more maintainable and testable.