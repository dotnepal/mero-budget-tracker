import 'package:equatable/equatable.dart';

abstract class StatisticsEvent extends Equatable {
  const StatisticsEvent();

  @override
  List<Object> get props => [];
}

class LoadStatistics extends StatisticsEvent {
  final DateTime startDate;
  final DateTime endDate;

  const LoadStatistics({
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object> get props => [startDate, endDate];
}

class RefreshStatistics extends StatisticsEvent {
  const RefreshStatistics();
}
