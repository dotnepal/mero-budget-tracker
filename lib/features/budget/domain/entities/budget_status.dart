import 'package:equatable/equatable.dart';

import 'budget_plan.dart';

enum BudgetHealth { underBudget, onTrack, overBudget }

class BucketStatus extends Equatable {
  final String bucket; // 'NEEDS' | 'WANTS' | 'SAVINGS'
  final int pct;
  // All amounts in cents
  final int allocated;
  final int spent;

  const BucketStatus({
    required this.bucket,
    required this.pct,
    required this.allocated,
    required this.spent,
  });

  int get remaining => allocated - spent;

  double get percentUsed => allocated > 0 ? spent / allocated : 0.0;

  BudgetHealth get health {
    final ratio = percentUsed;
    if (ratio > 1.0) return BudgetHealth.overBudget;
    if (ratio >= 0.8) return BudgetHealth.onTrack;
    return BudgetHealth.underBudget;
  }

  @override
  List<Object?> get props => [bucket, pct, allocated, spent];
}

class BudgetStatus extends Equatable {
  final BudgetPlan plan;
  final List<BucketStatus> buckets;

  const BudgetStatus({
    required this.plan,
    required this.buckets,
  });

  BucketStatus? bucketFor(String name) {
    try {
      return buckets.firstWhere((b) => b.bucket == name);
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props => [plan, buckets];
}