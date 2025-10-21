import '../../domain/models/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';

/// In-memory implementation of [TransactionRepository]
class InMemoryTransactionRepository implements TransactionRepository {
  final List<Transaction> _transactions = [];

  @override
  Future<List<Transaction>> getTransactions() async {
    return _transactions;
  }

  @override
  Future<void> addTransaction(Transaction transaction) async {
    _transactions.add(transaction);
  }

  @override
  Future<void> deleteTransaction(String id) async {
    _transactions.removeWhere((transaction) => transaction.id == id);
  }

  @override
  Future<void> updateTransaction(Transaction transaction) async {
    final index = _transactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      _transactions[index] = transaction;
    }
  }
}