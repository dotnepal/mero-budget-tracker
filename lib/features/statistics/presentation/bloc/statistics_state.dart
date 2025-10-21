import 'package:equatable/equatable.dart';
import '../../domain/entities/financial_summary.dart';
import '../../../transaction/domain/entities/transaction.dart';

abstract class StatisticsState extends Equatable {
  const StatisticsState();

  @override
  List<Object> get props => [];
}

class StatisticsInitial extends StatisticsState {
  const StatisticsInitial();
}

class StatisticsLoading extends StatisticsState {
  const StatisticsLoading();
}

class StatisticsLoaded extends StatisticsState {
  final FinancialSummary summary;
  final List<Transaction> transactions;

  const StatisticsLoaded({
    required this.summary,
    required this.transactions,
  });

  @override
  List<Object> get props => [summary, transactions];
}

class StatisticsError extends StatisticsState {
  final String message;

  const StatisticsError(this.message);

  @override
  List<Object> get props => [message];
}
