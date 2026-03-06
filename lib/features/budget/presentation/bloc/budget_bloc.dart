import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/sqlite_budget_repository.dart';
import '../../data/services/budget_service.dart';
import '../../domain/entities/budget_plan.dart';
import '../../domain/entities/budget_status.dart';

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

abstract class BudgetEvent extends Equatable {
  const BudgetEvent();

  @override
  List<Object?> get props => [];
}

class LoadBudgetForPeriod extends BudgetEvent {
  final int month;
  final int year;

  const LoadBudgetForPeriod({required this.month, required this.year});

  @override
  List<Object?> get props => [month, year];
}

class CreateBudgetPlan extends BudgetEvent {
  final int totalIncomeCents;
  final int month;
  final int year;
  final String ruleType;

  const CreateBudgetPlan({
    required this.totalIncomeCents,
    required this.month,
    required this.year,
    this.ruleType = '50-30-20',
  });

  @override
  List<Object?> get props => [totalIncomeCents, month, year, ruleType];
}

class DeleteBudgetPlan extends BudgetEvent {
  final String id;

  const DeleteBudgetPlan(this.id);

  @override
  List<Object?> get props => [id];
}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

abstract class BudgetState extends Equatable {
  const BudgetState();

  @override
  List<Object?> get props => [];
}

class BudgetInitial extends BudgetState {}

class BudgetLoading extends BudgetState {}

class BudgetLoaded extends BudgetState {
  final BudgetPlan plan;
  final BudgetStatus status;

  const BudgetLoaded({required this.plan, required this.status});

  @override
  List<Object?> get props => [plan, status];
}

class BudgetNoPlan extends BudgetState {
  final int month;
  final int year;

  const BudgetNoPlan({required this.month, required this.year});

  @override
  List<Object?> get props => [month, year];
}

class BudgetError extends BudgetState {
  final String message;

  const BudgetError(this.message);

  @override
  List<Object?> get props => [message];
}

// ---------------------------------------------------------------------------
// Bloc
// ---------------------------------------------------------------------------

class BudgetBloc extends Bloc<BudgetEvent, BudgetState> {
  final BudgetService _service;

  BudgetBloc({required BudgetService service})
      : _service = service,
        super(BudgetInitial()) {
    on<LoadBudgetForPeriod>(_onLoad);
    on<CreateBudgetPlan>(_onCreate);
    on<DeleteBudgetPlan>(_onDelete);
  }

  Future<void> _onLoad(
    LoadBudgetForPeriod event,
    Emitter<BudgetState> emit,
  ) async {
    emit(BudgetLoading());
    try {
      final status = await _service.getStatusForPeriod(event.month, event.year);
      if (status == null) {
        emit(BudgetNoPlan(month: event.month, year: event.year));
      } else {
        emit(BudgetLoaded(plan: status.plan, status: status));
      }
    } catch (e) {
      emit(BudgetError(e.toString()));
    }
  }

  Future<void> _onCreate(
    CreateBudgetPlan event,
    Emitter<BudgetState> emit,
  ) async {
    emit(BudgetLoading());
    try {
      await _service.createPlan(
        totalIncomeCents: event.totalIncomeCents,
        month: event.month,
        year: event.year,
        ruleType: event.ruleType,
      );
      // Reload to get full status
      final status = await _service.getStatusForPeriod(event.month, event.year);
      if (status == null) {
        emit(BudgetNoPlan(month: event.month, year: event.year));
      } else {
        emit(BudgetLoaded(plan: status.plan, status: status));
      }
    } catch (e) {
      emit(BudgetError(e.toString()));
    }
  }

  Future<void> _onDelete(
    DeleteBudgetPlan event,
    Emitter<BudgetState> emit,
  ) async {
    try {
      final repo = SqliteBudgetRepository();
      await repo.deletePlan(event.id);
      if (state is BudgetLoaded) {
        final current = state as BudgetLoaded;
        emit(BudgetNoPlan(
          month: current.plan.periodMonth,
          year: current.plan.periodYear,
        ));
      }
    } catch (e) {
      emit(BudgetError(e.toString()));
    }
  }
}