import '../entities/financial_summary.dart';
import '../../../transaction/domain/entities/transaction.dart';

abstract class StatisticsRepository {
  Future<FinancialSummary> getFinancialSummary({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<List<Transaction>> getTransactionsInRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  });
}
