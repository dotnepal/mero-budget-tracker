import 'dart:async';

import 'package:sqflite/sqflite.dart' hide Transaction;

import '../../../../core/database/database_helper.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';

/// SQLite implementation of [TransactionRepository]
class SqliteTransactionRepository implements TransactionRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  @override
  Future<List<Transaction>> getTransactions({
    int? offset,
    int? limit,
  }) async {
    final db = await _databaseHelper.database;

    // Build query with pagination
    String query = '''
      SELECT * FROM ${DatabaseHelper.tableTransactions}
      ORDER BY ${DatabaseHelper.columnDate} DESC
    ''';

    if (limit != null) {
      query += ' LIMIT $limit';
      if (offset != null) {
        query += ' OFFSET $offset';
      }
    }

    final List<Map<String, dynamic>> maps = await db.rawQuery(query);

    return List.generate(maps.length, (i) {
      return _mapToTransaction(maps[i]);
    });
  }

  @override
  Future<Transaction> addTransaction(Transaction transaction) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;

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

  @override
  Future<Transaction> updateTransaction(Transaction transaction) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.update(
      DatabaseHelper.tableTransactions,
      {
        DatabaseHelper.columnDescription: transaction.description,
        DatabaseHelper.columnAmount: transaction.amount,
        DatabaseHelper.columnDate: transaction.date.millisecondsSinceEpoch,
        DatabaseHelper.columnType: transaction.type.toString().split('.').last,
        DatabaseHelper.columnCategoryId: transaction.category,
        DatabaseHelper.columnNote: transaction.note,
        DatabaseHelper.columnUpdatedAt: now,
      },
      where: '${DatabaseHelper.columnId} = ?',
      whereArgs: [transaction.id],
    );

    return transaction;
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final db = await _databaseHelper.database;

    await db.delete(
      DatabaseHelper.tableTransactions,
      where: '${DatabaseHelper.columnId} = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<Transaction>> getTransactionsInRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return await getTransactionsByDateRange(
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Get transactions by date range
  Future<List<Transaction>> getTransactionsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    TransactionType? type,
    String? categoryId,
  }) async {
    final db = await _databaseHelper.database;

    String whereClause = '${DatabaseHelper.columnDate} >= ? AND ${DatabaseHelper.columnDate} <= ?';
    List<dynamic> whereArgs = [
      startDate.millisecondsSinceEpoch,
      endDate.millisecondsSinceEpoch,
    ];

    if (type != null) {
      whereClause += ' AND ${DatabaseHelper.columnType} = ?';
      whereArgs.add(type.toString().split('.').last);
    }

    if (categoryId != null) {
      whereClause += ' AND ${DatabaseHelper.columnCategoryId} = ?';
      whereArgs.add(categoryId);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableTransactions,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: '${DatabaseHelper.columnDate} DESC',
    );

    return List.generate(maps.length, (i) {
      return _mapToTransaction(maps[i]);
    });
  }

  /// Search transactions by description or note
  Future<List<Transaction>> searchTransactions({
    required String query,
    int? limit,
  }) async {
    final db = await _databaseHelper.database;

    final searchQuery = '%$query%';

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableTransactions,
      where: '${DatabaseHelper.columnDescription} LIKE ? OR ${DatabaseHelper.columnNote} LIKE ?',
      whereArgs: [searchQuery, searchQuery],
      orderBy: '${DatabaseHelper.columnDate} DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) {
      return _mapToTransaction(maps[i]);
    });
  }

  /// Get transaction statistics
  Future<Map<String, dynamic>> getTransactionStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _databaseHelper.database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (startDate != null && endDate != null) {
      whereClause = 'WHERE ${DatabaseHelper.columnDate} >= ? AND ${DatabaseHelper.columnDate} <= ?';
      whereArgs = [
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      ];
    }

    // Get total income
    final incomeResult = await db.rawQuery('''
      SELECT SUM(${DatabaseHelper.columnAmount}) as total
      FROM ${DatabaseHelper.tableTransactions}
      $whereClause ${whereClause.isNotEmpty ? 'AND' : 'WHERE'} ${DatabaseHelper.columnType} = 'income'
    ''', whereArgs);

    // Get total expenses
    final expenseResult = await db.rawQuery('''
      SELECT SUM(${DatabaseHelper.columnAmount}) as total
      FROM ${DatabaseHelper.tableTransactions}
      $whereClause ${whereClause.isNotEmpty ? 'AND' : 'WHERE'} ${DatabaseHelper.columnType} = 'expense'
    ''', whereArgs);

    // Get transaction count
    final countResult = await db.rawQuery('''
      SELECT
        COUNT(*) as total,
        COUNT(CASE WHEN ${DatabaseHelper.columnType} = 'income' THEN 1 END) as income_count,
        COUNT(CASE WHEN ${DatabaseHelper.columnType} = 'expense' THEN 1 END) as expense_count
      FROM ${DatabaseHelper.tableTransactions}
      $whereClause
    ''', whereArgs);

    return {
      'totalIncome': incomeResult.first['total'] ?? 0.0,
      'totalExpenses': expenseResult.first['total'] ?? 0.0,
      'totalTransactions': countResult.first['total'] ?? 0,
      'incomeCount': countResult.first['income_count'] ?? 0,
      'expenseCount': countResult.first['expense_count'] ?? 0,
      'balance': (incomeResult.first['total'] as num? ?? 0.0) -
                 (expenseResult.first['total'] as num? ?? 0.0),
    };
  }

  /// Delete all transactions (for testing or reset)
  Future<void> deleteAllTransactions() async {
    final db = await _databaseHelper.database;
    await db.delete(DatabaseHelper.tableTransactions);
  }

  /// Convert database map to Transaction entity
  Transaction _mapToTransaction(Map<String, dynamic> map) {
    return Transaction(
      id: map[DatabaseHelper.columnId],
      description: map[DatabaseHelper.columnDescription],
      amount: map[DatabaseHelper.columnAmount],
      date: DateTime.fromMillisecondsSinceEpoch(map[DatabaseHelper.columnDate]),
      type: map[DatabaseHelper.columnType] == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      category: map[DatabaseHelper.columnCategoryId],
      note: map[DatabaseHelper.columnNote],
    );
  }

  /// Generate random string for ID generation
  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final now = DateTime.now();
    int seed = now.millisecondsSinceEpoch;

    String result = '';
    for (int i = 0; i < length; i++) {
      seed = (seed * 1103515245 + 12345) % (1 << 32);
      result += chars[seed % chars.length];
    }
    return result;
  }
}
