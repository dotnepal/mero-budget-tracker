import 'package:equatable/equatable.dart';

// syncStatus values
const int syncStatusSynced = 0;
const int syncStatusPending = 1;
const int syncStatusConflict = 2;

class BudgetPlan extends Equatable {
  final String id;
  final String name;
  final int periodMonth;
  final int periodYear;
  // Total income stored in cents (e.g., $5,800 = 580000)
  final int totalIncome;
  final String ruleType;
  final int needsPct;
  final int wantsPct;
  final int savingsPct;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String hlcTimestamp;
  final bool isDeleted;
  final int syncStatus;

  const BudgetPlan({
    required this.id,
    required this.name,
    required this.periodMonth,
    required this.periodYear,
    required this.totalIncome,
    this.ruleType = '50-30-20',
    this.needsPct = 50,
    this.wantsPct = 30,
    this.savingsPct = 20,
    required this.createdAt,
    required this.updatedAt,
    this.hlcTimestamp = '',
    this.isDeleted = false,
    this.syncStatus = syncStatusPending,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        periodMonth,
        periodYear,
        totalIncome,
        ruleType,
        needsPct,
        wantsPct,
        savingsPct,
        createdAt,
        updatedAt,
        hlcTimestamp,
        isDeleted,
        syncStatus,
      ];

  BudgetPlan copyWith({
    String? id,
    String? name,
    int? periodMonth,
    int? periodYear,
    int? totalIncome,
    String? ruleType,
    int? needsPct,
    int? wantsPct,
    int? savingsPct,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? hlcTimestamp,
    bool? isDeleted,
    int? syncStatus,
  }) {
    return BudgetPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      periodMonth: periodMonth ?? this.periodMonth,
      periodYear: periodYear ?? this.periodYear,
      totalIncome: totalIncome ?? this.totalIncome,
      ruleType: ruleType ?? this.ruleType,
      needsPct: needsPct ?? this.needsPct,
      wantsPct: wantsPct ?? this.wantsPct,
      savingsPct: savingsPct ?? this.savingsPct,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      hlcTimestamp: hlcTimestamp ?? this.hlcTimestamp,
      isDeleted: isDeleted ?? this.isDeleted,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}