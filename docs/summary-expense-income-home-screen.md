# Summary Cards Feature Specification for Home Screen

## Overview

This feature adds financial summary cards to the bottom of the home screen, providing users with a quick overview of their income and expenses. The summary is filterable by month and displays total amounts in an easily digestible card layout, enabling users to quickly assess their financial status without navigating to a separate screen.

## Architecture Compliance

This specification follows the existing codebase architecture with clean architecture principles, proper BLoC pattern implementation, and consistent repository design patterns established in the transaction feature.

## Feature Requirements

### User Interface

1. **Card Layout**
   - Two horizontal cards displaying Income and Expense summaries
   - Material Design 3 cards with elevation and rounded corners
   - Color-coded: Green for income, Red for expenses
   - Positioned at the bottom of the home screen, above the FAB
   - Responsive design that adapts to different screen sizes

2. **Card Content**
   - Large, prominent amount display
   - Clear labels ("Total Income", "Total Expenses")
   - Icons to enhance visual recognition
   - Month/period indicator
   - Subtle background gradients or colors

3. **Month Filter**
   - Month selector dropdown or chip-based filter
   - Default to current month
   - Quick navigation between months
   - Visual indication of selected month

### Functionality

1. **Data Aggregation**
   ```dart
   // lib/features/home/domain/entities/monthly_summary.dart
   import 'package:equatable/equatable.dart';

   class MonthlySummary extends Equatable {
     final double totalIncome;
     final double totalExpenses;
     final double netBalance;
     final DateTime month;
     final int transactionCount;
     
     const MonthlySummary({
       required this.totalIncome,
       required this.totalExpenses,
       required this.netBalance,
       required this.month,
       required this.transactionCount,
     });
     
     double get savingsRate => totalIncome > 0 
       ? ((totalIncome - totalExpenses) / totalIncome) * 100 
       : 0;

     bool get hasData => totalIncome > 0 || totalExpenses > 0;

     @override
     List<Object?> get props => [
       totalIncome,
       totalExpenses,
       netBalance,
       month,
       transactionCount,
     ];

     MonthlySummary copyWith({
       double? totalIncome,
       double? totalExpenses,
       double? netBalance,
       DateTime? month,
       int? transactionCount,
     }) {
       return MonthlySummary(
         totalIncome: totalIncome ?? this.totalIncome,
         totalExpenses: totalExpenses ?? this.totalExpenses,
         netBalance: netBalance ?? this.netBalance,
         month: month ?? this.month,
         transactionCount: transactionCount ?? this.transactionCount,
       );
     }
   }
   ```

2. **Month Filtering**
   - Filter transactions by selected month and year
   - Persistent month selection across app sessions
   - Smooth transitions when changing months
   - Loading states during data aggregation

3. **Real-time Updates**
   - Automatic refresh when transactions are added/edited/deleted
   - Smooth animations for value changes
   - Optimistic updates for immediate feedback

## Technical Implementation

### 1. Repository Layer

**Create dedicated SummaryRepository following clean architecture:**

```dart
// lib/features/home/domain/repositories/summary_repository.dart
import '../entities/monthly_summary.dart';

abstract class SummaryRepository {
  Future<MonthlySummary> getMonthlySummary({
    required int year,
    required int month,
  });
}
```

**Repository Implementation:**

```dart
// lib/features/home/data/repositories/summary_repository_impl.dart
import '../../domain/entities/monthly_summary.dart';
import '../../domain/repositories/summary_repository.dart';
import '../../../transaction/domain/repositories/transaction_repository.dart';
import '../../../transaction/domain/entities/transaction.dart';

class SummaryRepositoryImpl implements SummaryRepository {
  final TransactionRepository transactionRepository;

  const SummaryRepositoryImpl({
    required this.transactionRepository,
  });

  @override
  Future<MonthlySummary> getMonthlySummary({
    required int year,
    required int month,
  }) async {
    // Use existing getTransactionsInRange method
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);
    
    final transactions = await transactionRepository.getTransactionsInRange(
      startDate: startDate,
      endDate: endDate,
    );
    
    double totalIncome = 0;
    double totalExpenses = 0;
    
    for (final transaction in transactions) {
      if (transaction.type == TransactionType.income) {
        totalIncome += transaction.amount;
      } else {
        totalExpenses += transaction.amount;
      }
    }
    
    return MonthlySummary(
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      netBalance: totalIncome - totalExpenses,
      month: startDate,
      transactionCount: transactions.length,
    );
  }
}
```

### 2. BLoC Implementation

