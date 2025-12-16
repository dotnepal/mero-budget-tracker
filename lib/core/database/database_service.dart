import 'dart:async';

import 'package:sqflite/sqflite.dart' hide Transaction;

import '../../features/transaction/domain/entities/transaction.dart' as domain;
import 'database_helper.dart';

/// Service class that provides high-level database operations
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  bool _isInitialized = false;

  /// Initialize the database service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Ensure database is created and migrations are applied
      final db = await _databaseHelper.database;

      // Verify database is working by running a simple query
      await db.rawQuery('SELECT 1');

      _isInitialized = true;
      // Database service initialized successfully
    } catch (e) {
      // Failed to initialize database service: $e
      rethrow;
    }
  }

  /// Check if database is initialized
  bool get isInitialized => _isInitialized;

  /// Get database helper instance
  DatabaseHelper get databaseHelper => _databaseHelper;

  /// Reset the database (delete all data)
  Future<void> resetDatabase() async {
    await _databaseHelper.deleteDatabase();
    _isInitialized = false;
    await initialize();
  }

  /// Backup database to a file
  Future<String> backupDatabase() async {
    if (!_isInitialized) {
      throw StateError('Database service not initialized');
    }
    return await _databaseHelper.backupDatabase();
  }

  /// Restore database from a backup file
  Future<void> restoreDatabase(String backupPath) async {
    await _databaseHelper.restoreDatabase(backupPath);
    _isInitialized = true;
  }

  /// Export all data as JSON
  Future<Map<String, dynamic>> exportData() async {
    if (!_isInitialized) {
      throw StateError('Database service not initialized');
    }

    final db = await _databaseHelper.database;

    // Export transactions
    final transactions = await db.query(DatabaseHelper.tableTransactions);

    // Export categories
    final categories = await db.query(DatabaseHelper.tableCategories);

    // Export budgets
    final budgets = await db.query(DatabaseHelper.tableBudgets);

    // Export preferences
    final preferences = await db.query(DatabaseHelper.tablePreferences);

    return {
      'version': 1,
      'exportDate': DateTime.now().toIso8601String(),
      'data': {
        'transactions': transactions,
        'categories': categories,
        'budgets': budgets,
        'preferences': preferences,
      },
    };
  }

  /// Import data from JSON
  Future<void> importData(Map<String, dynamic> jsonData) async {
    if (!_isInitialized) {
      throw StateError('Database service not initialized');
    }

    final db = await _databaseHelper.database;

    // Validate data structure
    if (!jsonData.containsKey('data')) {
      throw ArgumentError('Invalid import data structure');
    }

    final data = jsonData['data'] as Map<String, dynamic>;

    // Start transaction for atomic import
    await db.transaction((txn) async {
      // Clear existing data (optional, based on import strategy)
      // await txn.delete(DatabaseHelper.tableTransactions);
      // await txn.delete(DatabaseHelper.tableCategories, where: 'is_system = 0');
      // await txn.delete(DatabaseHelper.tableBudgets);

      // Import categories first (due to foreign key constraints)
      if (data.containsKey('categories')) {
        final categories = data['categories'] as List<dynamic>;
        for (final category in categories) {
          await txn.insert(
            DatabaseHelper.tableCategories,
            category as Map<String, dynamic>,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      // Import transactions
      if (data.containsKey('transactions')) {
        final transactions = data['transactions'] as List<dynamic>;
        for (final transaction in transactions) {
          await txn.insert(
            DatabaseHelper.tableTransactions,
            transaction as Map<String, dynamic>,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      // Import budgets
      if (data.containsKey('budgets')) {
        final budgets = data['budgets'] as List<dynamic>;
        for (final budget in budgets) {
          await txn.insert(
            DatabaseHelper.tableBudgets,
            budget as Map<String, dynamic>,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      // Import preferences
      if (data.containsKey('preferences')) {
        final preferences = data['preferences'] as List<dynamic>;
        for (final pref in preferences) {
          await txn.insert(
            DatabaseHelper.tablePreferences,
            pref as Map<String, dynamic>,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });
  }

  /// Get database statistics
  Future<Map<String, dynamic>> getDatabaseStats() async {
    if (!_isInitialized) {
      throw StateError('Database service not initialized');
    }

    final db = await _databaseHelper.database;

    final transactionCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseHelper.tableTransactions}'),
    ) ?? 0;

    final categoryCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseHelper.tableCategories}'),
    ) ?? 0;

    final budgetCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseHelper.tableBudgets}'),
    ) ?? 0;

    // Get database file size
    final dbPath = db.path;

    return {
      'transactionCount': transactionCount,
      'categoryCount': categoryCount,
      'budgetCount': budgetCount,
      'databasePath': dbPath,
      'isInitialized': _isInitialized,
    };
  }

  /// Perform database maintenance (optimize, vacuum, etc.)
  Future<void> performMaintenance() async {
    if (!_isInitialized) {
      throw StateError('Database service not initialized');
    }

    final db = await _databaseHelper.database;

    // Vacuum the database to reclaim unused space
    await db.execute('VACUUM');

    // Analyze tables for query optimization
    await db.execute('ANALYZE');

    // Database maintenance completed
  }

  /// Check database integrity
  Future<bool> checkIntegrity() async {
    if (!_isInitialized) {
      throw StateError('Database service not initialized');
    }

    final db = await _databaseHelper.database;

    try {
      // Run integrity check
      final result = await db.rawQuery('PRAGMA integrity_check');

      if (result.isNotEmpty && result.first.values.first == 'ok') {
        // Database integrity check passed
        return true;
      } else {
        // Database integrity check failed: $result
        return false;
      }
    } catch (e) {
      // Database integrity check error: $e
      return false;
    }
  }

  /// Clear all transactions (keep categories and settings)
  Future<void> clearTransactions() async {
    if (!_isInitialized) {
      throw StateError('Database service not initialized');
    }

    final db = await _databaseHelper.database;
    await db.delete(DatabaseHelper.tableTransactions);
    // All transactions cleared
  }

  /// Get sample data for testing
  static List<domain.Transaction> getSampleTransactions() {
    final now = DateTime.now();
    return [
      domain.Transaction(
        id: 'sample_1',
        description: 'Grocery Shopping',
        amount: 85.50,
        date: now.subtract(const Duration(days: 1)),
        type: domain.TransactionType.expense,
        category: 'cat_food',
        note: 'Weekly groceries',
      ),
      domain.Transaction(
        id: 'sample_2',
        description: 'Salary',
        amount: 3000.00,
        date: now.subtract(const Duration(days: 5)),
        type: domain.TransactionType.income,
        category: 'cat_salary',
        note: 'Monthly salary',
      ),
      domain.Transaction(
        id: 'sample_3',
        description: 'Coffee',
        amount: 5.50,
        date: now,
        type: domain.TransactionType.expense,
        category: 'cat_food',
        note: 'Morning coffee',
      ),
      domain.Transaction(
        id: 'sample_4',
        description: 'Uber Ride',
        amount: 15.75,
        date: now.subtract(const Duration(days: 2)),
        type: domain.TransactionType.expense,
        category: 'cat_transport',
        note: 'Ride to office',
      ),
      domain.Transaction(
        id: 'sample_5',
        description: 'Freelance Project',
        amount: 500.00,
        date: now.subtract(const Duration(days: 3)),
        type: domain.TransactionType.income,
        category: 'cat_freelance',
        note: 'Website development',
      ),
    ];
  }

  /// Insert sample data for testing
  Future<void> insertSampleData() async {
    if (!_isInitialized) {
      throw StateError('Database service not initialized');
    }

    final db = await _databaseHelper.database;
    final sampleTransactions = getSampleTransactions();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final transaction in sampleTransactions) {
      await db.insert(
        DatabaseHelper.tableTransactions,
        {
          DatabaseHelper.columnId: transaction.id,
          DatabaseHelper.columnDescription: transaction.description,
          DatabaseHelper.columnAmount: transaction.amount,
          DatabaseHelper.columnDate: transaction.date.millisecondsSinceEpoch,
          DatabaseHelper.columnType: transaction.type.toString().split('.').last,
          DatabaseHelper.columnCategoryId: transaction.category,
          DatabaseHelper.columnNote: transaction.note,
          DatabaseHelper.columnCreatedAt: now,
          DatabaseHelper.columnUpdatedAt: now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    // Sample data inserted successfully
  }
}
