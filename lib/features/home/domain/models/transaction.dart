/// Represents a financial transaction in the app
class Transaction {
  /// Creates a new [Transaction]
  Transaction({
    required this.id,
    required this.amount,
    required this.description,
    required this.date,
    required this.type,
  });

  /// Unique identifier for the transaction
  final String id;
  
  /// Amount of the transaction
  final double amount;
  
  /// Description of the transaction
  final String description;
  
  /// Date of the transaction
  final DateTime date;
  
  /// Type of transaction (income/expense)
  final TransactionType type;
}

/// Types of transactions
enum TransactionType {
  /// Money coming in
  income,
  
  /// Money going out
  expense
}