# SQLite Database Specification

## Overview

This document provides a detailed specification for the SQLite database implementation in the Mero Budget Tracker Flutter application. The application **already has a fully functional SQLite database** integrated into the codebase for managing transactions, categories, budgets, and preferences.

## Current Architecture

### Project Structure

The application follows a **clean architecture** pattern with clear separation of concerns:

```
lib/
├── core/
│   ├── database/
│   │   ├── database_helper.dart          # Low-level SQLite operations
│   │   ├── database_service.dart         # High-level database service
│   │   └── migration_manager.dart        # Database migrations
│   ├── router/                           # App routing
│   ├── theme/                            # App theming
│   ├── utils/                            # Utilities
│   └── widgets/                          # Shared widgets
├── features/
│   ├── transaction/
│   │   ├── data/
│   │   │   └── repositories/
│   │   │       ├── sqlite_transaction_repository.dart
│   │   │       └── in_memory_transaction_repository.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── transaction.dart      # Transaction entity
│   │   │   └── repositories/
│   │   │       └── transaction_repository.dart  # Repository interface
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   └── transaction_bloc.dart # BLoC for state management
│   │       ├── pages/                    # UI pages
│   │       └── widgets/                  # UI widgets
│   ├── home/                             # Home feature
│   ├── statistics/                       # Statistics feature
│   └── settings/                         # Settings feature
└── main.dart                             # App entry point
```

### Dependencies

The following packages are already configured in `pubspec.yaml`:

```yaml
dependencies:
  # State Management
  flutter_bloc: ^8.1.3
  bloc: ^8.1.2
  equatable: ^2.0.5
  
  # Database
  sqflite: ^2.3.0
  path: ^1.9.0
  
  # File System
  path_provider: ^2.1.1
```

## Database Schema

### Tables

The database consists of **4 main tables**:

#### 1. Transactions Table

Stores all income and expense transactions.

```sql
CREATE TABLE transactions (
  id TEXT PRIMARY KEY,
  description TEXT NOT NULL,
  amount REAL NOT NULL,
  date INTEGER NOT NULL,
  type TEXT NOT NULL,
  category_id TEXT,
  note TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY (category_id) REFERENCES categories (id)
    ON DELETE SET NULL
)
```

**Columns:**
- `id`: Unique identifier (TEXT) - Format: `txn_<timestamp>_<random>`
- `description`: Transaction description (TEXT, NOT NULL)
- `amount`: Transaction amount (REAL, NOT NULL)
- `date`: Transaction date in milliseconds since epoch (INTEGER, NOT NULL)
- `type`: Transaction type - "income" or "expense" (TEXT, NOT NULL)
- `category_id`: Foreign key to categories table (TEXT, nullable)
- `note`: Additional notes (TEXT, nullable)
- `created_at`: Creation timestamp in milliseconds (INTEGER, NOT NULL)
- `updated_at`: Last update timestamp in milliseconds (INTEGER, NOT NULL)

**Indexes:**
```sql
CREATE INDEX idx_transactions_date ON transactions (date DESC)
CREATE INDEX idx_transactions_type ON transactions (type)
CREATE INDEX idx_transactions_category ON transactions (category_id)
```

#### 2. Categories Table

Stores transaction categories (both system and user-defined).

```sql
CREATE TABLE categories (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  icon INTEGER,
  color INTEGER,
  type TEXT NOT NULL,
  is_system INTEGER DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
)
```

**Columns:**
- `id`: Unique identifier (TEXT) - Format: `cat_<name>`
- `name`: Category name (TEXT, NOT NULL)
- `icon`: Icon code point (INTEGER, nullable)
- `color`: Color value (INTEGER, nullable)
- `type`: Category type - "income" or "expense" (TEXT, NOT NULL)
- `is_system`: System category flag - 1 for system, 0 for user (INTEGER, default 0)
- `created_at`: Creation timestamp (INTEGER, NOT NULL)
- `updated_at`: Last update timestamp (INTEGER, NOT NULL)

**Default Categories:**

*Expense Categories:*
- Food & Dining (cat_food)
- Transportation (cat_transport)
- Shopping (cat_shopping)
- Entertainment (cat_entertainment)
- Bills & Utilities (cat_bills)
- Healthcare (cat_healthcare)
- Education (cat_education)
- Other (cat_other_expense)

*Income Categories:*
- Salary (cat_salary)
- Business (cat_business)
- Investment (cat_investment)
- Freelance (cat_freelance)
- Other (cat_other_income)

#### 3. Budgets Table

Stores budget information for categories.

