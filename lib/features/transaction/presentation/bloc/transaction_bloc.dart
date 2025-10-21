import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';

// Events
abstract class TransactionEvent extends Equatable {
  const TransactionEvent();

  @override
  List<Object> get props => [];
}

class LoadTransactions extends TransactionEvent {
  const LoadTransactions();
}

class LoadMoreTransactions extends TransactionEvent {
  final int pageSize;

  const LoadMoreTransactions({required this.pageSize});

  @override
  List<Object> get props => [pageSize];
}

class RefreshTransactions extends TransactionEvent {
  const RefreshTransactions();
}

class DeleteTransaction extends TransactionEvent {
  final String id;

  const DeleteTransaction(this.id);

  @override
  List<Object> get props => [id];
}

class AddTransaction extends TransactionEvent {
  final Transaction transaction;

  const AddTransaction(this.transaction);

  @override
  List<Object> get props => [transaction];
}

// States
abstract class TransactionState extends Equatable {
  const TransactionState();

  @override
  List<Object> get props => [];
}

class TransactionInitial extends TransactionState {}

class TransactionLoading extends TransactionState {}

class TransactionLoadingMore extends TransactionState {
  final List<Transaction> currentTransactions;

  const TransactionLoadingMore(this.currentTransactions);

  @override
  List<Object> get props => [currentTransactions];
}

class TransactionLoaded extends TransactionState {
  final List<Transaction> transactions;

  const TransactionLoaded(this.transactions);

  @override
  List<Object> get props => [transactions];
}

class TransactionError extends TransactionState {
  final String message;

  const TransactionError(this.message);

  @override
  List<Object> get props => [message];
}

// Bloc
class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final TransactionRepository repository;

  TransactionBloc({
    required this.repository,
  }) : super(TransactionInitial()) {
    on<LoadTransactions>(_onLoadTransactions);
    on<LoadMoreTransactions>(_onLoadMoreTransactions);
    on<RefreshTransactions>(_onRefreshTransactions);
    on<DeleteTransaction>(_onDeleteTransaction);
    on<AddTransaction>(_onAddTransaction);
  }

  Future<void> _onLoadTransactions(
    LoadTransactions event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    try {
      final transactions = await repository.getTransactions();
      emit(TransactionLoaded(transactions));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> _onLoadMoreTransactions(
    LoadMoreTransactions event,
    Emitter<TransactionState> emit,
  ) async {
    if (state is TransactionLoaded) {
      final currentState = state as TransactionLoaded;
      emit(TransactionLoadingMore(currentState.transactions));
      try {
        final newTransactions = await repository.getTransactions(
          offset: currentState.transactions.length,
          limit: event.pageSize,
        );
        emit(TransactionLoaded([
          ...currentState.transactions,
          ...newTransactions,
        ]));
      } catch (e) {
        emit(TransactionError(e.toString()));
      }
    }
  }

  Future<void> _onRefreshTransactions(
    RefreshTransactions event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      final transactions = await repository.getTransactions();
      emit(TransactionLoaded(transactions));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> _onDeleteTransaction(
    DeleteTransaction event,
    Emitter<TransactionState> emit,
  ) async {
    if (state is TransactionLoaded) {
      final currentState = state as TransactionLoaded;
      try {
        await repository.deleteTransaction(event.id);
        final updatedTransactions = currentState.transactions
            .where((t) => t.id != event.id)
            .toList();
        emit(TransactionLoaded(updatedTransactions));
      } catch (e) {
        emit(TransactionError(e.toString()));
      }
    }
  }

  Future<void> _onAddTransaction(
    AddTransaction event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      final transaction = await repository.addTransaction(event.transaction);
      
      if (state is TransactionLoaded) {
        final currentState = state as TransactionLoaded;
        final updatedTransactions = [
          transaction,
          ...currentState.transactions,
        ];
        emit(TransactionLoaded(updatedTransactions));
      } else {
        emit(TransactionLoaded([transaction]));
      }
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }
}