import '../entities/monthly_summary.dart';

abstract class SummaryRepository {
  Future<MonthlySummary> getMonthlySummary({
    required String userId,
    required int year,
    required int month,
  });
}