**Events:**
```dart
// lib/features/home/presentation/bloc/summary_event.dart
import 'package:equatable/equatable.dart';

abstract class SummaryEvent extends Equatable {
  const SummaryEvent();

  @override
  List<Object> get props => [];
}

class LoadMonthlySummary extends SummaryEvent {
  final int year;
  final int month;
  
  const LoadMonthlySummary({
    required this.year,
    required this.month,
  });
  
  @override
  List<Object> get props => [year, month];
}

class RefreshMonthlySummary extends SummaryEvent {
  const RefreshMonthlySummary();
}
```

**States:**
```dart
// lib/features/home/presentation/bloc/summary_state.dart
import 'package:equatable/equatable.dart';
import '../../domain/entities/monthly_summary.dart';

abstract class SummaryState extends Equatable {
  const SummaryState();

  @override
  List<Object> get props => [];
}

class SummaryInitial extends SummaryState {
  const SummaryInitial();
}

class SummaryLoading extends SummaryState {
  const SummaryLoading();
}

class SummaryLoaded extends SummaryState {
  final MonthlySummary summary;
  
  const SummaryLoaded(this.summary);
  
  @override
  List<Object> get props => [summary];
}

class SummaryError extends SummaryState {
  final String message;
  
  const SummaryError(this.message);
  
  @override
  List<Object> get props => [message];
}
```

**BLoC:**
```dart
// lib/features/home/presentation/bloc/summary_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/summary_repository.dart';
import 'summary_event.dart';
import 'summary_state.dart';

class SummaryBloc extends Bloc<SummaryEvent, SummaryState> {
  final SummaryRepository repository;

  SummaryBloc({required this.repository}) : super(const SummaryInitial()) {
    on<LoadMonthlySummary>(_onLoadMonthlySummary);
    on<RefreshMonthlySummary>(_onRefreshMonthlySummary);
  }

  Future<void> _onLoadMonthlySummary(
    LoadMonthlySummary event,
    Emitter<SummaryState> emit,
  ) async {
    emit(const SummaryLoading());
    try {
      final summary = await repository.getMonthlySummary(
        year: event.year,
        month: event.month,
      );
      emit(SummaryLoaded(summary));
    } catch (e) {
      emit(SummaryError(e.toString()));
    }
  }

  Future<void> _onRefreshMonthlySummary(
    RefreshMonthlySummary event,
    Emitter<SummaryState> emit,
  ) async {
    if (state is SummaryLoaded) {
      final currentState = state as SummaryLoaded;
      add(LoadMonthlySummary(
        year: currentState.summary.month.year,
        month: currentState.summary.month.month,
      ));
    } else {
      // Default to current month
      final now = DateTime.now();
      add(LoadMonthlySummary(
        year: now.year,
        month: now.month,
      ));
    }
  }
}
```

### 3. Widget Implementation

**Summary Cards Widget:**
```dart
// lib/features/home/presentation/widgets/summary_cards.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/monthly_summary.dart';
import '../bloc/summary_bloc.dart';
import '../bloc/summary_event.dart';
import 'month_selector.dart';
import 'income_card.dart';
import 'expense_card.dart';

class SummaryCards extends StatelessWidget {
  final MonthlySummary summary;
  final Function(DateTime) onMonthChanged;
  
  const SummaryCards({
    super.key,
    required this.summary,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          MonthSelector(
            selectedMonth: summary.month,
            onMonthChanged: onMonthChanged,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: IncomeCard(
                  amount: summary.totalIncome,
                  transactionCount: _getIncomeTransactionCount(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ExpenseCard(
                  amount: summary.totalExpenses,
                  transactionCount: _getExpenseTransactionCount(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _getIncomeTransactionCount() {
    // This would be calculated from the repository
    // For now, returning a placeholder
    return 0;
  }

  int _getExpenseTransactionCount() {
    // This would be calculated from the repository
    // For now, returning a placeholder
    return 0;
  }
}
```