```sql
CREATE TABLE budgets (
  id TEXT PRIMARY KEY,
  category_id TEXT,
  amount REAL NOT NULL,
  period TEXT NOT NULL,
  start_date INTEGER NOT NULL,
  end_date INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY (category_id) REFERENCES categories (id)
    ON DELETE CASCADE
)
```

**Columns:**
- `id`: Unique identifier (TEXT)
- `category_id`: Foreign key to categories (TEXT, nullable)
- `amount`: Budget amount (REAL, NOT NULL)
- `period`: Budget period - "daily", "weekly", "monthly", etc. (TEXT, NOT NULL)
- `start_date`: Budget start date in milliseconds (INTEGER, NOT NULL)
- `end_date`: Budget end date in milliseconds (INTEGER, NOT NULL)
- `created_at`: Creation timestamp (INTEGER, NOT NULL)
- `updated_at`: Last update timestamp (INTEGER, NOT NULL)

#### 4. Preferences Table

Stores application preferences and settings.

```sql
CREATE TABLE preferences (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at INTEGER NOT NULL
)
```

**Columns:**
- `key`: Preference key (TEXT, PRIMARY KEY)
- `value`: Preference value as JSON string (TEXT, NOT NULL)
- `updated_at`: Last update timestamp (INTEGER, NOT NULL)

## Core Components

### 1. DatabaseHelper (`lib/core/database/database_helper.dart`)

**Purpose:** Low-level SQLite database operations and schema management.

**Key Features:**
- Singleton pattern for single database instance
- Database initialization and creation
- Foreign key constraint enforcement
- Schema version management (current version: 1)
- Migration support via `_onUpgrade()`
- Default category insertion
- Database backup and restore
- Database deletion for testing/reset

**Important Methods:**
```dart
Future<Database> get database        // Get database instance
Future<void> close()                 // Close database connection
Future<void> deleteDatabase()        // Delete database file
Future<String> backupDatabase()      // Create backup
Future<void> restoreDatabase(String) // Restore from backup
```

**Database Location:**
- Database name: `mero_budget_tracker.db`
- Path: Platform-specific databases directory (via `getDatabasesPath()`)

### 2. DatabaseService (`lib/core/database/database_service.dart`)

**Purpose:** High-level database service providing business logic operations.

**Key Features:**
- Service initialization and health checks
- Data import/export as JSON
- Database statistics
- Database maintenance (VACUUM, ANALYZE)
- Integrity checking
- Sample data insertion for testing
- Transaction clearing

**Important Methods:**
```dart
Future<void> initialize()                      // Initialize service
Future<Map<String, dynamic>> exportData()      // Export all data as JSON
Future<void> importData(Map<String, dynamic>)  // Import data from JSON
Future<Map<String, dynamic>> getDatabaseStats() // Get database statistics
Future<void> performMaintenance()              // Run VACUUM and ANALYZE
Future<bool> checkIntegrity()                  // Check database integrity
Future<void> clearTransactions()               // Clear all transactions
```

### 3. Transaction Entity (`lib/features/transaction/domain/entities/transaction.dart`)

**Purpose:** Domain model representing a transaction.

**Properties:**
```dart
class Transaction extends Equatable {
  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final TransactionType type;  // enum: income, expense
  final String? category;
  final String? note;
}
```

**Enum:**
```dart
enum TransactionType {
  income,
  expense,
}
```

### 4. TransactionRepository Interface (`lib/features/transaction/domain/repositories/transaction_repository.dart`)

**Purpose:** Abstract repository interface defining transaction operations.

**Methods:**
```dart
Future<List<Transaction>> getTransactions({int? limit, int? offset})
Future<Transaction> addTransaction(Transaction transaction)
Future<void> deleteTransaction(String id)
Future<Transaction> updateTransaction(Transaction transaction)
Future<List<Transaction>> getTransactionsInRange({
  required DateTime startDate,
  required DateTime endDate,
})
```

### 5. SqliteTransactionRepository (`lib/features/transaction/data/repositories/sqlite_transaction_repository.dart`)

**Purpose:** SQLite implementation of the transaction repository.

**Key Features:**
- Full CRUD operations (Create, Read, Update, Delete)
- Pagination support
- Date range filtering
- Transaction type filtering
- Category filtering
- Search by description/note
- Transaction statistics calculation
- Automatic ID generation

**Important Methods:**
```dart
Future<List<Transaction>> getTransactions({int? offset, int? limit})
Future<Transaction> addTransaction(Transaction transaction)
Future<Transaction> updateTransaction(Transaction transaction)
Future<void> deleteTransaction(String id)
Future<List<Transaction>> getTransactionsByDateRange({
  required DateTime startDate,
  required DateTime endDate,
  TransactionType? type,
  String? categoryId,
})
Future<List<Transaction>> searchTransactions({
  required String query,
  int? limit,
})
Future<Map<String, dynamic>> getTransactionStats({
  DateTime? startDate,
  DateTime? endDate,
})
```

