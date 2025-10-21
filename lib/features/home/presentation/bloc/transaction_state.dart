import 'package:equatable/equatable.dart';
import '../../domain/models/transaction.dart';

/// Base class for all transaction states
abstract class TransactionState extends Equatable {
  const TransactionState();

  @override
  List<Object?> get props => [];
}

/// Initial state when no transactions have been loaded
class TransactionInitial extends TransactionState {}

/// State when transactions are being loaded
class TransactionLoading extends TransactionState {}

/// State when transactions have been successfully loaded
class TransactionLoaded extends TransactionState {
  const TransactionLoaded(this.transactions);

  final List<Transaction> transactions;

  @override
  List<Object?> get props => [transactions];
}

/// State when an error occurs during transaction operations
class TransactionError extends TransactionState {
  const TransactionError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}