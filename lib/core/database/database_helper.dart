import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Database helper class that manages SQLite database operations
class DatabaseHelper {
  static const String _databaseName = 'mero_budget_tracker.db';
  static const int _databaseVersion = 2;

  // Table names
  static const String tableTransactions = 'transactions';
  static const String tableCategories = 'categories';
  static const String tableBudgets = 'budgets';
  static const String tableBudgetPlans = 'budget_plans';
  static const String tablePreferences = 'preferences';

  // Transaction table columns
  static const String columnId = 'id';
  static const String columnDescription = 'description';
  static const String columnAmount = 'amount';
  static const String columnDate = 'date';
  static const String columnType = 'type';
  static const String columnCategoryId = 'category_id';
  static const String columnNote = 'note';
  static const String columnCreatedAt = 'created_at';
  static const String columnUpdatedAt = 'updated_at';

  // Category table columns
  static const String columnCategoryName = 'name';
  static const String columnCategoryIcon = 'icon';
  static const String columnCategoryColor = 'color';
  static const String columnCategoryType = 'type';
  static const String columnCategoryIsSystem = 'is_system';
  static const String columnBudgetBucket = 'budget_bucket';

  // Budget table columns (legacy)
  static const String columnBudgetCategoryId = 'category_id';
  static const String columnBudgetAmount = 'amount';
  static const String columnBudgetPeriod = 'period';
  static const String columnBudgetStartDate = 'start_date';
  static const String columnBudgetEndDate = 'end_date';

  // Budget plans table columns
  static const String columnBudgetPlanName = 'name';
  static const String columnPeriodMonth = 'period_month';
  static const String columnPeriodYear = 'period_year';
  static const String columnTotalIncome = 'total_income';
  static const String columnRuleType = 'rule_type';
  static const String columnNeedsPct = 'needs_pct';
  static const String columnWantsPct = 'wants_pct';
  static const String columnSavingsPct = 'savings_pct';
  static const String columnHlcTimestamp = 'hlc_timestamp';
  static const String columnIsDeleted = 'is_deleted';
  static const String columnSyncStatus = 'sync_status';

