import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/in_memory_transaction_repository.dart';
import '../../domain/repositories/transaction_repository.dart';
import 'transaction_event.dart';
import 'transaction_state.dart';

/// BLoC that handles transaction-related state management
class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  TransactionBloc({
    required TransactionRepository repository,
  })  : _repository = repository,
        super(TransactionInitial()) {
    on<LoadTransactions>(_onLoadTransactions);
    on<AddTransaction>(_onAddTransaction);
    on<UpdateTransaction>(_onUpdateTransaction);
    on<DeleteTransaction>(_onDeleteTransaction);
  }

  final TransactionRepository _repository;

  Future<void> _onLoadTransactions(
    LoadTransactions event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    try {
      final transactions = await _repository.getTransactions();
      emit(TransactionLoaded(transactions));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> _onAddTransaction(
    AddTransaction event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      await _repository.addTransaction(event.transaction);
      final transactions = await _repository.getTransactions();
      emit(TransactionLoaded(transactions));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> _onUpdateTransaction(
    UpdateTransaction event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      await _repository.updateTransaction(event.transaction);
      final transactions = await _repository.getTransactions();
      emit(TransactionLoaded(transactions));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> _onDeleteTransaction(
    DeleteTransaction event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      await _repository.deleteTransaction(event.id);
      final transactions = await _repository.getTransactions();
      emit(TransactionLoaded(transactions));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }
}