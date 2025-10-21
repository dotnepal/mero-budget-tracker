import '../models/transaction.dart';

/// Repository interface for transaction-related operations
abstract class TransactionRepository {
  /// Get all transactions
  Future<List<Transaction>> getTransactions();
  
  /// Add a new transaction
  Future<void> addTransaction(Transaction transaction);
  
  /// Delete a transaction
  Future<void> deleteTransaction(String id);
  
  /// Update an existing transaction
  Future<void> updateTransaction(Transaction transaction);
}