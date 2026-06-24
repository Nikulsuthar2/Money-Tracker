import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/features/goals/domain/goal.dart';
import 'package:money_manager/features/goals/domain/goal_contribution.dart';
import 'package:money_manager/core/database/database_provider.dart';
import 'package:money_manager/core/database/app_database.dart';

final goalsRepositoryProvider = Provider<GoalsRepository>((ref) {
  return GoalsRepository(ref.watch(databaseProvider));
});

extension GoalDataMapper on GoalData {
  Goal toDomain() {
    return Goal()
      ..id = id
      ..type = GoalType.values.firstWhere((e) => e.name == type)
      ..name = name
      ..iconData = iconData
      ..color = color
      ..targetAmount = targetAmount
      ..currentAmount = currentAmount
      ..startDate = startDate
      ..endDate = endDate
      ..frequency = frequency
      ..totalDebt = totalDebt
      ..remainingBalance = remainingBalance
      ..interestRate = interestRate
      ..minimumPayment = minimumPayment
      ..createdAt = createdAt
      ..updatedAt = updatedAt;
  }
}

extension GoalContributionDataMapper on GoalContributionData {
  GoalContribution toDomain() {
    return GoalContribution()
      ..id = id
      ..goalId = goalId
      ..accountId = accountId
      ..amount = amount
      ..date = date
      ..note = note;
  }
}

class GoalsRepository {
  final AppDatabase _db;

  GoalsRepository(this._db);

  Stream<List<Goal>> watchAllGoals() {
    return _db.select(_db.goals).watch().map((list) => list.map((e) => e.toDomain()).toList());
  }

  Future<Goal?> getGoal(int id) async {
    final data = await (_db.select(_db.goals)..where((g) => g.id.equals(id))).getSingleOrNull();
    return data?.toDomain();
  }

  Stream<Goal?> watchGoal(int id) {
    return (_db.select(_db.goals)..where((g) => g.id.equals(id)))
        .watchSingleOrNull()
        .map((data) => data?.toDomain());
  }

  Future<void> addGoal(Goal goal) async {
    await _db.into(_db.goals).insert(GoalsCompanion.insert(
      type: goal.type.name,
      name: goal.name,
      iconData: goal.iconData,
      color: goal.color,
      targetAmount: goal.targetAmount,
      currentAmount: drift.Value(goal.currentAmount),
      startDate: drift.Value(goal.startDate),
      endDate: drift.Value(goal.endDate),
      frequency: drift.Value(goal.frequency),
      totalDebt: drift.Value(goal.totalDebt),
      remainingBalance: drift.Value(goal.remainingBalance),
      interestRate: drift.Value(goal.interestRate),
      minimumPayment: drift.Value(goal.minimumPayment),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  }

  Future<void> updateGoal(Goal goal) async {
    await _db.update(_db.goals).replace(GoalData(
      id: goal.id,
      type: goal.type.name,
      name: goal.name,
      iconData: goal.iconData,
      color: goal.color,
      targetAmount: goal.targetAmount,
      currentAmount: goal.currentAmount,
      startDate: goal.startDate,
      endDate: goal.endDate,
      frequency: goal.frequency,
      totalDebt: goal.totalDebt,
      remainingBalance: goal.remainingBalance,
      interestRate: goal.interestRate,
      minimumPayment: goal.minimumPayment,
      createdAt: goal.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  }

  Future<void> deleteGoal(int id) async {
    await (_db.delete(_db.goals)..where((g) => g.id.equals(id))).go();
    await (_db.delete(_db.goalContributions)..where((c) => c.goalId.equals(id))).go();
  }

  // --- Contributions ---

  Stream<List<GoalContribution>> watchGoalContributions(int goalId) {
    return (_db.select(_db.goalContributions)
          ..where((c) => c.goalId.equals(goalId))
          ..orderBy([(c) => drift.OrderingTerm.desc(c.date)]))
        .watch()
        .map((list) => list.map((e) => e.toDomain()).toList());
  }

  Stream<List<GoalContribution>> watchAllGoalContributions() {
    return _db.select(_db.goalContributions).watch().map((list) => list.map((e) => e.toDomain()).toList());
  }

  Future<void> addContribution(GoalContribution contribution) async {
    await _db.transaction(() async {
      await _db.into(_db.goalContributions).insert(GoalContributionsCompanion.insert(
        goalId: contribution.goalId,
        accountId: contribution.accountId,
        amount: contribution.amount,
        date: contribution.date,
        note: drift.Value(contribution.note),
      ));
      
      // Update the goal's cached currentAmount
      final goalData = await (_db.select(_db.goals)..where((g) => g.id.equals(contribution.goalId))).getSingleOrNull();
      if (goalData != null) {
        final updatedAmount = goalData.currentAmount + contribution.amount;
        await _db.update(_db.goals).replace(goalData.copyWith(currentAmount: updatedAmount, updatedAt: DateTime.now()));
      }
    });
  }

  Future<void> deleteContribution(GoalContribution contribution) async {
    await _db.transaction(() async {
      await (_db.delete(_db.goalContributions)..where((c) => c.id.equals(contribution.id))).go();
      
      final goalData = await (_db.select(_db.goals)..where((g) => g.id.equals(contribution.goalId))).getSingleOrNull();
      if (goalData != null) {
        final updatedAmount = goalData.currentAmount - contribution.amount;
        await _db.update(_db.goals).replace(goalData.copyWith(currentAmount: updatedAmount, updatedAt: DateTime.now()));
      }
    });
  }

  Future<double> getTotalContributionsForAccount(int accountId) async {
    final list = await (_db.select(_db.goalContributions)..where((c) => c.accountId.equals(accountId))).get();
    return list.fold<double>(0.0, (sum, c) => sum + c.amount);
  }
  
  Stream<double> watchTotalContributionsForAccount(int accountId) {
    return (_db.select(_db.goalContributions)..where((c) => c.accountId.equals(accountId)))
        .watch()
        .map((list) => list.fold<double>(0.0, (sum, c) => sum + c.amount));
  }
  
  Future<void> recalculateGoalAmounts() async {
    final goals = await _db.select(_db.goals).get();
    for (var g in goals) {
      final contributions = await (_db.select(_db.goalContributions)..where((c) => c.goalId.equals(g.id))).get();
      final total = contributions.fold<double>(0.0, (sum, c) => sum + c.amount);
      if (g.currentAmount != total) {
         await _db.update(_db.goals).replace(g.copyWith(currentAmount: total, updatedAt: DateTime.now()));
      }
    }
  }
}
