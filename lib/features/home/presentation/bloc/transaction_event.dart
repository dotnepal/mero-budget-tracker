import 'package:equatable/equatable.dart';
import '../../domain/models/transaction.dart';

/// Base class for all transaction events
abstract class TransactionEvent extends Equatable {
  const TransactionEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load all transactions
class LoadTransactions extends TransactionEvent {}

/// Event to add a new transaction
class AddTransaction extends TransactionEvent {
  const AddTransaction(this.transaction);

  final Transaction transaction;

  @override
  List<Object?> get props => [transaction];
}

/// Event to update an existing transaction
class UpdateTransaction extends TransactionEvent {
  const UpdateTransaction(this.transaction);

  final Transaction transaction;

  @override
  List<Object?> get props => [transaction];
}

/// Event to delete a transaction
class DeleteTransaction extends TransactionEvent {
  const DeleteTransaction(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}