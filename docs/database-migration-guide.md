# Database Migration Guide

## Overview

This guide explains how to create and manage database migrations in the Mero Budget Tracker application. The migration system allows for safe schema updates while preserving user data.

## Migration System Architecture

The migration system consists of three main components:

1. **DatabaseHelper** - Manages database creation and version control
2. **MigrationManager** - Handles migration execution and rollback
3. **Migration Classes** - Individual migration definitions

## Creating a New Migration

### Step 1: Define the Migration

Create a new migration in the `MigrationManager` class:

```dart
static final Migration addTagsToTransactions = Migration(
  version: 2,
  description: 'Add tags support to transactions',
  up: (Database db) async {
    // Add the new column
    await MigrationManager.addColumnIfNotExists(
      db,
      'transactions',
      'tags',
      'TEXT',
    );
    
    // Create an index for better performance
    await MigrationManager.createIndexIfNotExists(
      db,
      'idx_transactions_tags',
      'transactions',
      'tags',
    );
  },
  down: (Database db) async {
    // SQLite doesn't support dropping columns directly
    // You would need to recreate the table without the column
    await MigrationManager.dropIndexIfExists(db, 'idx_transactions_tags');
  },
);
```

### Step 2: Register the Migration

Add your migration to the migrations list in `MigrationManager`:

```dart
static final List<Migration> migrations = [
  // Version 1 is handled in DatabaseHelper._onCreate
  addTagsToTransactions, // Version 2
  addRecurringTransactions, // Version 3
  // Add new migrations here
];
```

### Step 3: Update Database Version

In `DatabaseHelper`, update the database version:

```dart
static const int _databaseVersion = 2; // Increment this
```

## Migration Examples

### Example 1: Adding a New Column

```dart
static final Migration addCurrencySupport = Migration(
  version: 2,
  description: 'Add multi-currency support',
  up: (Database db) async {
    // Add currency column with default value
    await db.execute('''
      ALTER TABLE transactions 
      ADD COLUMN currency TEXT DEFAULT 'USD'
    ''');
    
    // Add exchange rate column
    await db.execute('''
      ALTER TABLE transactions 
      ADD COLUMN exchange_rate REAL DEFAULT 1.0
    ''');
  },
);
```

### Example 2: Creating a New Table

```dart
static final Migration addBudgetAlerts = Migration(
  version: 3,
  description: 'Add budget alerts table',
  up: (Database db) async {
    await db.execute('''
      CREATE TABLE budget_alerts (
        id TEXT PRIMARY KEY,
        budget_id TEXT NOT NULL,
        alert_type TEXT NOT NULL,
        threshold REAL NOT NULL,
        is_active INTEGER DEFAULT 1,
        last_triggered INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (budget_id) REFERENCES budgets (id) ON DELETE CASCADE
      )
    ''');
    
    // Add index
    await db.execute('''
      CREATE INDEX idx_budget_alerts_active 
      ON budget_alerts (is_active, budget_id)
    ''');
  },
  down: (Database db) async {
    await db.execute('DROP TABLE IF EXISTS budget_alerts');
  },
);
```

### Example 3: Data Migration

```dart
static final Migration normalizeCategories = Migration(
  version: 4,
  description: 'Normalize category names',
  up: (Database db) async {
    // First, backup the data
    await MigrationManager.backupTable(db, 'categories');
    
    // Update category names
    await db.execute('''
      UPDATE categories 
      SET name = LOWER(REPLACE(name, ' ', '_'))
      WHERE is_system = 0
    ''');
    
    // Update references in transactions
    await db.execute('''
      UPDATE transactions 
      SET category_id = (
        SELECT id FROM categories 
        WHERE LOWER(REPLACE(name, ' ', '_')) = transactions.category_id
      )
      WHERE category_id IS NOT NULL
    ''');
  },
);
```

### Example 4: Complex Migration with Data Transformation

```dart
static final Migration splitAmountFields = Migration(
  version: 5,
  description: 'Split amount into base_amount and converted_amount',
  up: (Database db) async {
    // Create temporary table with new schema
    await db.execute('''
      CREATE TABLE transactions_new (
        id TEXT PRIMARY KEY,
        description TEXT NOT NULL,
        base_amount REAL NOT NULL,
        converted_amount REAL NOT NULL,
        currency TEXT DEFAULT 'USD',
        exchange_rate REAL DEFAULT 1.0,
        date INTEGER NOT NULL,
        type TEXT NOT NULL,
        category_id TEXT,
        note TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    
    // Copy and transform data
    await db.execute('''
      INSERT INTO transactions_new (
        id, description, base_amount, converted_amount,
        currency, exchange_rate, date, type, category_id,
        note, created_at, updated_at
      )
      SELECT 
        id, description, amount, amount,
        'USD', 1.0, date, type, category_id,
        note, created_at, updated_at
      FROM transactions
    ''');
    
    // Drop old table
    await db.execute('DROP TABLE transactions');
    
    // Rename new table
    await db.execute('ALTER TABLE transactions_new RENAME TO transactions');
    
    // Recreate indexes
    await db.execute('''
      CREATE INDEX idx_transactions_date ON transactions (date DESC)
    ''');
  },
);
```

