import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/core/database/app_database.dart';
import 'package:money_manager/core/database/database_provider.dart';
import 'package:money_manager/features/budgets/domain/budget.dart';
import 'package:money_manager/features/budgets/domain/budget_allocation.dart';
import 'package:drift/drift.dart';

final budgetAllocationRepositoryProvider = Provider((ref) {
  return BudgetAllocationRepository(ref.watch(databaseProvider));
});

class BudgetAllocationRepository {
  final AppDatabase _db;

  BudgetAllocationRepository(this._db);

  BudgetAllocation _mapFromDb(BudgetAllocationData data) {
    return BudgetAllocation()
      ..id = data.id
      ..periodType = BudgetPeriod.values.firstWhere((e) => e.name == data.periodType, orElse: () => BudgetPeriod.monthly)
      ..periodKey = data.periodKey
      ..amount = data.amount;
  }

  Future<BudgetAllocation?> getAllocation(BudgetPeriod type, String periodKey) async {
    final query = _db.select(_db.budgetAllocations)..where((tbl) => tbl.periodType.equals(type.name) & tbl.periodKey.equals(periodKey));
    final result = await query.getSingleOrNull();
    return result != null ? _mapFromDb(result) : null;
  }

  Stream<BudgetAllocation?> watchAllocation(BudgetPeriod type, String periodKey) {
    final query = _db.select(_db.budgetAllocations)..where((tbl) => tbl.periodType.equals(type.name) & tbl.periodKey.equals(periodKey));
    return query.watchSingleOrNull().map((result) => result != null ? _mapFromDb(result) : null);
  }

  Future<void> saveAllocation(BudgetPeriod type, String periodKey, double amount) async {
    final existing = await getAllocation(type, periodKey);
    if (existing != null) {
      await _db.update(_db.budgetAllocations).replace(
        BudgetAllocationData(
          id: existing.id,
          periodType: type.name,
          periodKey: periodKey,
          amount: amount,
        ),
      );
    } else {
      await _db.into(_db.budgetAllocations).insert(
        BudgetAllocationsCompanion.insert(
          periodType: type.name,
          periodKey: periodKey,
          amount: amount,
        ),
      );
    }
  }
}
