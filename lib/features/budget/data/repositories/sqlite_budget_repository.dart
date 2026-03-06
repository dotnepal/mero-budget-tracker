import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../../domain/entities/budget_plan.dart';
import '../../domain/repositories/budget_repository.dart';

class SqliteBudgetRepository implements BudgetRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  @override
  Future<BudgetPlan?> getPlanForPeriod(int month, int year) async {
    final db = await _db.database;
    final rows = await db.query(
      DatabaseHelper.tableBudgetPlans,
      where: '${DatabaseHelper.columnPeriodMonth} = ? '
          'AND ${DatabaseHelper.columnPeriodYear} = ? '
          'AND ${DatabaseHelper.columnIsDeleted} = 0',
      whereArgs: [month, year],
      orderBy: '${DatabaseHelper.columnUpdatedAt} DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _mapToPlan(rows.first);
  }

  @override
  Future<List<BudgetPlan>> getAllPlans() async {
    final db = await _db.database;
    final rows = await db.query(
      DatabaseHelper.tableBudgetPlans,
      where: '${DatabaseHelper.columnIsDeleted} = 0',
      orderBy: '${DatabaseHelper.columnPeriodYear} DESC, ${DatabaseHelper.columnPeriodMonth} DESC',
    );
    return rows.map(_mapToPlan).toList();
  }

  @override
  Future<BudgetPlan> insertPlan(BudgetPlan plan) async {
    final db = await _db.database;
    final now = DateTime.now();
    final id = 'budget_${now.millisecondsSinceEpoch}_${_rand(6)}';
    final withId = plan.copyWith(
      id: id,
      createdAt: now,
      updatedAt: now,
      syncStatus: syncStatusPending,
    );
    await db.insert(
      DatabaseHelper.tableBudgetPlans,
      _planToMap(withId),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return withId;
  }

  @override
  Future<BudgetPlan> updatePlan(BudgetPlan plan) async {
    final db = await _db.database;
    final updated = plan.copyWith(
      updatedAt: DateTime.now(),
      syncStatus: syncStatusPending,
    );
    await db.update(
      DatabaseHelper.tableBudgetPlans,
      _planToMap(updated),
      where: '${DatabaseHelper.columnId} = ?',
      whereArgs: [plan.id],
    );
    return updated;
  }

  @override
  Future<void> deletePlan(String id) async {
    final db = await _db.database;
    await db.update(
      DatabaseHelper.tableBudgetPlans,
      {
        DatabaseHelper.columnIsDeleted: 1,
        DatabaseHelper.columnSyncStatus: syncStatusPending,
        DatabaseHelper.columnUpdatedAt: DateTime.now().millisecondsSinceEpoch,
      },
      where: '${DatabaseHelper.columnId} = ?',
      whereArgs: [id],
    );
  }

  BudgetPlan _mapToPlan(Map<String, dynamic> m) {
    return BudgetPlan(
      id: m[DatabaseHelper.columnId] as String,
      name: m[DatabaseHelper.columnBudgetPlanName] as String,
      periodMonth: m[DatabaseHelper.columnPeriodMonth] as int,
      periodYear: m[DatabaseHelper.columnPeriodYear] as int,
      totalIncome: m[DatabaseHelper.columnTotalIncome] as int,
      ruleType: m[DatabaseHelper.columnRuleType] as String? ?? '50-30-20',
      needsPct: m[DatabaseHelper.columnNeedsPct] as int? ?? 50,
      wantsPct: m[DatabaseHelper.columnWantsPct] as int? ?? 30,
      savingsPct: m[DatabaseHelper.columnSavingsPct] as int? ?? 20,
      createdAt: DateTime.fromMillisecondsSinceEpoch(m[DatabaseHelper.columnCreatedAt] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(m[DatabaseHelper.columnUpdatedAt] as int),
      hlcTimestamp: m[DatabaseHelper.columnHlcTimestamp] as String? ?? '',
      isDeleted: (m[DatabaseHelper.columnIsDeleted] as int? ?? 0) == 1,
      syncStatus: m[DatabaseHelper.columnSyncStatus] as int? ?? syncStatusPending,
    );
  }

  Map<String, dynamic> _planToMap(BudgetPlan p) {
    return {
      DatabaseHelper.columnId: p.id,
      DatabaseHelper.columnBudgetPlanName: p.name,
      DatabaseHelper.columnPeriodMonth: p.periodMonth,
      DatabaseHelper.columnPeriodYear: p.periodYear,
      DatabaseHelper.columnTotalIncome: p.totalIncome,
      DatabaseHelper.columnRuleType: p.ruleType,
      DatabaseHelper.columnNeedsPct: p.needsPct,
      DatabaseHelper.columnWantsPct: p.wantsPct,
      DatabaseHelper.columnSavingsPct: p.savingsPct,
      DatabaseHelper.columnCreatedAt: p.createdAt.millisecondsSinceEpoch,
      DatabaseHelper.columnUpdatedAt: p.updatedAt.millisecondsSinceEpoch,
      DatabaseHelper.columnHlcTimestamp: p.hlcTimestamp,
      DatabaseHelper.columnIsDeleted: p.isDeleted ? 1 : 0,
      DatabaseHelper.columnSyncStatus: p.syncStatus,
    };
  }

  String _rand(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    int seed = DateTime.now().millisecondsSinceEpoch;
    String result = '';
    for (int i = 0; i < length; i++) {
      seed = (seed * 1103515245 + 12345) % (1 << 32);
      result += chars[seed % chars.length];
    }
    return result;
  }
}