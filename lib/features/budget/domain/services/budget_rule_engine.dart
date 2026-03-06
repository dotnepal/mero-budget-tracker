abstract class BudgetRule {
  String get name;
  // Returns allocation in cents per bucket key
  Map<String, int> allocate(int totalIncome);
}

class FiftyThirtyTwenty implements BudgetRule {
  const FiftyThirtyTwenty();

  @override
  String get name => '50-30-20';

  @override
  Map<String, int> allocate(int totalIncome) {
    final needs = totalIncome * 50 ~/ 100;
    final wants = totalIncome * 30 ~/ 100;
    return {
      'NEEDS': needs,
      'WANTS': wants,
      'SAVINGS': totalIncome - needs - wants,
    };
  }
}

BudgetRule budgetRuleForType(String ruleType) {
  switch (ruleType) {
    case '50-30-20':
      return const FiftyThirtyTwenty();
    default:
      return const FiftyThirtyTwenty();
  }
}