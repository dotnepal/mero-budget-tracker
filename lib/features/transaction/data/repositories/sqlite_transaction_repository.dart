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
    required String userId,
    int? offset,
    int? limit,
  }) async {
    final db = await _databaseHelper.database;

    String query = '''
      SELECT * FROM ${DatabaseHelper.tableTransactions}
      WHERE ${DatabaseHelper.columnUserId} = ?
      ORDER BY ${DatabaseHelper.columnDate} DESC
    ''';

    if (limit != null) {
      query += ' LIMIT $limit';
      if (offset != null) {
        query += ' OFFSET $offset';
      }
    }

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, [userId]);

    return List.generate(maps.length, (i) => _mapToTransaction(maps[i]));
  }

  @override
  Future<Transaction> addTransaction(
    Transaction transaction, {
    required String userId,
  }) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    final id =
        'txn_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(6)}';
    final transactionWithId = transaction.copyWith(id: id);

    await db.insert(
      DatabaseHelper.tableTransactions,
      {
        DatabaseHelper.columnId: transactionWithId.id,
        DatabaseHelper.columnDescription: transactionWithId.description,
        DatabaseHelper.columnAmount: transactionWithId.amount,
        DatabaseHelper.columnDate:
            transactionWithId.date.millisecondsSinceEpoch,
        DatabaseHelper.columnType:
            transactionWithId.type.toString().split('.').last,
        DatabaseHelper.columnCategoryId: transactionWithId.category,
        DatabaseHelper.columnNote: transactionWithId.note,
        DatabaseHelper.columnUserId: userId,
        DatabaseHelper.columnCreatedAt: now,
        DatabaseHelper.columnUpdatedAt: now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return transactionWithId;
  }

  @override
  Future<Transaction> updateTransaction(
    Transaction transaction, {
    required String userId,
  }) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.update(
      DatabaseHelper.tableTransactions,
      {
        DatabaseHelper.columnDescription: transaction.description,
        DatabaseHelper.columnAmount: transaction.amount,
        DatabaseHelper.columnDate: transaction.date.millisecondsSinceEpoch,
        DatabaseHelper.columnType:
            transaction.type.toString().split('.').last,
        DatabaseHelper.columnCategoryId: transaction.category,
        DatabaseHelper.columnNote: transaction.note,
        DatabaseHelper.columnUpdatedAt: now,
      },
      where:
          '${DatabaseHelper.columnId} = ? AND ${DatabaseHelper.columnUserId} = ?',
      whereArgs: [transaction.id, userId],
    );

    return transaction;
  }

  @override
  Future<void> deleteTransaction(String id, {required String userId}) async {
    final db = await _databaseHelper.database;

    await db.delete(
      DatabaseHelper.tableTransactions,
      where:
          '${DatabaseHelper.columnId} = ? AND ${DatabaseHelper.columnUserId} = ?',
      whereArgs: [id, userId],
    );
  }

  @override
  Future<List<Transaction>> getTransactionsInRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return await getTransactionsByDateRange(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Get transactions by date range with optional type/category filters
  Future<List<Transaction>> getTransactionsByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    TransactionType? type,
    String? categoryId,
  }) async {
    final db = await _databaseHelper.database;

    String whereClause =
        '${DatabaseHelper.columnUserId} = ? AND ${DatabaseHelper.columnDate} >= ? AND ${DatabaseHelper.columnDate} <= ?';
    List<dynamic> whereArgs = [
      userId,
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

    return List.generate(maps.length, (i) => _mapToTransaction(maps[i]));
  }

  /// Search transactions by description or note
  Future<List<Transaction>> searchTransactions({
    required String userId,
    required String query,
    int? limit,
  }) async {
    final db = await _databaseHelper.database;

    final searchQuery = '%$query%';

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableTransactions,
      where:
          '${DatabaseHelper.columnUserId} = ? AND (${DatabaseHelper.columnDescription} LIKE ? OR ${DatabaseHelper.columnNote} LIKE ?)',
      whereArgs: [userId, searchQuery, searchQuery],
      orderBy: '${DatabaseHelper.columnDate} DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) => _mapToTransaction(maps[i]));
  }

  /// Get transaction statistics scoped to a user
  Future<Map<String, dynamic>> getTransactionStats({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _databaseHelper.database;

    // userId is always present; date range is optional
    String whereClause = 'WHERE ${DatabaseHelper.columnUserId} = ?';
    List<dynamic> whereArgs = [userId];

    if (startDate != null && endDate != null) {
      whereClause +=
          ' AND ${DatabaseHelper.columnDate} >= ? AND ${DatabaseHelper.columnDate} <= ?';
      whereArgs.addAll([
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      ]);
    }

    final incomeResult = await db.rawQuery('''
      SELECT SUM(${DatabaseHelper.columnAmount}) as total
      FROM ${DatabaseHelper.tableTransactions}
      $whereClause AND ${DatabaseHelper.columnType} = 'income'
    ''', whereArgs);

    final expenseResult = await db.rawQuery('''
      SELECT SUM(${DatabaseHelper.columnAmount}) as total
      FROM ${DatabaseHelper.tableTransactions}
      $whereClause AND ${DatabaseHelper.columnType} = 'expense'
    ''', whereArgs);

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

  /// Delete all transactions (used on sign-out)
  Future<void> deleteAllTransactions() async {
    final db = await _databaseHelper.database;
    await db.delete(DatabaseHelper.tableTransactions);
  }

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
