import 'package:sqflite/sqflite.dart';

/// Manages database migrations and schema updates
class MigrationManager {
  /// List of all migrations
  static final List<Migration> migrations = [
    // Version 1 is handled in DatabaseHelper._onCreate
    // Add future migrations here
    // Migration(
    //   version: 2,
    //   up: (Database db) async {
    //     await db.execute('ALTER TABLE transactions ADD COLUMN tags TEXT');
    //   },
    //   down: (Database db) async {
    //     // Downgrade logic if needed
    //   },
    // ),
  ];

  /// Apply migrations from current version to target version
  static Future<void> migrate(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    for (final migration in migrations) {
      if (migration.version > oldVersion && migration.version <= newVersion) {
        // Applying migration to version ${migration.version}
        await migration.up(db);
      }
    }
  }

  /// Rollback migrations from current version to target version
  static Future<void> rollback(
    Database db,
    int currentVersion,
    int targetVersion,
  ) async {
    final reversedMigrations = migrations.reversed.toList();
    for (final migration in reversedMigrations) {
      if (migration.version <= currentVersion && migration.version > targetVersion) {
        if (migration.down != null) {
          // Rolling back migration from version ${migration.version}
          await migration.down!(db);
        }
      }
    }
  }

  /// Check if a table exists in the database
  static Future<bool> tableExists(Database db, String tableName) async {
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [tableName],
    );
    return result.isNotEmpty;
  }

  /// Check if a column exists in a table
  static Future<bool> columnExists(
    Database db,
    String tableName,
    String columnName,
  ) async {
    final result = await db.rawQuery('PRAGMA table_info($tableName)');
    for (final row in result) {
      if (row['name'] == columnName) {
        return true;
      }
    }
    return false;
  }

  /// Add a column to a table if it doesn't exist
  static Future<void> addColumnIfNotExists(
    Database db,
    String tableName,
    String columnName,
    String columnDefinition,
  ) async {
    final exists = await columnExists(db, tableName, columnName);
    if (!exists) {
      await db.execute(
        'ALTER TABLE $tableName ADD COLUMN $columnName $columnDefinition',
      );
    }
  }

  /// Create an index if it doesn't exist
  static Future<void> createIndexIfNotExists(
    Database db,
    String indexName,
    String tableName,
    String columns,
  ) async {
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='index' AND name=?",
      [indexName],
    );

    if (result.isEmpty) {
      await db.execute(
        'CREATE INDEX $indexName ON $tableName ($columns)',
      );
    }
  }

  /// Drop an index if it exists
  static Future<void> dropIndexIfExists(
    Database db,
    String indexName,
  ) async {
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='index' AND name=?",
      [indexName],
    );

    if (result.isNotEmpty) {
      await db.execute('DROP INDEX $indexName');
    }
  }

  /// Backup a table before migration
  static Future<void> backupTable(
    Database db,
    String tableName,
  ) async {
    final backupTableName = '${tableName}_backup_${DateTime.now().millisecondsSinceEpoch}';

    // Create backup table with same structure
    await db.execute(
      'CREATE TABLE $backupTableName AS SELECT * FROM $tableName',
    );

    // Backed up table $tableName to $backupTableName
  }

  /// Restore a table from backup
  static Future<void> restoreTable(
    Database db,
    String tableName,
    String backupTableName,
  ) async {
    // Drop current table
    await db.execute('DROP TABLE IF EXISTS $tableName');

    // Rename backup table to original name
    await db.execute('ALTER TABLE $backupTableName RENAME TO $tableName');

    // Restored table $tableName from $backupTableName
  }

  /// Get current database version
  static Future<int> getDatabaseVersion(Database db) async {
    return await db.getVersion();
  }

  /// Set database version
  static Future<void> setDatabaseVersion(Database db, int version) async {
    await db.setVersion(version);
  }
}

/// Represents a single database migration
class Migration {
  final int version;
  final Future<void> Function(Database db) up;
  final Future<void> Function(Database db)? down;
  final String? description;

  Migration({
    required this.version,
    required this.up,
    this.down,
    this.description,
  });
}

/// Example migrations for reference
class ExampleMigrations {
  static final addTagsColumn = Migration(
    version: 2,
    description: 'Add tags column to transactions table',
    up: (Database db) async {
      await MigrationManager.addColumnIfNotExists(
        db,
        'transactions',
        'tags',
        'TEXT',
      );
    },
    down: (Database db) async {
      // SQLite doesn't support dropping columns directly
      // Would need to recreate the table without the column
    },
  );

  static final addRecurringTransactions = Migration(
    version: 3,
    description: 'Add recurring transactions table',
    up: (Database db) async {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS recurring_transactions (
          id TEXT PRIMARY KEY,
          description TEXT NOT NULL,
          amount REAL NOT NULL,
          type TEXT NOT NULL,
          category_id TEXT,
          frequency TEXT NOT NULL,
          start_date INTEGER NOT NULL,
          end_date INTEGER,
          last_executed INTEGER,
          is_active INTEGER DEFAULT 1,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');

      await MigrationManager.createIndexIfNotExists(
        db,
        'idx_recurring_active',
        'recurring_transactions',
        'is_active, start_date',
      );
    },
    down: (Database db) async {
      await db.execute('DROP TABLE IF EXISTS recurring_transactions');
    },
  );

  static final addAttachments = Migration(
    version: 4,
    description: 'Add attachments support for transactions',
    up: (Database db) async {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS attachments (
          id TEXT PRIMARY KEY,
          transaction_id TEXT NOT NULL,
          file_path TEXT NOT NULL,
          file_name TEXT NOT NULL,
          file_size INTEGER,
          mime_type TEXT,
          created_at INTEGER NOT NULL,
          FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE CASCADE
        )
      ''');

      await MigrationManager.createIndexIfNotExists(
        db,
        'idx_attachments_transaction',
        'attachments',
        'transaction_id',
      );
    },
    down: (Database db) async {
      await db.execute('DROP TABLE IF EXISTS attachments');
    },
  );
}