  // Singleton pattern
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  /// Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    final String path = join(await getDatabasesPath(), _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  /// Configure database
  Future<void> _onConfigure(Database db) async {
    // Enable foreign keys
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    // Create categories table
    batch.execute('''
      CREATE TABLE $tableCategories (
        $columnId TEXT PRIMARY KEY,
        $columnCategoryName TEXT NOT NULL,
        $columnCategoryIcon INTEGER,
        $columnCategoryColor INTEGER,
        $columnCategoryType TEXT NOT NULL,
        $columnCategoryIsSystem INTEGER DEFAULT 0,
        $columnBudgetBucket TEXT,
        $columnCreatedAt INTEGER NOT NULL,
        $columnUpdatedAt INTEGER NOT NULL
      )
    ''');

    // Create transactions table
    batch.execute('''
      CREATE TABLE $tableTransactions (
        $columnId TEXT PRIMARY KEY,
        $columnDescription TEXT NOT NULL,
        $columnAmount REAL NOT NULL,
        $columnDate INTEGER NOT NULL,
        $columnType TEXT NOT NULL,
        $columnCategoryId TEXT,
        $columnNote TEXT,
        $columnCreatedAt INTEGER NOT NULL,
        $columnUpdatedAt INTEGER NOT NULL,
        FOREIGN KEY ($columnCategoryId) REFERENCES $tableCategories ($columnId)
          ON DELETE SET NULL
      )
    ''');

    // Create budgets table (legacy, kept for compatibility)
    batch.execute('''
      CREATE TABLE $tableBudgets (
        $columnId TEXT PRIMARY KEY,
        $columnBudgetCategoryId TEXT,
        $columnBudgetAmount REAL NOT NULL,
        $columnBudgetPeriod TEXT NOT NULL,
        $columnBudgetStartDate INTEGER NOT NULL,
        $columnBudgetEndDate INTEGER NOT NULL,
        $columnCreatedAt INTEGER NOT NULL,
        $columnUpdatedAt INTEGER NOT NULL,
        FOREIGN KEY ($columnBudgetCategoryId) REFERENCES $tableCategories ($columnId)
          ON DELETE CASCADE
      )
    ''');

    // Create budget_plans table
    batch.execute('''
      CREATE TABLE $tableBudgetPlans (
        $columnId TEXT PRIMARY KEY,
        $columnBudgetPlanName TEXT NOT NULL,
        $columnPeriodMonth INTEGER NOT NULL,
        $columnPeriodYear INTEGER NOT NULL,
        $columnTotalIncome INTEGER NOT NULL,
        $columnRuleType TEXT NOT NULL DEFAULT '50-30-20',
        $columnNeedsPct INTEGER NOT NULL DEFAULT 50,
        $columnWantsPct INTEGER NOT NULL DEFAULT 30,
        $columnSavingsPct INTEGER NOT NULL DEFAULT 20,
        $columnCreatedAt INTEGER NOT NULL,
        $columnUpdatedAt INTEGER NOT NULL,
        $columnHlcTimestamp TEXT NOT NULL DEFAULT '',
        $columnIsDeleted INTEGER NOT NULL DEFAULT 0,
        $columnSyncStatus INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Create preferences table
    batch.execute('''
      CREATE TABLE $tablePreferences (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        $columnUpdatedAt INTEGER NOT NULL
      )
    ''');

    // Create indexes for better performance
    batch.execute('''
      CREATE INDEX idx_transactions_date ON $tableTransactions ($columnDate DESC)
    ''');

    batch.execute('''
      CREATE INDEX idx_transactions_type ON $tableTransactions ($columnType)
    ''');

    batch.execute('''
      CREATE INDEX idx_transactions_category ON $tableTransactions ($columnCategoryId)
    ''');

    await batch.commit();

    // Insert default categories
    await _insertDefaultCategories(db);
    // Insert seed budget data for March 2026
    await _insertBudgetSeedData(db);
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _migrateToV2(db);
    }
  }

  /// Migrate from version 1 to 2
  Future<void> _migrateToV2(Database db) async {
    // Add budget_bucket column to categories
    await db.execute(
      'ALTER TABLE $tableCategories ADD COLUMN $columnBudgetBucket TEXT',
    );

    // Create budget_plans table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableBudgetPlans (
        $columnId TEXT PRIMARY KEY,
        $columnBudgetPlanName TEXT NOT NULL,
        $columnPeriodMonth INTEGER NOT NULL,
        $columnPeriodYear INTEGER NOT NULL,
        $columnTotalIncome INTEGER NOT NULL,
        $columnRuleType TEXT NOT NULL DEFAULT '50-30-20',
        $columnNeedsPct INTEGER NOT NULL DEFAULT 50,
        $columnWantsPct INTEGER NOT NULL DEFAULT 30,
        $columnSavingsPct INTEGER NOT NULL DEFAULT 20,
        $columnCreatedAt INTEGER NOT NULL,
        $columnUpdatedAt INTEGER NOT NULL,
        $columnHlcTimestamp TEXT NOT NULL DEFAULT '',
        $columnIsDeleted INTEGER NOT NULL DEFAULT 0,
        $columnSyncStatus INTEGER NOT NULL DEFAULT 1
      )
    ''');

    final now = DateTime.now().millisecondsSinceEpoch;

    // Update existing system categories with bucket assignments
    final updates = <String, String>{
      'cat_transport': 'NEEDS',
      'cat_bills': 'NEEDS',
      'cat_healthcare': 'NEEDS',
      'cat_education': 'NEEDS',
      'cat_shopping': 'WANTS',
      'cat_entertainment': 'WANTS',
    };
    for (final entry in updates.entries) {
      await db.update(
        tableCategories,
        {columnBudgetBucket: entry.value, columnUpdatedAt: now},
        where: '$columnId = ?',
        whereArgs: [entry.key],
      );
    }

    // Insert new spec categories that don't exist yet
    final newCategories = [
      // NEEDS
      {'id': 'cat_rent', 'name': 'Rent', 'icon': 0xe318, 'color': 0xFFE17055, 'type': 'expense', 'bucket': 'NEEDS'},
      {'id': 'cat_groceries', 'name': 'Groceries', 'icon': 0xe25a, 'color': 0xFF00B894, 'type': 'expense', 'bucket': 'NEEDS'},
      {'id': 'cat_insurance', 'name': 'Insurance', 'icon': 0xe3f3, 'color': 0xFF0984E3, 'type': 'expense', 'bucket': 'NEEDS'},
      // WANTS
      {'id': 'cat_dining', 'name': 'Dining Out', 'icon': 0xe56c, 'color': 0xFFFF7675, 'type': 'expense', 'bucket': 'WANTS'},
      {'id': 'cat_travel', 'name': 'Travel', 'icon': 0xe1d7, 'color': 0xFF6C5CE7, 'type': 'expense', 'bucket': 'WANTS'},
      {'id': 'cat_subscriptions', 'name': 'Subscriptions', 'icon': 0xe8f8, 'color': 0xFFA29BFE, 'type': 'expense', 'bucket': 'WANTS'},
      // SAVINGS
      {'id': 'cat_emergency', 'name': 'Emergency Fund', 'icon': 0xe002, 'color': 0xFFFF6B6B, 'type': 'expense', 'bucket': 'SAVINGS'},
      {'id': 'cat_retirement', 'name': 'Retirement', 'icon': 0xe227, 'color': 0xFFFFD93D, 'type': 'expense', 'bucket': 'SAVINGS'},
      {'id': 'cat_invest_out', 'name': 'Investments Out', 'icon': 0xe25c, 'color': 0xFF55EFC4, 'type': 'expense', 'bucket': 'SAVINGS'},
      {'id': 'cat_debt', 'name': 'Debt Repayment', 'icon': 0xe870, 'color': 0xFFB2BEC3, 'type': 'expense', 'bucket': 'SAVINGS'},
      // INCOME additions
      {'id': 'cat_gifts', 'name': 'Gifts', 'icon': 0xe1bc, 'color': 0xFFFDAB00, 'type': 'income', 'bucket': null},
    ];

    final batch = db.batch();
    for (final cat in newCategories) {
      batch.insert(
        tableCategories,
        {
          columnId: cat['id'],
          columnCategoryName: cat['name'],
          columnCategoryIcon: cat['icon'],
          columnCategoryColor: cat['color'],
          columnCategoryType: cat['type'],
          columnCategoryIsSystem: 1,
          columnBudgetBucket: cat['bucket'],
          columnCreatedAt: now,
          columnUpdatedAt: now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit();

    // Insert seed budget data for March 2026
    await _insertBudgetSeedData(db);
  }

  /// Insert default categories
  Future<void> _insertDefaultCategories(Database db) async {
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    // Default expense categories
    final expenseCategories = [
      {'id': 'cat_food', 'name': 'Food & Dining', 'icon': 0xe25a, 'color': 0xFFFF6B6B, 'bucket': null},
      {'id': 'cat_transport', 'name': 'Transportation', 'icon': 0xe1d7, 'color': 0xFF4ECDC4, 'bucket': 'NEEDS'},
      {'id': 'cat_shopping', 'name': 'Shopping', 'icon': 0xe59c, 'color': 0xFF95E77E, 'bucket': 'WANTS'},
      {'id': 'cat_entertainment', 'name': 'Entertainment', 'icon': 0xe332, 'color': 0xFFFFD93D, 'bucket': 'WANTS'},
      {'id': 'cat_bills', 'name': 'Bills & Utilities', 'icon': 0xe227, 'color': 0xFF6C5CE7, 'bucket': 'NEEDS'},
      {'id': 'cat_healthcare', 'name': 'Healthcare', 'icon': 0xe3f3, 'color': 0xFFFF6B9D, 'bucket': 'NEEDS'},
      {'id': 'cat_education', 'name': 'Education', 'icon': 0xe80c, 'color': 0xFF778BEB, 'bucket': 'NEEDS'},
      {'id': 'cat_other_expense', 'name': 'Other', 'icon': 0xe468, 'color': 0xFFA8A8A8, 'bucket': null},
      // Spec categories
      {'id': 'cat_rent', 'name': 'Rent', 'icon': 0xe318, 'color': 0xFFE17055, 'bucket': 'NEEDS'},
      {'id': 'cat_groceries', 'name': 'Groceries', 'icon': 0xe56c, 'color': 0xFF00B894, 'bucket': 'NEEDS'},
      {'id': 'cat_insurance', 'name': 'Insurance', 'icon': 0xe3f3, 'color': 0xFF0984E3, 'bucket': 'NEEDS'},
      {'id': 'cat_dining', 'name': 'Dining Out', 'icon': 0xe56c, 'color': 0xFFFF7675, 'bucket': 'WANTS'},
      {'id': 'cat_travel', 'name': 'Travel', 'icon': 0xe1d7, 'color': 0xFF6C5CE7, 'bucket': 'WANTS'},
      {'id': 'cat_subscriptions', 'name': 'Subscriptions', 'icon': 0xe8f8, 'color': 0xFFA29BFE, 'bucket': 'WANTS'},
      {'id': 'cat_emergency', 'name': 'Emergency Fund', 'icon': 0xe002, 'color': 0xFFFF6B6B, 'bucket': 'SAVINGS'},
      {'id': 'cat_retirement', 'name': 'Retirement', 'icon': 0xe227, 'color': 0xFFFFD93D, 'bucket': 'SAVINGS'},
      {'id': 'cat_invest_out', 'name': 'Investments Out', 'icon': 0xe25c, 'color': 0xFF55EFC4, 'bucket': 'SAVINGS'},
      {'id': 'cat_debt', 'name': 'Debt Repayment', 'icon': 0xe870, 'color': 0xFFB2BEC3, 'bucket': 'SAVINGS'},
    ];

    // Default income categories
    final incomeCategories = [
      {'id': 'cat_salary', 'name': 'Salary', 'icon': 0xe227, 'color': 0xFF27AE60, 'bucket': null},
      {'id': 'cat_business', 'name': 'Business', 'icon': 0xe0af, 'color': 0xFF3498DB, 'bucket': null},
      {'id': 'cat_investment', 'name': 'Investment', 'icon': 0xe25c, 'color': 0xFF9B59B6, 'bucket': null},
      {'id': 'cat_freelance', 'name': 'Freelance', 'icon': 0xe3ac, 'color': 0xFFE74C3C, 'bucket': null},
      {'id': 'cat_gifts', 'name': 'Gifts', 'icon': 0xe1bc, 'color': 0xFFFDAB00, 'bucket': null},
      {'id': 'cat_other_income', 'name': 'Other', 'icon': 0xe468, 'color': 0xFF95A5A6, 'bucket': null},
    ];

    for (final category in expenseCategories) {
      batch.insert(tableCategories, {
        columnId: category['id'],
        columnCategoryName: category['name'],
        columnCategoryIcon: category['icon'],
        columnCategoryColor: category['color'],
        columnCategoryType: 'expense',
        columnCategoryIsSystem: 1,
        columnBudgetBucket: category['bucket'],
        columnCreatedAt: now,
        columnUpdatedAt: now,
      });
    }

    for (final category in incomeCategories) {
      batch.insert(tableCategories, {
        columnId: category['id'],
        columnCategoryName: category['name'],
        columnCategoryIcon: category['icon'],
        columnCategoryColor: category['color'],
        columnCategoryType: 'income',
        columnCategoryIsSystem: 1,
        columnBudgetBucket: category['bucket'],
        columnCreatedAt: now,
        columnUpdatedAt: now,
      });
    }

    await batch.commit();
  }

  /// Insert seed budget plan and transactions for March 2026
  Future<void> _insertBudgetSeedData(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final march2026Start = DateTime(2026, 3, 1).millisecondsSinceEpoch;

    // Check if seed plan already exists
    final existing = await db.query(
      tableBudgetPlans,
      where: '$columnPeriodMonth = ? AND $columnPeriodYear = ? AND $columnIsDeleted = 0',
      whereArgs: [3, 2026],
      limit: 1,
    );
    if (existing.isNotEmpty) return;

    // Insert March 2026 budget plan (totalIncome in cents: $5,800 = 580000)
    await db.insert(tableBudgetPlans, {
      columnId: 'budget_seed_march_2026',
      columnBudgetPlanName: 'March 2026',
      columnPeriodMonth: 3,
      columnPeriodYear: 2026,
      columnTotalIncome: 580000,
      columnRuleType: '50-30-20',
      columnNeedsPct: 50,
      columnWantsPct: 30,
      columnSavingsPct: 20,
      columnCreatedAt: now,
      columnUpdatedAt: now,
      columnHlcTimestamp: '',
      columnIsDeleted: 0,
      columnSyncStatus: 0,
    });

    // Insert seed transactions for March 2026 matching spec status:
    // Needs: $2,352 spent → Rent $1,200, Groceries $680, Transportation $250, Insurance $222
    // Wants: $285 spent  → Dining Out $140, Entertainment $80, Subscriptions $65
    // Savings: $900 spent → Emergency Fund $400, Retirement $300, Debt Repayment $200
    final seedTransactions = [
      // NEEDS
      {'id': 'seed_t1', 'desc': 'March Rent', 'amount': 1200.0, 'cat': 'cat_rent', 'day': 1},
      {'id': 'seed_t2', 'desc': 'Grocery Run', 'amount': 680.0, 'cat': 'cat_groceries', 'day': 5},
      {'id': 'seed_t3', 'desc': 'Transport', 'amount': 250.0, 'cat': 'cat_transport', 'day': 8},
      {'id': 'seed_t4', 'desc': 'Insurance Premium', 'amount': 222.0, 'cat': 'cat_insurance', 'day': 10},
      // WANTS
      {'id': 'seed_t5', 'desc': 'Restaurant Dinner', 'amount': 140.0, 'cat': 'cat_dining', 'day': 7},
      {'id': 'seed_t6', 'desc': 'Movie Night', 'amount': 80.0, 'cat': 'cat_entertainment', 'day': 12},
      {'id': 'seed_t7', 'desc': 'Streaming & Apps', 'amount': 65.0, 'cat': 'cat_subscriptions', 'day': 3},
      // SAVINGS
      {'id': 'seed_t8', 'desc': 'Emergency Fund', 'amount': 400.0, 'cat': 'cat_emergency', 'day': 2},
      {'id': 'seed_t9', 'desc': 'Retirement Contribution', 'amount': 300.0, 'cat': 'cat_retirement', 'day': 2},
      {'id': 'seed_t10', 'desc': 'Loan Payment', 'amount': 200.0, 'cat': 'cat_debt', 'day': 4},
      // INCOME
      {'id': 'seed_t11', 'desc': 'March Salary', 'amount': 5800.0, 'cat': 'cat_salary', 'day': 1},
    ];

    final batch = db.batch();
    for (final t in seedTransactions) {
      final day = t['day'] as int;
      final isIncome = t['cat'] == 'cat_salary';
      batch.insert(
        tableTransactions,
        {
          columnId: t['id'],
          columnDescription: t['desc'],
          columnAmount: t['amount'],
          columnDate: DateTime(2026, 3, day).millisecondsSinceEpoch,
          columnType: isIncome ? 'income' : 'expense',
          columnCategoryId: t['cat'],
          columnNote: null,
          columnCreatedAt: march2026Start,
          columnUpdatedAt: march2026Start,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit();
  }

  /// Close database
  Future<void> close() async {
    final db = await database;
    db.close();
    _database = null;
  }

  /// Delete database (for testing or reset)
  Future<void> deleteDatabase() async {
    final String path = join(await getDatabasesPath(), _databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }

  /// Backup database
  Future<String> backupDatabase() async {
    final db = await database;
    final String dbPath = join(await getDatabasesPath(), _databaseName);
    final String backupPath = join(
      await getDatabasesPath(),
      'backup_${DateTime.now().millisecondsSinceEpoch}.db',
    );

    // Close current database connection
    await db.close();
    _database = null;

    // Copy database file
    final dbFile = File(dbPath);
    await dbFile.copy(backupPath);

    // Reopen database
    _database = await _initDatabase();

    return backupPath;
  }

  /// Restore database from backup
  Future<void> restoreDatabase(String backupPath) async {
    final String dbPath = join(await getDatabasesPath(), _databaseName);

    // Close current database
    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    // Copy backup to main database path
    final backupFile = File(backupPath);
    await backupFile.copy(dbPath);

    // Reopen database
    _database = await _initDatabase();
  }

  /// Execute raw SQL query (for debugging)
  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }

  /// Read a preference value by key. Returns null if not set.
  Future<String?> getPreference(String key) async {
    final db = await database;
    final rows = await db.query(
      tablePreferences,
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  /// Write a preference value. Inserts or replaces.
  Future<void> setPreference(String key, String value) async {
    final db = await database;
    await db.insert(
      tablePreferences,
      {
        'key': key,
        'value': value,
        columnUpdatedAt: DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}