**Data Mapping:**
- Converts database maps to `Transaction` entities
- Handles type conversion (milliseconds ↔ DateTime)
- Manages enum serialization (TransactionType ↔ String)

### 6. TransactionBloc (`lib/features/transaction/presentation/bloc/transaction_bloc.dart`)

**Purpose:** BLoC for managing transaction state and business logic.

**Events:**
```dart
LoadTransactions()              // Load initial transactions
LoadMoreTransactions(pageSize)  // Load more for pagination
RefreshTransactions()           // Refresh transaction list
AddTransaction(transaction)     // Add new transaction
EditTransaction(transaction)    // Update existing transaction
DeleteTransaction(id)           // Delete transaction
```

**States:**
```dart
TransactionInitial()                        // Initial state
TransactionLoading()                        // Loading state
TransactionLoadingMore(currentTransactions) // Loading more for pagination
TransactionLoaded(transactions)             // Successfully loaded
TransactionUpdating(transaction)            // Updating transaction
TransactionError(message)                   // Error state
```

## Application Initialization

### Main Entry Point (`lib/main.dart`)

The application initializes the database before running:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database
  final databaseService = DatabaseService();
  await databaseService.initialize();
  
  runApp(const MyApp());
}
```

### Dependency Injection

The app uses `MultiBlocProvider` to provide BLoCs throughout the widget tree:

```dart
MultiBlocProvider(
  providers: [
    BlocProvider(
      create: (context) => TransactionBloc(
        repository: SqliteTransactionRepository(),
      )..add(const LoadTransactions()),
    ),
    // ... other BLoCs
  ],
  child: MaterialApp(...)
)
```

## How Transactions Are Added

### Flow for Adding a New Transaction

1. **User Input:** User fills out transaction form in the UI
2. **Event Dispatch:** UI dispatches `AddTransaction` event to `TransactionBloc`
3. **BLoC Processing:** `TransactionBloc` receives event and calls repository
4. **Repository Operation:** `SqliteTransactionRepository.addTransaction()`:
   - Generates unique ID: `txn_<timestamp>_<random>`
   - Creates transaction with ID
   - Converts `Transaction` entity to database map
   - Inserts into `transactions` table via `DatabaseHelper`
   - Returns transaction with generated ID
5. **State Update:** BLoC reloads all transactions and emits `TransactionLoaded` state
6. **UI Update:** UI rebuilds with updated transaction list

### Code Flow

```dart
// 1. User submits form
context.read<TransactionBloc>().add(AddTransaction(transaction));

// 2. BLoC handles event
Future<void> _onAddTransaction(AddTransaction event, Emitter emit) async {
  await repository.addTransaction(event.transaction);
  final transactions = await repository.getTransactions();
  emit(TransactionLoaded(transactions));
}

