import '../../domain/entities/transaction.dart';

abstract class TransactionRepository {
  Future<List<Transaction>> getTransactions({
    required String userId,
    int? limit,
    int? offset,
  });

  Future<Transaction> addTransaction(Transaction transaction, {required String userId});

  Future<void> deleteTransaction(String id, {required String userId});

  Future<Transaction> updateTransaction(Transaction transaction, {required String userId});

  Future<List<Transaction>> getTransactionsInRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  });
}
