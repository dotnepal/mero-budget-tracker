import 'package:equatable/equatable.dart';

abstract class SummaryEvent extends Equatable {
  const SummaryEvent();

  @override
  List<Object> get props => [];
}

class LoadMonthlySummary extends SummaryEvent {
  final int year;
  final int month;

  const LoadMonthlySummary({
    required this.year,
    required this.month,
  });

  @override
  List<Object> get props => [year, month];
}

class RefreshMonthlySummary extends SummaryEvent {
  const RefreshMonthlySummary();
}
