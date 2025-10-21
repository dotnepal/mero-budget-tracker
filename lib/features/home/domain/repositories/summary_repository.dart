import '../entities/monthly_summary.dart';

abstract class SummaryRepository {
  Future<MonthlySummary> getMonthlySummary({
    required int year,
    required int month,
  });
}
