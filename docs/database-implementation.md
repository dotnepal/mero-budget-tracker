# Database Implementation Documentation

## Overview

This document describes the SQLite database implementation for the Mero Budget Tracker application, which provides persistent local storage for all financial data.

## Architecture

### Core Components

1. **DatabaseHelper** (`lib/core/database/database_helper.dart`)
   - Singleton pattern for database instance management
   - Schema creation and migration handling
   - Low-level database operations

2. **DatabaseService** (`lib/core/database/database_service.dart`)
   - High-level database operations
   - Backup/restore functionality
   - Data export/import capabilities
   - Database maintenance utilities

3. **SqliteTransactionRepository** (`lib/features/transaction/data/repositories/sqlite_transaction_repository.dart`)
   - Implementation of TransactionRepository interface
   - CRUD operations for transactions
   - Advanced querying capabilities

4. **MigrationManager** (`lib/core/database/migration_manager.dart`)
   - Database schema versioning
   - Migration execution and rollback
   - Schema update utilities

## Database Schema

### Tables

#### 1. transactions
Stores all financial transactions.

| Column | Type | Description |
|--------|------|-------------|
| id | TEXT (PK) | Unique transaction identifier |
| description | TEXT | Transaction description |
| amount | REAL | Transaction amount |
| date | INTEGER | Unix timestamp of transaction date |
| type | TEXT | 'income' or 'expense' |
| category_id | TEXT (FK) | Reference to categories table |
| note | TEXT | Optional notes |
| created_at | INTEGER | Creation timestamp |
| updated_at | INTEGER | Last update timestamp |

**Indexes:**
- `idx_transactions_date` - For date-based queries
- `idx_transactions_type` - For filtering by type
- `idx_transactions_category` - For category filtering

#### 2. categories
Stores transaction categories.

| Column | Type | Description |
|--------|------|-------------|
| id | TEXT (PK) | Unique category identifier |
| name | TEXT | Category name |
| icon | INTEGER | Icon code point |
| color | INTEGER | Color value |
| type | TEXT | 'income' or 'expense' |
| is_system | INTEGER | 1 for default categories, 0 for user-created |
| created_at | INTEGER | Creation timestamp |
| updated_at | INTEGER | Last update timestamp |

#### 3. budgets
Stores budget rules for categories.

| Column | Type | Description |
|--------|------|-------------|
| id | TEXT (PK) | Unique budget identifier |
| category_id | TEXT (FK) | Reference to categories table |
| amount | REAL | Budget limit amount |
| period | TEXT | Budget period (monthly, weekly, etc.) |
| start_date | INTEGER | Budget start date |
| end_date | INTEGER | Budget end date |
| created_at | INTEGER | Creation timestamp |
| updated_at | INTEGER | Last update timestamp |

#### 4. preferences
Stores user preferences and settings.

| Column | Type | Description |
|--------|------|-------------|
| key | TEXT (PK) | Preference key |
| value | TEXT | Preference value (JSON encoded) |
| updated_at | INTEGER | Last update timestamp |

## Features

### 1. Data Persistence
- Automatic database initialization on app startup
- Transaction data persists between app sessions
- Support for large datasets with pagination

### 2. Default Categories
The system automatically creates default categories on first launch:

**Expense Categories:**
- Food & Dining
- Transportation
- Shopping
- Entertainment
- Bills & Utilities
- Healthcare
- Education
- Other

**Income Categories:**
- Salary
- Business
- Investment
- Freelance
- Other

### 3. Backup & Restore

#### Database Backup
```dart
// Create a backup
final backupPath = await DatabaseService().backupDatabase();
```

#### Data Export (JSON)
```dart
// Export all data as JSON
final jsonData = await DatabaseService().exportData();
```

#### Data Import
```dart
// Import data from JSON
await DatabaseService().importData(jsonData);
```

### 4. Database Maintenance

#### Integrity Check
```dart
// Check database integrity
final isHealthy = await DatabaseService().checkIntegrity();
```

#### Optimization
```dart
// Perform database optimization
await DatabaseService().performMaintenance();
```

### 5. Query Capabilities

#### Date Range Queries
```dart
final transactions = await repository.getTransactionsByDateRange(
  startDate: DateTime(2024, 1, 1),
  endDate: DateTime(2024, 12, 31),
  type: TransactionType.expense,
  categoryId: 'cat_food',
);
```

