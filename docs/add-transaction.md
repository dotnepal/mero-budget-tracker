# Add Transaction Functionality

This document outlines how to implement the "Add Transaction" functionality in the Mero Budget Tracker app when the FloatingActionButton is pressed.

## Overview

The implementation will include:
1. A modal bottom sheet for transaction input
2. Form validation
3. BLoC integration for state management
4. Error handling

## Implementation Steps

### 1. Create Transaction Form Widget

Create a new file at `lib/features/home/presentation/widgets/add_transaction_form.dart`:

```dart
class AddTransactionForm extends StatefulWidget {
  const AddTransactionForm({super.key});

  @override
  State<AddTransactionForm> createState() => _AddTransactionFormState();
}

class _AddTransactionFormState extends State<AddTransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  TransactionType _type = TransactionType.expense;
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add Transaction',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Enter transaction description',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                hintText: 'Enter amount',
                prefixText: '\$ ',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Type: '),
                SegmentedButton<TransactionType>(
                  segments: const [
                    ButtonSegment(
                      value: TransactionType.expense,
                      label: Text('Expense'),
                      icon: Icon(Icons.arrow_upward),
                    ),
                    ButtonSegment(
                      value: TransactionType.income,
                      label: Text('Income'),
                      icon: Icon(Icons.arrow_downward),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (Set<TransactionType> selection) {
                    setState(() {
                      _type = selection.first;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Date: '),
                TextButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _selectedDate = date;
                      });
                    }
                  },
                  child: Text(
                    _selectedDate.toString().split(' ')[0],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitForm,
              child: const Text('Add Transaction'),
            ),
          ],
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      final transaction = Transaction(
        id: DateTime.now().toString(), // In production, use UUID
        description: _descriptionController.text,
        amount: double.parse(_amountController.text),
        date: _selectedDate,
        type: _type,
      );

      context.read<TransactionBloc>().add(AddTransaction(transaction));
      Navigator.pop(context);
    }
  }
}
```

### 2. Update HomeScreen

Modify the FloatingActionButton in `lib/features/home/presentation/screens/home_screen.dart`:

```dart
floatingActionButton: FloatingActionButton(
  onPressed: () {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return const AddTransactionForm();
      },
    );
  },
  child: const Icon(Icons.add),
),
```

### 3. Error Handling

Add BlocListener to handle errors in HomeScreen:

```dart
@override
Widget build(BuildContext context) {
  return BlocListener<TransactionBloc, TransactionState>(
    listener: (context, state) {
      if (state is TransactionError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    },
    child: Scaffold(
      // ... existing scaffold content
    ),
  );
}
```

## Usage Example

1. Press the FloatingActionButton (+ icon)
2. Fill in the transaction details:
   - Description (e.g., "Grocery shopping")
   - Amount (e.g., "45.99")
   - Select type (Expense/Income)
   - Choose date
3. Press "Add Transaction"
4. The new transaction appears in the list

## Form Validation

The form validates:
- Description is not empty
- Amount is a valid number
- Amount is not empty
- Date is not in the future

## Error Cases

1. Invalid Input:
   - Empty fields
   - Invalid number format
   - Future dates

2. BLoC Errors:
   - Repository errors
   - Database errors
   - Network errors (if implemented)

## Testing

Example test cases:

```dart
void main() {
  group('AddTransactionForm', () {
    testWidgets('validates empty fields', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AddTransactionForm(),
        ),
      ));

      await tester.tap(find.text('Add Transaction'));
      await tester.pump();

      expect(find.text('Please enter a description'), findsOneWidget);
      expect(find.text('Please enter an amount'), findsOneWidget);
    });

    testWidgets('submits valid form', (tester) async {
      // Test implementation
    });
  });
}
```

## Next Steps

1. Add transaction categories
2. Implement recurring transactions
3. Add image attachments for receipts
4. Add notes field
5. Implement transaction templates
6. Add budget limits warning

## Best Practices

1. **Form Validation**:
   - Validate input before submission
   - Show clear error messages
   - Prevent future dates
   - Format currency input

2. **User Experience**:
   - Use appropriate keyboard types
   - Show loading state during submission
   - Provide clear feedback
   - Maintain form state

3. **Error Handling**:
   - Handle all possible error cases
   - Show user-friendly error messages
   - Provide recovery options
   - Log errors for debugging

4. **State Management**:
   - Use BLoC for state management
   - Handle loading states
   - Update UI after successful submission
   - Clean up resources

## Related Documentation

- [Basic BLoC Implementation](basic-bloc-implementation.md)
- [Transaction Model](../lib/features/home/domain/models/transaction.dart)
- [Material Design Bottom Sheets](https://material.io/components/sheets-bottom)