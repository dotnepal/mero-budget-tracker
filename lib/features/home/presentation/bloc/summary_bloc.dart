import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/summary_repository.dart';
import 'summary_event.dart';
import 'summary_state.dart';

class SummaryBloc extends Bloc<SummaryEvent, SummaryState> {
  final SummaryRepository repository;

  SummaryBloc({required this.repository}) : super(const SummaryInitial()) {
    on<LoadMonthlySummary>(_onLoadMonthlySummary);
    on<RefreshMonthlySummary>(_onRefreshMonthlySummary);
  }

  Future<void> _onLoadMonthlySummary(
    LoadMonthlySummary event,
    Emitter<SummaryState> emit,
  ) async {
    emit(const SummaryLoading());
    try {
      final summary = await repository.getMonthlySummary(
        year: event.year,
        month: event.month,
      );
      emit(SummaryLoaded(summary));
    } catch (e) {
      emit(SummaryError(e.toString()));
    }
  }

  Future<void> _onRefreshMonthlySummary(
    RefreshMonthlySummary event,
    Emitter<SummaryState> emit,
  ) async {
    if (state is SummaryLoaded) {
      final currentState = state as SummaryLoaded;
      add(LoadMonthlySummary(
        year: currentState.summary.month.year,
        month: currentState.summary.month.month,
      ));
    } else {
      // Default to current month
      final now = DateTime.now();
      add(LoadMonthlySummary(
        year: now.year,
        month: now.month,
      ));
    }
  }
}
