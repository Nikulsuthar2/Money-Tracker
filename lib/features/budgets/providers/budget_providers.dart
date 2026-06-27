import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/core/database/app_database.dart';
import 'package:money_manager/core/database/database_provider.dart';
import 'package:money_manager/features/budgets/data/budget_repository.dart';
import 'package:money_manager/features/budgets/domain/budget.dart';
import 'package:money_manager/features/analytics/application/analytics_transactions_provider.dart';
import 'package:money_manager/features/transactions/domain/transaction.dart';
import 'package:money_manager/features/budgets/domain/budget_allocation.dart';
import 'package:money_manager/features/budgets/data/budget_allocation_repository.dart';
import 'package:drift/drift.dart' as drift;

final budgetsProvider = StreamProvider<List<Budget>>((ref) {
  return ref.watch(budgetRepositoryProvider).watchAllBudgets();
});

class BudgetWithConsumption {
  final Budget budget;
  final double spent;

  BudgetWithConsumption(this.budget, this.spent);

  double get progress => amountLimit > 0 ? spent / amountLimit : 0;
  double get amountLimit => budget.amount;
  bool get isExceeded => spent > amountLimit;
}

String getPeriodKey(BudgetPeriod period, DateTime date) {
  switch (period) {
    case BudgetPeriod.weekly:
      final diff = date.weekday - DateTime.monday;
      final start = date.subtract(Duration(days: diff));
      return '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
    case BudgetPeriod.monthly:
      return '${date.year}-${date.month.toString().padLeft(2, '0')}';
    case BudgetPeriod.yearly:
      return '${date.year}';
  }
}

final budgetPeriodFilterProvider = StateProvider<BudgetPeriod>((ref) => BudgetPeriod.monthly);
final budgetSelectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final currentBudgetAllocationProvider = StreamProvider<BudgetAllocation?>((ref) {
  final period = ref.watch(budgetPeriodFilterProvider);
  final date = ref.watch(budgetSelectedDateProvider);
  final key = getPeriodKey(period, date);
  return ref.watch(budgetAllocationRepositoryProvider).watchAllocation(period, key);
});

final budgetsWithConsumptionProvider = StreamProvider<List<BudgetWithConsumption>>((ref) async* {
  final budgetsAsync = ref.watch(budgetsProvider);
  final selectedDate = ref.watch(budgetSelectedDateProvider);
  final selectedPeriod = ref.watch(budgetPeriodFilterProvider);
  final txAsync = ref.watch(analyticsTransactionsProvider);
  
  if (budgetsAsync.hasValue && txAsync.hasValue) {
    final allBudgets = budgetsAsync.value!;
    final transactions = txAsync.value!;
    
    // Filter budgets by the selected period tab
    final budgets = allBudgets.where((b) => b.period == selectedPeriod).toList();
    
    // We calculate the start and end of the current period based on selectedDate
    final now = selectedDate;

    List<BudgetWithConsumption> results = [];

    for (final budget in budgets) {
      DateTime startDate;
      DateTime endDate;

      switch (budget.period) {
        case BudgetPeriod.weekly:
          // Start of the week (Monday)
          final diff = now.weekday - DateTime.monday;
          startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: diff));
          endDate = startDate.add(const Duration(days: 7));
          break;
        case BudgetPeriod.monthly:
          startDate = DateTime(now.year, now.month, 1);
          endDate = DateTime(now.year, now.month + 1, 1);
          break;
        case BudgetPeriod.yearly:
          startDate = DateTime(now.year, 1, 1);
          endDate = DateTime(now.year + 1, 1, 1);
          break;
      }

      double spent = 0.0;
      for (final t in transactions) {
        if (t.categoryId == budget.categoryId && t.type == TransactionType.expense) {
          if (t.date.isAfter(startDate.subtract(const Duration(milliseconds: 1))) && t.date.isBefore(endDate)) {
            spent += t.amount;
          }
        }
      }

      results.add(BudgetWithConsumption(budget, spent));
    }

    yield results;
  } else {
    yield [];
  }
});

class BudgetSummary {
  final double income;
  final double assigned;
  double get toAssign => income - assigned;

  BudgetSummary({required this.income, required this.assigned});
}

final budgetSummaryProvider = Provider<BudgetSummary>((ref) {
  final budgetsWithConsAsync = ref.watch(budgetsWithConsumptionProvider);
  final allocationAsync = ref.watch(currentBudgetAllocationProvider);

  if (!budgetsWithConsAsync.hasValue) {
    return BudgetSummary(income: 0, assigned: 0);
  }

  final budgets = budgetsWithConsAsync.value!;
  
  double totalIncome = 0;
  if (allocationAsync.hasValue && allocationAsync.value != null) {
    totalIncome = allocationAsync.value!.amount;
  }

  double totalAssigned = 0;
  for (final b in budgets) {
    totalAssigned += b.amountLimit;
  }

  return BudgetSummary(income: totalIncome, assigned: totalAssigned);
});

final budgetTransactionsProvider = StreamProvider.family<List<Transaction>, int>((ref, budgetId) async* {
  final selectedDate = ref.watch(budgetSelectedDateProvider);
  final budgetRepo = ref.watch(budgetRepositoryProvider);
  final txAsync = ref.watch(analyticsTransactionsProvider);
  
  if (!txAsync.hasValue) {
    yield [];
    return;
  }

  final budget = await budgetRepo.getBudget(budgetId);
  if (budget == null) {
    yield [];
    return;
  }

  DateTime startDate;
  DateTime endDate;
  final now = selectedDate;

  switch (budget.period) {
    case BudgetPeriod.weekly:
      final diff = now.weekday - DateTime.monday;
      startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: diff));
      endDate = startDate.add(const Duration(days: 7));
      break;
    case BudgetPeriod.monthly:
      startDate = DateTime(now.year, now.month, 1);
      endDate = DateTime(now.year, now.month + 1, 1);
      break;
    case BudgetPeriod.yearly:
      startDate = DateTime(now.year, 1, 1);
      endDate = DateTime(now.year + 1, 1, 1);
      break;
  }

  final filtered = txAsync.value!.where((t) {
    return t.categoryId == budget.categoryId &&
           t.type == TransactionType.expense &&
           t.date.isAfter(startDate.subtract(const Duration(milliseconds: 1))) &&
           t.date.isBefore(endDate);
  }).toList();
  
  filtered.sort((a, b) => b.date.compareTo(a.date));

  yield filtered;
});
