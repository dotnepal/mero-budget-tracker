import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mero_budget_tracker/features/transaction/domain/entities/transaction.dart';
import 'package:mero_budget_tracker/features/transaction/presentation/bloc/transaction_bloc.dart';
import 'package:mero_budget_tracker/features/transaction/presentation/widgets/edit_transaction_sheet.dart';
import 'package:mero_budget_tracker/features/transaction/data/repositories/in_memory_transaction_repository.dart';

void main() {
  group('Edit Transaction Tests', () {
    late TransactionBloc transactionBloc;
    late InMemoryTransactionRepository repository;
    late Transaction sampleTransaction;

    setUp(() {
      repository = InMemoryTransactionRepository();
      transactionBloc = TransactionBloc(repository: repository);
      sampleTransaction = Transaction(
        id: '1',
        description: 'Test Transaction',
        amount: 100.0,
        date: DateTime(2024, 1, 1),
        type: TransactionType.expense,
        note: 'Test note',
      );
    });

    tearDown(() {
      transactionBloc.close();
    });

    testWidgets('EditTransactionSheet displays pre-populated data', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<TransactionBloc>.value(
            value: transactionBloc,
            child: Scaffold(
              body: EditTransactionSheet(transaction: sampleTransaction),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check if form fields are pre-populated
      expect(find.text('Test Transaction'), findsOneWidget);
      expect(find.text('100.0'), findsOneWidget);
      expect(find.text('Test note'), findsOneWidget);
      expect(find.text('Edit Transaction'), findsOneWidget);
    });

    testWidgets('EditTransactionSheet validates empty description', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<TransactionBloc>.value(
            value: transactionBloc,
            child: Scaffold(
              body: EditTransactionSheet(transaction: sampleTransaction),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Clear description field
      await tester.tap(find.byType(TextFormField).first);
      await tester.enterText(find.byType(TextFormField).first, '');

      // Tap update button
      await tester.tap(find.text('Update'));
      await tester.pumpAndSettle();

      // Check for validation error
      expect(find.text('Description is required'), findsOneWidget);
    });

    testWidgets('EditTransactionSheet validates invalid amount', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<TransactionBloc>.value(
            value: transactionBloc,
            child: Scaffold(
              body: EditTransactionSheet(transaction: sampleTransaction),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find amount field and enter invalid amount
      final amountField = find.byType(TextFormField).at(1);
      await tester.tap(amountField);
      await tester.enterText(amountField, 'invalid');

      // Tap update button
      await tester.tap(find.text('Update'));
      await tester.pumpAndSettle();

      // Check for validation error
      expect(find.text('Invalid amount'), findsOneWidget);
    });

    testWidgets('EditTransactionSheet validates negative amount', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<TransactionBloc>.value(
            value: transactionBloc,
            child: Scaffold(
              body: EditTransactionSheet(transaction: sampleTransaction),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find amount field and enter negative amount
      final amountField = find.byType(TextFormField).at(1);
      await tester.tap(amountField);
      await tester.enterText(amountField, '-50');

      // Tap update button
      await tester.tap(find.text('Update'));
      await tester.pumpAndSettle();

      // Check for validation error
      expect(find.text('Amount must be greater than zero'), findsOneWidget);
    });

    testWidgets('EditTransactionSheet successfully updates transaction', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<TransactionBloc>.value(
            value: transactionBloc,
            child: Scaffold(
              body: EditTransactionSheet(transaction: sampleTransaction),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Update description
      await tester.tap(find.byType(TextFormField).first);
      await tester.enterText(find.byType(TextFormField).first, 'Updated Transaction');

      // Update amount
      final amountField = find.byType(TextFormField).at(1);
      await tester.tap(amountField);
      await tester.enterText(amountField, '150.0');

      // Update note
      final noteField = find.byType(TextFormField).last;
      await tester.tap(noteField);
      await tester.enterText(noteField, 'Updated note');

      // Tap update button
      await tester.tap(find.text('Update'));
      await tester.pumpAndSettle();

      // Check for success message
      expect(find.text('Transaction updated successfully'), findsOneWidget);
    });

    testWidgets('EditTransactionSheet shows loading state during submission', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<TransactionBloc>.value(
            value: transactionBloc,
            child: Scaffold(
              body: EditTransactionSheet(transaction: sampleTransaction),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap update button
      await tester.tap(find.text('Update'));
      await tester.pump(); // Don't pump and settle to catch loading state

      // Check for loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('EditTransactionSheet switches transaction type', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<TransactionBloc>.value(
            value: transactionBloc,
            child: Scaffold(
              body: EditTransactionSheet(transaction: sampleTransaction),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially, expense should be selected
      expect(find.text('Expense'), findsOneWidget);
      expect(find.text('Income'), findsOneWidget);

      // Tap income button
      await tester.tap(find.text('Income'));
      await tester.pumpAndSettle();

      // Verify income is now selected (this would be visible in the UI state)
      // The actual implementation would show visual feedback for the selected state
    });

    testWidgets('EditTransactionSheet opens date picker', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<TransactionBloc>.value(
            value: transactionBloc,
            child: Scaffold(
              body: EditTransactionSheet(transaction: sampleTransaction),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap date field
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Check if date picker is opened
      expect(find.byType(DatePickerDialog), findsOneWidget);
    });

    testWidgets('EditTransactionSheet validates description length', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<TransactionBloc>.value(
            value: transactionBloc,
            child: Scaffold(
              body: EditTransactionSheet(transaction: sampleTransaction),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter a very long description (over 160 characters)
      final longDescription = 'a' * 161;
      await tester.tap(find.byType(TextFormField).first);
      await tester.enterText(find.byType(TextFormField).first, longDescription);

      // Tap update button
      await tester.tap(find.text('Update'));
      await tester.pumpAndSettle();

      // Check for validation error
      expect(find.text('Description must be less than 160 characters'), findsOneWidget);
    });

    testWidgets('EditTransactionSheet cancel button closes sheet', (WidgetTester tester) async {
      bool sheetClosed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => BlocProvider<TransactionBloc>.value(
                      value: transactionBloc,
                      child: EditTransactionSheet(transaction: sampleTransaction),
                    ),
                  ).then((_) => sheetClosed = true);
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      // Open the sheet
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Tap cancel button
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Sheet should be closed
      expect(find.text('Edit Transaction'), findsNothing);
    });

    test('TransactionBloc handles EditTransaction event', () async {
      // Add initial transaction
      await repository.addTransaction(sampleTransaction);

      // Create updated transaction
      final updatedTransaction = sampleTransaction.copyWith(
        description: 'Updated Description',
        amount: 200.0,
      );

      // Test the bloc
      transactionBloc.add(LoadTransactions());
      await expectLater(
        transactionBloc.stream,
        emitsInOrder([
          isA<TransactionLoading>(),
          isA<TransactionLoaded>(),
        ]),
      );

      transactionBloc.add(EditTransaction(updatedTransaction));
      await expectLater(
        transactionBloc.stream,
        emitsInOrder([
          isA<TransactionUpdating>(),
          isA<TransactionLoaded>(),
        ]),
      );
    });
  });

  group('Integration Tests', () {
    testWidgets('Full edit transaction flow', (WidgetTester tester) async {
      final repository = InMemoryTransactionRepository();
      final bloc = TransactionBloc(repository: repository);

      // Add a sample transaction first
      final sampleTransaction = Transaction(
        id: '1',
        description: 'Original Transaction',
        amount: 100.0,
        date: DateTime(2024, 1, 1),
        type: TransactionType.expense,
      );

      await repository.addTransaction(sampleTransaction);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<TransactionBloc>.value(
            value: bloc,
            child: Scaffold(
              body: EditTransactionSheet(transaction: sampleTransaction),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify original data is displayed
      expect(find.text('Original Transaction'), findsOneWidget);
      expect(find.text('100.0'), findsOneWidget);

      // Edit the transaction
      await tester.tap(find.byType(TextFormField).first);
      await tester.enterText(find.byType(TextFormField).first, 'Modified Transaction');

      final amountField = find.byType(TextFormField).at(1);
      await tester.tap(amountField);
      await tester.enterText(amountField, '250.0');

      // Submit the changes
      await tester.tap(find.text('Update'));
      await tester.pumpAndSettle();

      // Verify success message
      expect(find.text('Transaction updated successfully'), findsOneWidget);

      bloc.close();
    });
  });
}