// 3. Repository inserts into database
Future<Transaction> addTransaction(Transaction transaction) async {
  final db = await _databaseHelper.database;
  final id = 'txn_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(6)}';
  final transactionWithId = transaction.copyWith(id: id);
  
  await db.insert(
    DatabaseHelper.tableTransactions,
    {
      DatabaseHelper.columnId: transactionWithId.id,
      DatabaseHelper.columnDescription: transactionWithId.description,
      DatabaseHelper.columnAmount: transactionWithId.amount,
      DatabaseHelper.columnDate: transactionWithId.date.millisecondsSinceEpoch,
      DatabaseHelper.columnType: transactionWithId.type.toString().split('.').last,
      DatabaseHelper.columnCategoryId: transactionWithId.category,
      DatabaseHelper.columnNote: transactionWithId.note,
      DatabaseHelper.columnCreatedAt: now,
      DatabaseHelper.columnUpdatedAt: now,
    },
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
  
  return transactionWithId;
}
```

## Database Operations

### Create (Insert)

```dart
// Add transaction
final transaction = Transaction(
  id: '', // Will be auto-generated
  description: 'Grocery Shopping',
  amount: 85.50,
  date: DateTime.now(),
  type: TransactionType.expense,
  category: 'cat_food',
  note: 'Weekly groceries',
);

await repository.addTransaction(transaction);
```

### Read (Query)

```dart
// Get all transactions
final transactions = await repository.getTransactions();

// Get with pagination
final transactions = await repository.getTransactions(limit: 20, offset: 0);

// Get by date range
final transactions = await repository.getTransactionsInRange(
  startDate: DateTime(2024, 1, 1),
  endDate: DateTime(2024, 12, 31),
);

// Search transactions
final transactions = await repository.searchTransactions(query: 'grocery');

// Get statistics
final stats = await repository.getTransactionStats(
  startDate: DateTime(2024, 1, 1),
  endDate: DateTime(2024, 12, 31),
);
```

### Update

```dart
// Update transaction
final updatedTransaction = transaction.copyWith(
  amount: 100.00,
  description: 'Updated description',
);

await repository.updateTransaction(updatedTransaction);
```

### Delete

```dart
// Delete transaction by ID
await repository.deleteTransaction('txn_123456789_abc123');

// Delete all transactions
await repository.deleteAllTransactions();
```

## Data Persistence

### Storage Location

- **Android:** `/data/data/<package_name>/databases/mero_budget_tracker.db`
- **iOS:** `<Application Documents Directory>/databases/mero_budget_tracker.db`
- **macOS:** `<Application Support Directory>/databases/mero_budget_tracker.db`
- **Linux:** `<Home Directory>/.local/share/<app_name>/databases/mero_budget_tracker.db`
- **Windows:** `<AppData>/databases/mero_budget_tracker.db`

### Backup and Restore

```dart
// Create backup
final backupPath = await databaseService.backupDatabase();
// Returns: '<databases_path>/backup_<timestamp>.db'

// Restore from backup
await databaseService.restoreDatabase(backupPath);
```

### Data Export/Import

```dart
// Export all data as JSON
final jsonData = await databaseService.exportData();
// Returns: { version: 1, exportDate: '...', data: { transactions: [...], categories: [...], ... } }

// Import data from JSON
await databaseService.importData(jsonData);
```

## Migration Strategy

### Current Version: 1

The database is currently at version 1. Future migrations will be handled in the `_onUpgrade()` method:

```dart
Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    // Example: Add new column
    // await db.execute('ALTER TABLE transactions ADD COLUMN tags TEXT');
  }
  if (oldVersion < 3) {
    // Future migrations
  }
}
```

### Migration Best Practices

1. **Incremental Updates:** Handle each version increment separately
2. **Backward Compatibility:** Ensure old data remains valid
3. **Data Preservation:** Never delete user data during migration
4. **Testing:** Test migrations with real data before deployment
5. **Backup:** Always backup before migration

## Error Handling

### Database Initialization Errors

```dart
try {
  await databaseService.initialize();
} catch (e) {
  // Handle initialization error
  // Log error, show user message, etc.
}
```

### Transaction Operation Errors

The BLoC handles errors and emits `TransactionError` state:

```dart
try {
  await repository.addTransaction(transaction);
} catch (e) {
  emit(TransactionError(e.toString()));
}
```

## Performance Considerations

### Indexes

The database uses indexes for optimal query performance:
- `idx_transactions_date`: Speeds up date-based queries and sorting
- `idx_transactions_type`: Speeds up filtering by transaction type
- `idx_transactions_category`: Speeds up category-based queries

### Pagination

The repository supports pagination to avoid loading all transactions at once:

```dart
// Load first 20 transactions
final transactions = await repository.getTransactions(limit: 20, offset: 0);

// Load next 20 transactions
final moreTransactions = await repository.getTransactions(limit: 20, offset: 20);
```

### Database Maintenance

Regular maintenance improves performance:

```dart
// Reclaim unused space and optimize queries
await databaseService.performMaintenance();
```

## Testing

### Sample Data

The `DatabaseService` provides sample transactions for testing:

```dart
// Insert sample data
await databaseService.insertSampleData();

// Get sample transactions
final samples = DatabaseService.getSampleTransactions();
```

### Database Reset

For testing purposes, the database can be reset:

```dart
// Delete all data and reinitialize
await databaseService.resetDatabase();

// Delete database file
await databaseHelper.deleteDatabase();
```

## Summary

The Mero Budget Tracker application has a **complete and functional SQLite database implementation** with:

✅ **Well-defined schema** with 4 tables (transactions, categories, budgets, preferences)  
✅ **Clean architecture** separating domain, data, and presentation layers  
✅ **Repository pattern** with abstract interface and SQLite implementation  
✅ **BLoC state management** for reactive UI updates  
✅ **Full CRUD operations** for transactions  
✅ **Advanced features** like pagination, search, filtering, and statistics  
✅ **Data persistence** with backup/restore and import/export  
✅ **Migration support** for future schema changes  
✅ **Performance optimizations** with indexes and maintenance utilities  
✅ **Error handling** throughout the stack  

The database is initialized in `main.dart` before the app runs, and all transaction operations flow through the BLoC → Repository → DatabaseHelper architecture, ensuring a clean separation of concerns and maintainable codebase.
