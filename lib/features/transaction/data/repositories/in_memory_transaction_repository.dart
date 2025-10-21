import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';

class InMemoryTransactionRepository implements TransactionRepository {
  final List<Transaction> _transactions = [];

  @override
  Future<List<Transaction>> getTransactions({int? limit, int? offset}) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay

    // Sort transactions by date (newest first)
    final sortedTransactions = List<Transaction>.from(_transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    if (limit != null && offset != null) {
      final end = offset + limit;
      return sortedTransactions
          .sublist(offset, end > sortedTransactions.length ? sortedTransactions.length : end);
    }

    return sortedTransactions;
  }

  @override
  Future<Transaction> addTransaction(Transaction transaction) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _transactions.add(transaction);
    return transaction;
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _transactions.removeWhere((t) => t.id == id);
  }

  @override
  Future<Transaction> updateTransaction(Transaction transaction) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _transactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      _transactions[index] = transaction;
      return transaction;
    }
    throw Exception('Transaction not found');
  }

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
