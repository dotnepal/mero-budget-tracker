import '../../../../core/database/database_helper.dart';
import '../../domain/entities/budget_plan.dart';
import '../../domain/entities/budget_status.dart';
import '../../domain/services/budget_rule_engine.dart';
import '../repositories/sqlite_budget_repository.dart';

class BudgetService {
  final SqliteBudgetRepository _repo;
  final DatabaseHelper _db = DatabaseHelper.instance;

  BudgetService(this._repo);

  /// Returns [BudgetStatus] for the given month/year, or null if no plan exists.
  Future<BudgetStatus?> getStatusForPeriod(int month, int year) async {
    final plan = await _repo.getPlanForPeriod(month, year);
    if (plan == null) return null;

    final startMs = DateTime(year, month).millisecondsSinceEpoch;
    final endMs = DateTime(year, month + 1, 0, 23, 59, 59, 999).millisecondsSinceEpoch;

    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT c.${DatabaseHelper.columnBudgetBucket} AS bucket,
             SUM(t.${DatabaseHelper.columnAmount}) AS total
      FROM ${DatabaseHelper.tableTransactions} t
      JOIN ${DatabaseHelper.tableCategories} c
        ON t.${DatabaseHelper.columnCategoryId} = c.${DatabaseHelper.columnId}
      WHERE t.${DatabaseHelper.columnType} = 'expense'
        AND t.${DatabaseHelper.columnDate} >= ?
        AND t.${DatabaseHelper.columnDate} <= ?
        AND c.${DatabaseHelper.columnBudgetBucket} IS NOT NULL
      GROUP BY c.${DatabaseHelper.columnBudgetBucket}
    ''', [startMs, endMs]);

    // Map bucket -> spent cents
    final spentMap = <String, int>{};
    for (final row in rows) {
      final bucket = row['bucket'] as String;
      final total = row['total'];
      // transactions store amounts as REAL (dollars); convert to cents
      final spentCents = ((total as num? ?? 0.0) * 100).round();
      spentMap[bucket] = spentCents;
    }

    final rule = budgetRuleForType(plan.ruleType);
    final allocations = rule.allocate(plan.totalIncome);

    const bucketOrder = ['NEEDS', 'WANTS', 'SAVINGS'];
    final bucketPcts = {
      'NEEDS': plan.needsPct,
      'WANTS': plan.wantsPct,
      'SAVINGS': plan.savingsPct,
    };

    final buckets = bucketOrder.map((bucket) {
      return BucketStatus(
        bucket: bucket,
        pct: bucketPcts[bucket]!,
        allocated: allocations[bucket]!,
        spent: spentMap[bucket] ?? 0,
      );
    }).toList();

    return BudgetStatus(plan: plan, buckets: buckets);
  }

  /// Creates or updates the budget plan for the given period (upsert).
  /// If a plan already exists for that month/year it is updated in place.
  Future<BudgetPlan> createPlan({
    required int totalIncomeCents,
    required int month,
    required int year,
    String ruleType = '50-30-20',
  }) async {
    final rule = budgetRuleForType(ruleType);
    final pcts = _pctsForRule(rule);
    final now = DateTime.now();

    final existing = await _repo.getPlanForPeriod(month, year);
    if (existing != null) {
      final updated = existing.copyWith(
        totalIncome: totalIncomeCents,
        ruleType: ruleType,
        needsPct: pcts['NEEDS'],
        wantsPct: pcts['WANTS'],
        savingsPct: pcts['SAVINGS'],
        updatedAt: now,
      );
      return _repo.updatePlan(updated);
    }

    final plan = BudgetPlan(
      id: '',
      name: _periodName(month, year),
      periodMonth: month,
      periodYear: year,
      totalIncome: totalIncomeCents,
      ruleType: ruleType,
      needsPct: pcts['NEEDS']!,
      wantsPct: pcts['WANTS']!,
      savingsPct: pcts['SAVINGS']!,
      createdAt: now,
      updatedAt: now,
    );

    return _repo.insertPlan(plan);
  }

  Map<String, int> _pctsForRule(BudgetRule rule) {
    // Derive percentages from allocation against a known income
    // For built-in rules we can hard-code; for extensibility use the rule name.
    if (rule is FiftyThirtyTwenty) {
      return {'NEEDS': 50, 'WANTS': 30, 'SAVINGS': 20};
    }
    return {'NEEDS': 50, 'WANTS': 30, 'SAVINGS': 20};
  }

  String _periodName(int month, int year) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[month]} $year';
  }
}