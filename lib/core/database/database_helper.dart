import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Database helper class that manages SQLite database operations
class DatabaseHelper {
  static const String _databaseName = 'mero_budget_tracker.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String tableTransactions = 'transactions';
  static const String tableCategories = 'categories';
  static const String tableBudgets = 'budgets';
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

  // Budget table columns
  static const String columnBudgetCategoryId = 'category_id';
  static const String columnBudgetAmount = 'amount';
  static const String columnBudgetPeriod = 'period';
  static const String columnBudgetStartDate = 'start_date';
  static const String columnBudgetEndDate = 'end_date';

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

    // Create budgets table
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
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle migrations based on version
    if (oldVersion < 2) {
      // Future migration example
      // await db.execute('ALTER TABLE $tableTransactions ADD COLUMN tags TEXT');
    }
  }

  /// Insert default categories
  Future<void> _insertDefaultCategories(Database db) async {
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    // Default expense categories
    final expenseCategories = [
      {'id': 'cat_food', 'name': 'Food & Dining', 'icon': 0xe25a, 'color': 0xFFFF6B6B},
      {'id': 'cat_transport', 'name': 'Transportation', 'icon': 0xe1d7, 'color': 0xFF4ECDC4},
      {'id': 'cat_shopping', 'name': 'Shopping', 'icon': 0xe59c, 'color': 0xFF95E77E},
      {'id': 'cat_entertainment', 'name': 'Entertainment', 'icon': 0xe332, 'color': 0xFFFFD93D},
      {'id': 'cat_bills', 'name': 'Bills & Utilities', 'icon': 0xe227, 'color': 0xFF6C5CE7},
      {'id': 'cat_healthcare', 'name': 'Healthcare', 'icon': 0xe3f3, 'color': 0xFFFF6B9D},
      {'id': 'cat_education', 'name': 'Education', 'icon': 0xe80c, 'color': 0xFF778BEB},
      {'id': 'cat_other_expense', 'name': 'Other', 'icon': 0xe468, 'color': 0xFFA8A8A8},
    ];

    // Default income categories
    final incomeCategories = [
      {'id': 'cat_salary', 'name': 'Salary', 'icon': 0xe227, 'color': 0xFF27AE60},
      {'id': 'cat_business', 'name': 'Business', 'icon': 0xe0af, 'color': 0xFF3498DB},
      {'id': 'cat_investment', 'name': 'Investment', 'icon': 0xe25c, 'color': 0xFF9B59B6},
      {'id': 'cat_freelance', 'name': 'Freelance', 'icon': 0xe3ac, 'color': 0xFFE74C3C},
      {'id': 'cat_other_income', 'name': 'Other', 'icon': 0xe468, 'color': 0xFF95A5A6},
    ];

    // Insert expense categories
    for (final category in expenseCategories) {
      batch.insert(tableCategories, {
        columnId: category['id'],
        columnCategoryName: category['name'],
        columnCategoryIcon: category['icon'],
        columnCategoryColor: category['color'],
        columnCategoryType: 'expense',
        columnCategoryIsSystem: 1,
        columnCreatedAt: now,
        columnUpdatedAt: now,
      });
    }

    // Insert income categories
    for (final category in incomeCategories) {
      batch.insert(tableCategories, {
        columnId: category['id'],
        columnCategoryName: category['name'],
        columnCategoryIcon: category['icon'],
        columnCategoryColor: category['color'],
        columnCategoryType: 'income',
        columnCategoryIsSystem: 1,
        columnCreatedAt: now,
        columnUpdatedAt: now,
      });
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

    // Copy database file - SQLite doesn't have a built-in copy method
    // We'll need to use file system operations
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
}
