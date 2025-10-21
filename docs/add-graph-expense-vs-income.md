# Expense vs Income Statistics Feature Specification

## Overview

The statistics feature provides users with visual insights into their financial data through an interactive pie chart showing the proportion of income versus expenses. This feature helps users understand their spending patterns and financial health at a glance.

## Feature Requirements

### User Interface

1. **Navigation**
   - Add statistics button/icon in home screen app bar
   - Navigate to dedicated statistics screen
   - Material Design 3 consistent styling

2. **Statistics Screen**
   - Clean, focused layout with pie chart as primary element
   - Summary cards showing total income and expenses
   - Date range selector for filtering data
   - Empty state when no transactions exist

3. **Pie Chart Visualization**
   - Interactive pie chart using fl_chart package
   - Income shown in green (#4CAF50)
   - Expenses shown in red (#F44336)
   - Percentage labels on chart segments
   - Legend showing amounts and percentages
   - Touch interactions to highlight segments

### Functionality

1. **Data Aggregation**
   ```dart
   class FinancialSummary {
     final double totalIncome;
     final double totalExpenses;
     final double netBalance;
     final DateTime startDate;
     final DateTime endDate;
     
     const FinancialSummary({
       required this.totalIncome,
       required this.totalExpenses,
       required this.netBalance,
       required this.startDate,
       required this.endDate,
     });
     
     double get incomePercentage => 
       totalIncome / (totalIncome + totalExpenses) * 100;
     
     double get expensePercentage => 
       totalExpenses / (totalIncome + totalExpenses) * 100;
   }
   ```

2. **Date Filtering**
   - Current month (default)
   - Last 3 months
   - Last 6 months
   - Last year
   - All time
   - Custom date range picker

3. **State Management**
   ```dart
   // New BLoC Events
   class LoadStatistics extends StatisticsEvent {
     final DateTime startDate;
     final DateTime endDate;
     
     const LoadStatistics({
       required this.startDate,
       required this.endDate,
     });
   }
   
   class RefreshStatistics extends StatisticsEvent {}
   
   // New BLoC States
   abstract class StatisticsState extends Equatable {
     const StatisticsState();
   }
   
   class StatisticsInitial extends StatisticsState {}
   
   class StatisticsLoading extends StatisticsState {}
   
   class StatisticsLoaded extends StatisticsState {
     final FinancialSummary summary;
     final List<Transaction> transactions;
     
     const StatisticsLoaded({
       required this.summary,
       required this.transactions,
     });
   }
   
   class StatisticsError extends StatisticsState {
     final String message;
     
     const StatisticsError(this.message);
   }
   ```

## UI/UX Specifications

### Statistics Screen Layout

1. **App Bar**
   ```dart
   AppBar(
     title: const Text('Statistics'),
     centerTitle: true,
     actions: [
       IconButton(
         icon: const Icon(Icons.refresh),
         onPressed: () => context.read<StatisticsBloc>()
           .add(RefreshStatistics()),
       ),
     ],
   )
   ```

2. **Date Range Selector**
   ```dart
   class DateRangeSelector extends StatelessWidget {
     final DateTimeRange selectedRange;
     final Function(DateTimeRange) onRangeChanged;
     
     // Dropdown with predefined ranges + custom option
     // Material Design 3 chips for quick selection
   }
   ```

3. **Summary Cards**
   ```dart
   class FinancialSummaryCards extends StatelessWidget {
     final FinancialSummary summary;
     
     // Three cards: Total Income, Total Expenses, Net Balance
     // Color-coded: green for income, red for expenses, 
     // blue/green for positive balance, red for negative
   }
   ```

4. **Pie Chart Widget**
   ```dart
   class ExpenseIncomeChart extends StatefulWidget {
     final FinancialSummary summary;
     final bool showPercentages;
     
     // Interactive pie chart with touch callbacks
     // Animated transitions when data changes
     // Responsive sizing for different screen sizes
   }
   ```

### Chart Specifications

1. **Visual Design**
   - Minimum 250px diameter, scales with screen size
   - 8dp spacing between segments
   - Material Design 3 color palette
   - Smooth animations (300ms duration)
   - Drop shadow for depth

2. **Interactivity**
   - Touch to highlight segments
   - Show exact values on touch
   - Smooth rotation animation on selection
   - Haptic feedback on interaction (mobile)

3. **Accessibility**
   - Screen reader support with meaningful labels
   - High contrast mode support
   - Semantic labels for chart data
   - Focus indicators for keyboard navigation

## Technical Implementation

### 1. Repository Layer Extensions

**Required Update to TransactionRepository**

First, extend the existing TransactionRepository interface to support date range filtering:

```dart
abstract class TransactionRepository {
  Future<List<Transaction>> getTransactions({int? limit, int? offset});
  Future<Transaction> addTransaction(Transaction transaction);
  Future<void> deleteTransaction(String id);
  Future<Transaction> updateTransaction(Transaction transaction);
  
  // New method required for statistics
  Future<List<Transaction>> getTransactionsInRange({
    required DateTime startDate,
    required DateTime endDate,
  });
}
```

**Update InMemoryTransactionRepository implementation**:

```dart
class InMemoryTransactionRepository implements TransactionRepository {
  // ... existing methods ...
  
  @override
  Future<List<Transaction>> getTransactionsInRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final sortedTransactions = List<Transaction>.from(_transactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    
    return sortedTransactions.where((transaction) {
      final transactionDate = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      final start = DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(endDate.year, endDate.month, endDate.day);
      
      return (transactionDate.isAtSameMomentAs(start) || transactionDate.isAfter(start)) &&
             (transactionDate.isAtSameMomentAs(end) || transactionDate.isBefore(end));
    }).toList();
  }
}
```

**Statistics Repository Implementation**:

```dart
abstract class StatisticsRepository {
  Future<FinancialSummary> getFinancialSummary({
    required DateTime startDate,
    required DateTime endDate,
  });
  
  Future<List<Transaction>> getTransactionsInRange({
    required DateTime startDate,
    required DateTime endDate,
  });
}

class StatisticsRepositoryImpl implements StatisticsRepository {
  final TransactionRepository transactionRepository;
  
  const StatisticsRepositoryImpl({
    required this.transactionRepository,
  });
  
  @override
  Future<List<Transaction>> getTransactionsInRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return await transactionRepository.getTransactionsInRange(
      startDate: startDate,
      endDate: endDate,
    );
  }
  
  @override
  Future<FinancialSummary> getFinancialSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
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
    
    return FinancialSummary(
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      netBalance: totalIncome - totalExpenses,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
```

### 2. BLoC Implementation

```dart
class StatisticsBloc extends Bloc<StatisticsEvent, StatisticsState> {
  final StatisticsRepository repository;
  
  StatisticsBloc({required this.repository}) : super(StatisticsInitial()) {
    on<LoadStatistics>(_onLoadStatistics);
    on<RefreshStatistics>(_onRefreshStatistics);
  }
  
  Future<void> _onLoadStatistics(
    LoadStatistics event,
    Emitter<StatisticsState> emit,
  ) async {
    emit(StatisticsLoading());
    try {
      final summary = await repository.getFinancialSummary(
        startDate: event.startDate,
        endDate: event.endDate,
      );
      
      final transactions = await repository.getTransactionsInRange(
        startDate: event.startDate,
        endDate: event.endDate,
      );
      
      emit(StatisticsLoaded(
        summary: summary,
        transactions: transactions,
      ));
    } catch (e) {
      emit(StatisticsError(e.toString()));
    }
  }
  
  Future<void> _onRefreshStatistics(
    RefreshStatistics event,
    Emitter<StatisticsState> emit,
  ) async {
    if (state is StatisticsLoaded) {
      final currentState = state as StatisticsLoaded;
      add(LoadStatistics(
        startDate: currentState.summary.startDate,
        endDate: currentState.summary.endDate,
      ));
    } else {
      // Default to current month if no previous state
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);
      
      add(LoadStatistics(
        startDate: startOfMonth,
        endDate: endOfMonth,
      ));
    }
  }
}
```

### 3. Chart Implementation

```dart
class ExpenseIncomeChart extends StatefulWidget {
  final FinancialSummary summary;
  
  const ExpenseIncomeChart({
    super.key,
    required this.summary,
  });
  
  @override
  State<ExpenseIncomeChart> createState() => _ExpenseIncomeChartState();
}

class _ExpenseIncomeChartState extends State<ExpenseIncomeChart> {
  int touchedIndex = -1;
  
  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.3,
      child: PieChart(
        PieChartData(
          pieTouchData: PieTouchData(
            touchCallback: (FlTouchEvent event, pieTouchResponse) {
              setState(() {
                if (!event.isInterestedForInteractions ||
                    pieTouchResponse == null ||
                    pieTouchResponse.touchedSection == null) {
                  touchedIndex = -1;
                  return;
                }
                touchedIndex = pieTouchResponse
                    .touchedSection!.touchedSectionIndex;
              });
            },
          ),
          borderData: FlBorderData(show: false),
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: showingSections(),
        ),
      ),
    );
  }
  
  List<PieChartSectionData> showingSections() {
    final total = widget.summary.totalIncome + widget.summary.totalExpenses;
    if (total == 0) return [];
    
    return List.generate(2, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 25.0 : 16.0;
      final radius = isTouched ? 60.0 : 50.0;
      
      switch (i) {
        case 0:
          return PieChartSectionData(
            color: Colors.green,
            value: widget.summary.totalIncome,
            title: '${(widget.summary.incomePercentage).toStringAsFixed(1)}%',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        case 1:
          return PieChartSectionData(
            color: Colors.red,
            value: widget.summary.totalExpenses,
            title: '${(widget.summary.expensePercentage).toStringAsFixed(1)}%',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        default:
          throw Error();
      }
    });
  }
}
```

## Navigation Integration

### Home Screen App Bar Update

```dart
class HomePage extends StatefulWidget {
  // ... existing code
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      // ... rest of the widget
    );
  }
}
```

### Router Updates

```dart
class AppRouter {
  static const String home = '/';
  static const String statistics = '/statistics';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(
          builder: (_) => const HomePage(),
        );
      case statistics:
        return MaterialPageRoute(
          builder: (_) => const StatisticsPage(),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
```

## Error Handling

1. **No Data State**
   - Empty state illustration
   - Helpful message encouraging user to add transactions
   - Quick action button to add first transaction

2. **Network/Database Errors**
   - Error state with retry button
   - Toast messages for transient errors
   - Graceful fallback to cached data when available

3. **Invalid Date Ranges**
   - Validation on date range selection
   - Meaningful error messages
   - Auto-correction for invalid ranges

## Performance Considerations

1. **Data Loading**
   - Lazy loading for large datasets
   - Background data fetching
   - Smart caching of computed statistics
   - Debounced date range changes

2. **Chart Rendering**
   - Efficient repainting on data changes
   - Smooth animations without blocking UI
   - Responsive design for various screen sizes
   - Memory management for chart resources

## Testing Strategy

### Unit Tests
```dart
void main() {
  group('StatisticsRepository', () {
    test('calculates correct financial summary', () async {
      // Test aggregation logic
    });
    
    test('handles empty transaction list', () async {
      // Test edge case
    });
  });
  
  group('StatisticsBloc', () {
    blocTest<StatisticsBloc, StatisticsState>(
      'emits [loading, loaded] when LoadStatistics is added',
      build: () => statisticsBloc,
      act: (bloc) => bloc.add(LoadStatistics(
        startDate: DateTime.now().subtract(Duration(days: 30)),
        endDate: DateTime.now(),
      )),
      expect: () => [
        StatisticsLoading(),
        isA<StatisticsLoaded>(),
      ],
    );
  });
}
```

### Widget Tests
```dart
void main() {
  group('StatisticsPage', () {
    testWidgets('displays pie chart when data is loaded', (tester) async {
      // Test chart rendering
    });
    
    testWidgets('shows empty state when no transactions', (tester) async {
      // Test empty state
    });
    
    testWidgets('updates chart when date range changes', (tester) async {
      // Test filtering
    });
  });
}
```

## Accessibility

1. **Screen Reader Support**
   - Semantic labels for chart segments
   - Meaningful descriptions of financial data
   - Navigation announcements

2. **Keyboard Navigation**
   - Tab order through interactive elements
   - Keyboard shortcuts for date range selection
   - Focus indicators

3. **Visual Accessibility**
   - High contrast color support
   - Scalable text and UI elements
   - Color-blind friendly palette options

## Security Considerations

1. **Data Privacy**
   - No sensitive financial data in logs
   - Secure caching of statistics
   - Memory cleanup after navigation

2. **Input Validation**
   - Date range validation
   - Numerical data sanitization
   - SQL injection prevention (if using SQL)

## Future Enhancements

### Phase 1: Basic Implementation
- Simple pie chart with income/expense breakdown
- Current month view
- Basic navigation

### Phase 2: Enhanced Filtering
- Custom date ranges
- Category-wise breakdowns
- Multiple chart types (bar, line)

### Phase 3: Advanced Analytics
- Trend analysis
- Spending patterns
- Budget vs actual comparisons
- Export functionality

### Phase 4: Interactive Features
- Drill-down capabilities
- Comparative analysis
- Goal tracking integration
- Sharing functionality

## Dependencies

**Required Updates to pubspec.yaml**:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Existing dependencies
  cupertino_icons: ^1.0.8
  flutter_bloc: ^8.1.3
  bloc: ^8.1.2
  equatable: ^2.0.5
  shimmer: ^3.0.0
  grouped_list: ^5.1.2
  intl: ^0.18.1
  
  # New dependency for charts
  fl_chart: ^0.68.0  # For pie chart visualization
```

**BLoC Provider Integration**:

Update main.dart to include StatisticsBloc:

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

## File Structure

```
lib/features/statistics/
├── data/
│   └── repositories/
│       └── statistics_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── financial_summary.dart
│   └── repositories/
│       └── statistics_repository.dart
└── presentation/
    ├── bloc/
    │   ├── statistics_bloc.dart
    │   ├── statistics_event.dart
    │   └── statistics_state.dart
    ├── pages/
    │   └── statistics_page.dart
    └── widgets/
        ├── date_range_selector.dart
        ├── expense_income_chart.dart
        ├── financial_summary_cards.dart
        └── statistics_empty_view.dart

# Required Updates to Existing Files:
lib/features/transaction/domain/repositories/transaction_repository.dart
lib/features/transaction/data/repositories/in_memory_transaction_repository.dart  
lib/core/router/app_router.dart
lib/main.dart
pubspec.yaml
```

## Implementation Steps

### Step 1: Update Existing Codebase
1. **Update TransactionRepository interface** (add `getTransactionsInRange` method)
2. **Update InMemoryTransactionRepository** (implement new method)
3. **Update AppRouter** (add statistics route)
4. **Update pubspec.yaml** (add fl_chart dependency)
5. **Update main.dart** (add StatisticsBloc to providers)

### Step 2: Implement Statistics Feature
1. **Create FinancialSummary entity** (domain layer)
2. **Create StatisticsRepository** (domain and data layers)
3. **Create StatisticsBloc** (presentation layer)
4. **Create StatisticsPage** (presentation layer)
5. **Create Chart and UI widgets** (presentation layer)

### Step 3: Integration
1. **Update HomePage** (add statistics button)
2. **Test integration** (verify data flow)
3. **Handle edge cases** (empty data, errors)

## Implementation Priority

1. **High Priority** (Required for basic functionality)
   - Repository method extensions
   - BLoC provider setup
   - Basic pie chart implementation
   - Current month statistics
   - Navigation from home screen

2. **Medium Priority** (Enhanced user experience)
   - Date range filtering
   - Error handling
   - Loading states
   - Empty state handling

3. **Low Priority** (Polish and advanced features)
   - Advanced animations
   - Multiple chart types
   - Export functionality
   - Accessibility enhancements

This specification provides a comprehensive guide for implementing the expense vs income statistics feature, ensuring consistency with the existing architecture while providing valuable financial insights to users. The implementation follows clean architecture principles and maintains compatibility with the current codebase structure.