**Individual Card Implementations:**
```dart
// lib/features/home/presentation/widgets/income_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class IncomeCard extends StatelessWidget {
  final double amount;
  final int transactionCount;
  
  const IncomeCard({
    super.key,
    required this.amount,
    required this.transactionCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.green.withOpacity(0.1),
              Colors.green.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Income',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              currencyFormat.format(amount),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$transactionCount transactions',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 4. Home Screen Integration

```dart
// Updated lib/features/transaction/presentation/pages/home_page.dart
class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionBloc>().add(const LoadTransactions());
      
      // Load current month summary
      final now = DateTime.now();
      context.read<SummaryBloc>().add(LoadMonthlySummary(
        year: now.year,
        month: now.month,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TransactionBloc, TransactionState>(
      listener: (context, state) {
        // Auto-refresh summary when transactions change
        if (state is TransactionLoaded) {
          context.read<SummaryBloc>().add(const RefreshMonthlySummary());
        }
        
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
        appBar: AppBar(
          title: const Text('Mero Budget Tracker'),
          actions: [
            IconButton(
              icon: const Icon(Icons.analytics_outlined),
              onPressed: () => Navigator.pushNamed(context, AppRouter.statistics),
              tooltip: 'View Statistics',
            ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {
                // TODO: Show filter options
              },
            ),
            IconButton(
              icon: const Icon(Icons.sort),
              onPressed: () {
                // TODO: Show sort options
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Existing transaction list
            Expanded(
              child: BlocBuilder<TransactionBloc, TransactionState>(
                builder: (context, state) {
                  if (state is TransactionLoading) {
                    return const TransactionLoadingView();
                  }

                  if (state is TransactionError) {
                    return TransactionErrorView(
                      message: state.message,
                      onRetry: () => context.read<TransactionBloc>()
                        .add(const LoadTransactions()),
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
            ),
            
            // Summary cards section
            BlocBuilder<SummaryBloc, SummaryState>(
              builder: (context, state) {
                if (state is SummaryLoading) {
                  return const SummaryCardsLoading();
                }
                if (state is SummaryLoaded) {
                  return SummaryCards(
                    summary: state.summary,
                    onMonthChanged: (month) {
                      context.read<SummaryBloc>().add(LoadMonthlySummary(
                        year: month.year,
                        month: month.month,
                      ));
                    },
                  );
                }
                if (state is SummaryError) {
                  return SummaryCardsError(
                    error: state.message,
                    onRetry: () {
                      final now = DateTime.now();
                      context.read<SummaryBloc>().add(LoadMonthlySummary(
                        year: now.year,
                        month: now.month,
                      ));
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (context) => const AddTransactionSheet(),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context, Transaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => EditTransactionSheet(transaction: transaction),
    );
  }
}
```

### 5. Dependency Injection

**Update main.dart:**
```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final transactionRepository = InMemoryTransactionRepository();
    
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => TransactionBloc(
            repository: transactionRepository,
          )..add(const LoadTransactions()),
        ),
        BlocProvider(
          create: (context) => StatisticsBloc(
            repository: StatisticsRepositoryImpl(
              transactionRepository: transactionRepository,
            ),
          ),
        ),
        BlocProvider(
          create: (context) => SummaryBloc(
            repository: SummaryRepositoryImpl(
              transactionRepository: transactionRepository,
            ),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Mero Budget Tracker',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        onGenerateRoute: AppRouter.onGenerateRoute,
        initialRoute: AppRouter.home,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
```

## UI/UX Specifications

### Month Selector Widget

```dart
// lib/features/home/presentation/widgets/month_selector.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MonthSelector extends StatelessWidget {
  final DateTime selectedMonth;
  final Function(DateTime) onMonthChanged;
  
  const MonthSelector({
    super.key,
    required this.selectedMonth,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 12,
        itemBuilder: (context, index) {
          final month = DateTime(
            selectedMonth.year,
            index + 1,
            1,
          );
          final isSelected = month.month == selectedMonth.month &&
                            month.year == selectedMonth.year;
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              selected: isSelected,
              label: Text(DateFormat('MMM').format(month)),
              onSelected: (selected) {
                if (selected) {
                  onMonthChanged(month);
                }
              },
            ),
          );
        },
      ),
    );
  }
}
```

## Error Handling & Loading States

### Loading State Widget
```dart
// lib/features/home/presentation/widgets/summary_cards_loading.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SummaryCardsLoading extends StatelessWidget {
  const SummaryCardsLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: _buildSkeletonCard()),
          const SizedBox(width: 12),
          Expanded(child: _buildSkeletonCard()),
        ],
      ),
    );
  }
  
  Widget _buildSkeletonCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 20,
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 32,
                width: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 16,
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Error State Widget
```dart
// lib/features/home/presentation/widgets/summary_cards_error.dart
import 'package:flutter/material.dart';

class SummaryCardsError extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  
  const SummaryCardsError({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                color: theme.colorScheme.error,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load summary',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

## File Structure

```
lib/features/home/
├── data/
│   └── repositories/
│       └── summary_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── monthly_summary.dart
│   └── repositories/
│       └── summary_repository.dart
└── presentation/
    ├── bloc/
    │   ├── summary_bloc.dart
    │   ├── summary_event.dart
    │   └── summary_state.dart
    └── widgets/
        ├── summary_cards.dart
        ├── income_card.dart
        ├── expense_card.dart
        ├── month_selector.dart
        ├── summary_cards_loading.dart
        └── summary_cards_error.dart

# Required Updates to Existing Files:
lib/features/transaction/presentation/pages/home_page.dart
lib/main.dart
```

## Testing Strategy

### Unit Tests
```dart
// test/features/home/domain/entities/monthly_summary_test.dart
void main() {
  group('MonthlySummary', () {
    test('calculates savings rate correctly', () {
      final summary = MonthlySummary(
        totalIncome: 5000,
        totalExpenses: 3000,
        netBalance: 2000,
        month: DateTime(2024, 1, 1),
        transactionCount: 10,
      );
      
      expect(summary.savingsRate, equals(40.0));
    });

    test('returns 0 savings rate when no income', () {
      final summary = MonthlySummary(
        totalIncome: 0,
        totalExpenses: 1000,
        netBalance: -1000,
        month: DateTime(2024, 1, 1),
        transactionCount: 5,
      );
      
      expect(summary.savingsRate, equals(0));
    });

    test('copyWith creates new instance with updated values', () {
      final original = MonthlySummary(
        totalIncome: 5000,
        totalExpenses: 3000,
        netBalance: 2000,
        month: DateTime(2024, 1, 1),
        transactionCount: 10,
      );
      
      final updated = original.copyWith(totalIncome: 6000);
      
      expect(updated.totalIncome, equals(6000));
      expect(updated.totalExpenses, equals(3000));
      expect(updated != original, isTrue);
    });
  });
}

// test/features/home/presentation/bloc/summary_bloc_test.dart
void main() {
  group('SummaryBloc', () {
    late SummaryBloc summaryBloc;
    late MockSummaryRepository mockRepository;

    setUp(() {
      mockRepository = MockSummaryRepository();
      summaryBloc = SummaryBloc(repository: mockRepository);
    });

    tearDown(() {
      summaryBloc.close();
    });

    test('initial state is SummaryInitial', () {
      expect(summaryBloc.state, equals(const SummaryInitial()));
    });

    blocTest<SummaryBloc, SummaryState>(
      'emits [SummaryLoading, SummaryLoaded] when LoadMonthlySummary is added',
      build: () => summaryBloc,
      act: (bloc) => bloc.add(const LoadMonthlySummary(year: 2024, month: 1)),
      expect: () => [
        const SummaryLoading(),
        isA<SummaryLoaded>(),
      ],
    );
  });
}
```

### Widget Tests
```dart
// test/features/home/presentation/widgets/summary_cards_test.dart
void main() {
  group('SummaryCards', () {
    testWidgets('displays income and expense amounts correctly', (tester) async {
      final summary = MonthlySummary(
        totalIncome: 5000,
        totalExpenses: 3000,
        netBalance: 2000,
        month: DateTime(2024, 1, 1),
        transactionCount: 10,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummaryCards(
              summary: summary,
              onMonthChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('\$5,000.00'), findsOneWidget);
      expect(find.text('\$3,000.00'), findsOneWidget);
    });
  });
}
```

## Performance Considerations

1. **Efficient Calculations**
   - Leverage existing transaction filtering methods
   - Cache monthly summaries using SharedPreferences
   - Use const constructors where possible

2. **Smooth Animations**
   - Use AnimatedContainer for value changes
   - Implement custom AnimatedWidget for smooth transitions
   - Optimize rebuild cycles with proper BLoC selectors

3. **Memory Management**
   - Dispose BLoC properly
   - Clean up listeners and streams
   - Use efficient data structures

## Dependencies

All dependencies are already included in the existing project:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5
  intl: ^0.18.1
  shimmer: ^3.0.0  # Already included
```

## Implementation Priority

### Phase 1: Core Implementation (High Priority)
1. Create MonthlySummary entity with proper Equatable implementation
2. Implement SummaryRepository following clean architecture
3. Create SummaryBloc with proper event/state management
4. Add basic summary cards to home screen
5. Implement month selection functionality

### Phase 2: Enhanced UI/UX (Medium Priority)
1. Add loading and error states with proper widgets
2. Implement smooth animations and transitions
3. Add visual improvements (gradients, better typography)
4. Optimize for different screen sizes and orientations

### Phase 3: Advanced Features (Low Priority)
1. Add persistent month selection (SharedPreferences)
2. Implement swipe gestures for month navigation
3. Add tap-to-view-details functionality
4. Performance optimizations and caching

This specification now follows the existing codebase architecture with proper clean architecture principles, dedicated BLoC implementation, and consistent patterns established in the transaction feature.