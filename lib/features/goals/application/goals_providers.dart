import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/features/goals/domain/goal.dart';
import 'package:money_manager/features/goals/domain/goal_contribution.dart';
import 'package:money_manager/features/goals/data/goals_repository.dart';

final goalsStreamProvider = StreamProvider<List<Goal>>((ref) {
  final repo = ref.watch(goalsRepositoryProvider);
  return repo.watchAllGoals();
});

final goalStreamProvider = StreamProvider.family<Goal?, int>((ref, goalId) {
  final repo = ref.watch(goalsRepositoryProvider);
  return repo.watchGoal(goalId); // I need to implement watchGoal in repository! Or use watchAllGoals and filter.
});

final goalContributionsProvider = StreamProvider.family<List<GoalContribution>, int>((ref, goalId) {
  final repo = ref.watch(goalsRepositoryProvider);
  return repo.watchGoalContributions(goalId);
});

final totalContributionsForAccountProvider = StreamProvider.family<double, int>((ref, accountId) {
  final repo = ref.watch(goalsRepositoryProvider);
  return repo.watchTotalContributionsForAccount(accountId);
});

final allGoalContributionsProvider = StreamProvider<List<GoalContribution>>((ref) {
  final repo = ref.watch(goalsRepositoryProvider);
  return repo.watchAllGoalContributions();
});
