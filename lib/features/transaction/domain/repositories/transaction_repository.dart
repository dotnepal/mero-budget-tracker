import '../../domain/entities/transaction.dart';

abstract class TransactionRepository {
  Future<List<Transaction>> getTransactions({int? limit, int? offset});
  Future<Transaction> addTransaction(Transaction transaction);
  Future<void> deleteTransaction(String id);
  Future<Transaction> updateTransaction(Transaction transaction);
}