#### Search Functionality
```dart
final results = await repository.searchTransactions(
  query: 'coffee',
  limit: 20,
);
```

#### Statistics
```dart
final stats = await repository.getTransactionStats(
  startDate: DateTime(2024, 1, 1),
  endDate: DateTime(2024, 12, 31),
);
// Returns: totalIncome, totalExpenses, balance, transaction counts
```

## Migration System

### Creating Migrations

Migrations are defined in the `MigrationManager` class:

```dart
static final Migration addNewFeature = Migration(
  version: 2,
  description: 'Add new feature support',
  up: (Database db) async {
    // Apply migration
    await db.execute('ALTER TABLE ...');
  },
  down: (Database db) async {
    // Rollback migration (if possible)
  },
);
```

### Migration Execution

Migrations are automatically executed when the database version is upgraded:

1. Database version is incremented in `DatabaseHelper._databaseVersion`
2. On app launch, if current version < new version, migrations run
3. Each migration between old and new version is executed in sequence

## Security Considerations

### Data Protection
- All data is stored locally on device
- Database file is protected by OS-level security
- No network transmission of financial data

### Input Validation
- SQL injection prevention through parameterized queries
- Data type validation before database operations
- Foreign key constraints ensure data integrity

## Performance Optimizations

### Indexing Strategy
- Indexes on frequently queried columns (date, type, category)
- Composite indexes for complex queries
- Regular index optimization through ANALYZE

### Query Optimization
- Pagination support for large datasets
- Efficient batch operations
- Query result caching where appropriate

### Database Maintenance
- Automatic VACUUM on database optimization
- ANALYZE for query planner statistics
- Periodic integrity checks

## Usage Examples

### Initialize Database
```dart
// In main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final databaseService = DatabaseService();
  await databaseService.initialize();
  
  runApp(const MyApp());
}
```

### Repository Usage
```dart
// Use SQLite repository instead of in-memory
final transactionRepository = SqliteTransactionRepository();

// Add transaction
final transaction = Transaction(
  id: 'txn_123',
  description: 'Coffee',
  amount: 5.50,
  date: DateTime.now(),
  type: TransactionType.expense,
  category: 'cat_food',
);
await repository.addTransaction(transaction);

// Get all transactions
final transactions = await repository.getTransactions();

// Search transactions
final results = await repository.searchTransactions(query: 'coffee');
```

### Database Settings UI
Access database settings through the app menu:
1. Tap menu (⋮) in the app bar
2. Select "Database Settings"
3. Available options:
   - Backup database
   - Export data as JSON
   - Optimize database
   - Insert sample data (for testing)
   - Clear all transactions
   - Reset database

## Troubleshooting

### Common Issues

#### Database Locked Error
**Solution:** Ensure all database operations are properly awaited and connections are closed.

#### Migration Failed
**Solution:** 
1. Check error logs for specific failure
2. Restore from backup if available
3. Reset database as last resort

#### Data Not Persisting
**Solution:**
1. Verify database initialization in main.dart
2. Check that SqliteTransactionRepository is being used
3. Ensure transactions are being awaited

### Debug Commands

```dart
// Get database statistics
final stats = await DatabaseService().getDatabaseStats();
print('Total transactions: ${stats['transactionCount']}');

// Check database health
final isHealthy = await DatabaseService().checkIntegrity();
print('Database healthy: $isHealthy');

// View database path
final db = await DatabaseHelper.instance.database;
print('Database location: ${db.path}');
```

## Future Enhancements

### Planned Features
1. **Cloud Sync** - Optional backup to cloud storage
2. **Data Encryption** - Encrypt sensitive financial data
3. **Advanced Analytics** - More complex statistical queries
4. **Multi-user Support** - Multiple profiles in single app
5. **Recurring Transactions** - Automatic transaction creation

### Performance Improvements
1. Implement query result caching
2. Add background data processing
3. Optimize large dataset handling
4. Implement data compression

## Conclusion

The SQLite database implementation provides a robust, performant, and reliable data persistence layer for the Mero Budget Tracker application. With features like automatic backups, data export/import, and comprehensive maintenance tools, users can trust their financial data is secure and accessible.