import '../entities/financial_summary.dart';
import '../../../transaction/domain/entities/transaction.dart';

abstract class StatisticsRepository {
  Future<FinancialSummary> getFinancialSummary({
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<List<Transaction>> getTransactionsInRange({
    required DateTime startDate,
    required DateTime endDate,
  });
}