## Testing Migrations

### Unit Testing

```dart
test('Migration adds tags column successfully', () async {
  final db = await openDatabase(':memory:');
  
  // Create initial schema
  await db.execute(createTransactionsTableSQL);
  
  // Run migration
  await addTagsToTransactions.up(db);
  
  // Verify column exists
  final hasColumn = await MigrationManager.columnExists(
    db, 'transactions', 'tags'
  );
  
  expect(hasColumn, isTrue);
  
  await db.close();
});
```

### Integration Testing

```dart
test('Database upgrades from v1 to v2 successfully', () async {
  // Create v1 database
  final db = await openDatabase(
    'test.db',
    version: 1,
    onCreate: (db, version) async {
      // Create v1 schema
    },
  );
  
  await db.close();
  
  // Reopen with v2
  final upgradedDb = await openDatabase(
    'test.db',
    version: 2,
    onUpgrade: (db, oldVersion, newVersion) async {
      await MigrationManager.migrate(db, oldVersion, newVersion);
    },
  );
  
  // Verify migration was applied
  final version = await upgradedDb.getVersion();
  expect(version, equals(2));
  
  await upgradedDb.close();
});
```

## Best Practices

### 1. Always Test Migrations

- Test on a copy of production data
- Verify data integrity after migration
- Test both upgrade and downgrade paths

### 2. Make Migrations Idempotent

Migrations should be safe to run multiple times:

```dart
// Good - checks if column exists first
await MigrationManager.addColumnIfNotExists(
  db, 'transactions', 'tags', 'TEXT'
);

// Bad - will fail if column already exists
await db.execute('ALTER TABLE transactions ADD COLUMN tags TEXT');
```

### 3. Handle Large Data Sets

For migrations affecting large amounts of data:

```dart
up: (Database db) async {
  // Process in batches
  const batchSize = 1000;
  int offset = 0;
  
  while (true) {
    final batch = await db.query(
      'transactions',
      limit: batchSize,
      offset: offset,
    );
    
    if (batch.isEmpty) break;
    
    // Process batch
    for (final row in batch) {
      // Transform data
    }
    
    offset += batchSize;
  }
},
```

### 4. Provide Rollback Capability

Always implement the `down` method when possible:

```dart
down: (Database db) async {
  // For new tables
  await db.execute('DROP TABLE IF EXISTS new_table');
  
  // For indexes
  await MigrationManager.dropIndexIfExists(db, 'index_name');
  
  // For complex changes, restore from backup
  await MigrationManager.restoreTable(
    db, 'table_name', 'table_name_backup'
  );
},
```

### 5. Document Breaking Changes

If a migration contains breaking changes:

```dart
static final Migration breakingChange = Migration(
  version: 10,
  description: '''
    BREAKING CHANGE: Restructures transaction storage.
    - Backup your data before upgrading
    - Export/Import may be required for some users
    - Old app versions will not be compatible
  ''',
  up: (Database db) async {
    // Migration logic
  },
);
```

## Troubleshooting

### Migration Failed

1. Check the error logs
2. Verify database integrity: `PRAGMA integrity_check`
3. Restore from backup if necessary
4. Fix the migration and retry

### Database Locked

```dart
// Wait for operations to complete
await db.close();
await Future.delayed(Duration(milliseconds: 100));
// Retry migration
```

### Out of Memory

For large migrations, use transactions:

```dart
await db.transaction((txn) async {
  // Migration steps
  await txn.execute('...');
});
```

## Migration Checklist

Before deploying a migration:

- [ ] Migration is idempotent
- [ ] Down/rollback method implemented
- [ ] Tested with sample data
- [ ] Tested with large data sets
- [ ] Performance impact assessed
- [ ] Backup strategy in place
- [ ] Documentation updated
- [ ] Version number incremented
- [ ] Migration registered in list

## Conclusion

The migration system provides a robust way to evolve the database schema while preserving user data. Always test migrations thoroughly and provide rollback capabilities when possible.