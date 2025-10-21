import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/statistics_repository.dart';
import 'statistics_event.dart';
import 'statistics_state.dart';

class StatisticsBloc extends Bloc<StatisticsEvent, StatisticsState> {
  final StatisticsRepository repository;

  StatisticsBloc({required this.repository}) : super(const StatisticsInitial()) {
    on<LoadStatistics>(_onLoadStatistics);
    on<RefreshStatistics>(_onRefreshStatistics);
  }

  Future<void> _onLoadStatistics(
    LoadStatistics event,
    Emitter<StatisticsState> emit,
  ) async {
    emit(const StatisticsLoading());
    try {
      final summary = await repository.getFinancialSummary(
        startDate: event.startDate,
        endDate: event.endDate,
      );

      final transactions = await repository.getTransactionsInRange(
        startDate: event.startDate,
        endDate: event.endDate,
      );

      emit(StatisticsLoaded(
        summary: summary,
        transactions: transactions,
      ));
    } catch (e) {
      emit(StatisticsError(e.toString()));
    }
  }

  Future<void> _onRefreshStatistics(
    RefreshStatistics event,
    Emitter<StatisticsState> emit,
  ) async {
    if (state is StatisticsLoaded) {
      final currentState = state as StatisticsLoaded;
      add(LoadStatistics(
        startDate: currentState.summary.startDate,
        endDate: currentState.summary.endDate,
      ));
    } else {
      // Default to current month if no previous state
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      add(LoadStatistics(
        startDate: startOfMonth,
        endDate: endOfMonth,
      ));
    }
  }
}
