import '../entities/budget_plan.dart';

abstract class BudgetRepository {
  Future<BudgetPlan?> getPlanForPeriod(int month, int year);
  Future<List<BudgetPlan>> getAllPlans();
  Future<BudgetPlan> insertPlan(BudgetPlan plan);
  Future<BudgetPlan> updatePlan(BudgetPlan plan);
  Future<void> deletePlan(String id);
}