import '../../domain/entities/monthly_summary.dart';
import '../../domain/repositories/summary_repository.dart';
import '../../../transaction/domain/repositories/transaction_repository.dart';
import '../../../transaction/domain/entities/transaction.dart';

class SummaryRepositoryImpl implements SummaryRepository {
  final TransactionRepository transactionRepository;

  const SummaryRepositoryImpl({
    required this.transactionRepository,
  });

  @override
  Future<MonthlySummary> getMonthlySummary({
    required int year,
    required int month,
  }) async {
    // Use existing getTransactionsInRange method
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);

    final transactions = await transactionRepository.getTransactionsInRange(
      startDate: startDate,
      endDate: endDate,
    );

    double totalIncome = 0;
    double totalExpenses = 0;
    int incomeTransactionCount = 0;
    int expenseTransactionCount = 0;

    for (final transaction in transactions) {
      if (transaction.type == TransactionType.income) {
        totalIncome += transaction.amount;
        incomeTransactionCount++;
      } else {
        totalExpenses += transaction.amount;
        expenseTransactionCount++;
      }
    }

    return MonthlySummary(
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      netBalance: totalIncome - totalExpenses,
      month: startDate,
      transactionCount: transactions.length,
      incomeTransactionCount: incomeTransactionCount,
      expenseTransactionCount: expenseTransactionCount,
    );
  }
}
