# List Transactions Feature Specification

## Overview
This document outlines the implementation details for displaying transactions in the home screen of the Mero Budget Tracker app.

## UI Components

### 1. Transaction List Widget
```dart
class TransactionListView extends StatelessWidget {
  final List<Transaction> transactions;
  final Function(String) onDelete;
  final Function(Transaction) onEdit;

  // Implementation details below
}
```

### 2. Transaction Card/Tile
```dart
class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  // Displays:
  // - Amount with color (green for income, red for expense)
  // - Description
  // - Date
  // - Category (future)
  // - Transaction type icon
}
```

## Features

### 1. Basic Listing
- Chronological order (newest first by default)
  - Transaction dates in descending order (latest on top)
  - Group by date with date headers
  - Option to switch between ascending/descending
  
- Pull to refresh functionality
  - Shows loading spinner while refreshing
  - Updates transaction list with latest data
  - Error handling with retry option
  - Visual feedback for success/failure
  
- Infinite scroll (pagination)
  - Load 20 transactions initially
  - Load more as user scrolls
  - Loading indicator at bottom
  - Cache previous pages
  - Smooth scrolling experience
  
- Empty state handling
  - Friendly message for no transactions
  - Add transaction suggestion
  - Illustration/icon for visual appeal
  - Clear call-to-action button
  
- Loading state
  - Shimmer effect for loading items
  - Placeholder transaction cards
  - Progress indicator
  - Cancelable loading state
  
- Error state
  - Clear error message display
  - Retry button
  - Offline indicator if applicable
  - Error details for debugging
  - Auto-retry option

### 2. Transaction Item Display
- Clear typography hierarchy
- Color coding by transaction type (income, expenses)
- Amount formatting
- Date formatting (Y-m-d)
- Swipe actions
- Material Design 3 elevation and shapes

### 3. Interactions
- Swipe left to show delete option
- Swipe right to show edit option
- Tap to view details of the single transaction
- Long press options menu to show list of available actions for the selected transaction

## Implementation Details

### 1. Home Screen Structure
```dart
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mero Budget Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Show filter options
            },
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {
              // Show sort options
            },
          ),
        ],
      ),
      body: BlocBuilder<TransactionBloc, TransactionState>(
        builder: (context, state) {
          if (state is TransactionLoading) {
            return const TransactionLoadingView();
          }
          
          if (state is TransactionError) {
            return TransactionErrorView(
              message: state.message,
              onRetry: () => context.read<TransactionBloc>()
                .add(LoadTransactions()),
            );
          }
          
          if (state is TransactionLoaded) {
            return TransactionListView(
              transactions: state.transactions,
              onDelete: (id) => context.read<TransactionBloc>()
                .add(DeleteTransaction(id)),
              onEdit: (transaction) => _showEditSheet(context, transaction),
            );
          }
          
          return const TransactionEmptyView();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

### 2. Transaction List Implementation
```dart
class TransactionListView extends StatelessWidget {
  const TransactionListView({
    super.key,
    required this.transactions,
    required this.onDelete,
    required this.onEdit,
  });

  final List<Transaction> transactions;
  final Function(String) onDelete;
  final Function(Transaction) onEdit;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<TransactionBloc>().add(LoadTransactions());
      },
      child: ListView.separated(
        itemCount: transactions.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final transaction = transactions[index];
          return Dismissible(
            key: Key(transaction.id),
            background: const DismissibleBackground(
              alignment: Alignment.centerLeft,
              color: Colors.green,
              icon: Icons.edit,
            ),
            secondaryBackground: const DismissibleBackground(
              alignment: Alignment.centerRight,
              color: Colors.red,
              icon: Icons.delete,
            ),
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.endToStart) {
                return await showDeleteConfirmation(context);
              }
              return false;
            },
            onDismissed: (direction) {
              if (direction == DismissDirection.endToStart) {
                onDelete(transaction.id);
              }
            },
            child: TransactionTile(
              transaction: transaction,
              onEdit: () => onEdit(transaction),
              onDelete: () => onDelete(transaction.id),
            ),
          );
        },
      ),
    );
  }
}
```

### 3. Transaction Tile Implementation
```dart
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
  });

  final Transaction transaction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncome = transaction.type == TransactionType.income;
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isIncome 
          ? Colors.green.withOpacity(0.2)
          : Colors.red.withOpacity(0.2),
        child: Icon(
          isIncome ? Icons.arrow_downward : Icons.arrow_upward,
          color: isIncome ? Colors.green : Colors.red,
        ),
      ),
      title: Text(
        transaction.description,
        style: theme.textTheme.titleMedium,
      ),
      subtitle: Text(
        _formatDate(transaction.date),
        style: theme.textTheme.bodySmall,
      ),
      trailing: Text(
        '\$${transaction.amount.toStringAsFixed(2)}',
        style: theme.textTheme.titleMedium?.copyWith(
          color: isIncome ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: () {
        // Show transaction details
      },
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          builder: (context) => TransactionOptionsSheet(
            onEdit: onEdit,
            onDelete: onDelete,
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
```

### 4. Supporting Views

#### Loading State
```dart
class TransactionLoadingView extends StatelessWidget {
  const TransactionLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}
```

#### Error State
```dart
class TransactionErrorView extends StatelessWidget {
  const TransactionErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
```

#### Empty State
```dart
class TransactionEmptyView extends StatelessWidget {
  const TransactionEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('No transactions yet. Add one to get started!'),
    );
  }
}
```

## Animation and Transitions

1. **List Item Animations**
   - Fade in new items
   - Slide out deleted items
   - Smooth reordering

2. **State Transitions**
   - Smooth loading indicator
   - Fade between states
   - Pull to refresh animation

## Performance Considerations

1. **List Optimization**
   - Use const constructors
   - Implement proper keys
   - Lazy loading for large lists
   - Pagination support

2. **Memory Management**
   - Cache management
   - Image optimization
   - Dispose controllers

## Testing Strategy

1. **Widget Tests**
```dart
void main() {
  group('TransactionListView', () {
    testWidgets('renders list of transactions', (tester) async {
      // Test implementation
    });

    testWidgets('shows empty state when no transactions', (tester) async {
      // Test implementation
    });

    testWidgets('handles refresh correctly', (tester) async {
      // Test implementation
    });
  });
}
```

2. **Integration Tests**
```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Transaction List', () {
    testWidgets('end-to-end test', (tester) async {
      // Test implementation
    });
  });
}
```

## Future Improvements

1. **Enhanced Filtering**
   - Date range selection
   - Category filtering
   - Amount range filtering
   - Search by description

2. **Advanced Sorting**
   - Multiple sort criteria
   - Custom sort orders
   - Sort preferences saving

3. **Visual Enhancements**
   - Category icons
   - Transaction tags
   - Custom themes
   - Animations

4. **Interaction Improvements**
   - Batch operations
   - Drag to reorder
   - Quick actions
   - Context menus

## Error Handling

1. **Network Errors**
   - Offline support
   - Retry mechanisms
   - Error messages

2. **Data Validation**
   - Input validation
   - Data integrity checks
   - Error recovery

3. **Edge Cases**
   - Empty states
   - Loading states
   - Error states
   - Boundary conditions

This specification provides a comprehensive guide for implementing the transaction listing feature. It covers UI components, interactions, performance considerations, and future improvements.