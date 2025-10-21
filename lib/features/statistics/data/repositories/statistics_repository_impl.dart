import '../../domain/entities/financial_summary.dart';
import '../../domain/repositories/statistics_repository.dart';
import '../../../transaction/domain/entities/transaction.dart';
import '../../../transaction/domain/repositories/transaction_repository.dart';

class StatisticsRepositoryImpl implements StatisticsRepository {
  final TransactionRepository transactionRepository;

  const StatisticsRepositoryImpl({
    required this.transactionRepository,
  });

  @override
  Future<List<Transaction>> getTransactionsInRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return await transactionRepository.getTransactionsInRange(
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<FinancialSummary> getFinancialSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final transactions = await transactionRepository.getTransactionsInRange(
      startDate: startDate,
      endDate: endDate,
    );

    double totalIncome = 0;
    double totalExpenses = 0;

    for (final transaction in transactions) {
      if (transaction.type == TransactionType.income) {
        totalIncome += transaction.amount;
      } else {
        totalExpenses += transaction.amount;
      }
    }

    return FinancialSummary(
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      netBalance: totalIncome - totalExpenses,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
