import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/core/database/app_database.dart';
import 'package:money_manager/core/database/database_provider.dart';
import 'package:money_manager/features/budgets/domain/budget.dart';
import 'package:drift/drift.dart' as drift;

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository(ref.watch(databaseProvider));
});

extension BudgetDataMapper on BudgetData {
  Budget toDomain() {
    return Budget()
      ..id = id
      ..categoryId = categoryId
      ..amount = amount
      ..period = parseBudgetPeriod(period)
      ..startDate = startDate
      ..createdAt = createdAt;
  }
}

class BudgetRepository {
  final AppDatabase _db;

  BudgetRepository(this._db);

  Stream<List<Budget>> watchAllBudgets() {
    // Join with categories to get category name and color
    final query = _db.select(_db.budgets).join([
      drift.innerJoin(_db.categories, _db.categories.id.equalsExp(_db.budgets.categoryId)),
    ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        final budgetData = row.readTable(_db.budgets);
        final categoryData = row.readTable(_db.categories);
        final budget = budgetData.toDomain();
        budget.categoryName = categoryData.name;
        budget.categoryColor = categoryData.color;
        budget.categoryIconData = categoryData.iconData;
        return budget;
      }).toList();
    });
  }

  Future<void> addBudget(Budget budget) async {
    await _db.into(_db.budgets).insert(BudgetsCompanion.insert(
      categoryId: budget.categoryId,
      amount: budget.amount,
      period: drift.Value(budget.period.name),
      startDate: drift.Value(budget.startDate),
      createdAt: DateTime.now(),
    ));
  }

  Future<void> updateBudget(Budget budget) async {
    await _db.update(_db.budgets).replace(BudgetData(
      id: budget.id,
      categoryId: budget.categoryId,
      amount: budget.amount,
      period: budget.period.name,
      startDate: budget.startDate,
      createdAt: budget.createdAt,
    ));
  }

  Future<void> deleteBudget(int id) async {
    await (_db.delete(_db.budgets)..where((b) => b.id.equals(id))).go();
  }

  Future<Budget?> getBudget(int id) async {
    final query = _db.select(_db.budgets).join([
      drift.innerJoin(_db.categories, _db.categories.id.equalsExp(_db.budgets.categoryId)),
    ])..where(_db.budgets.id.equals(id));

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final budgetData = row.readTable(_db.budgets);
    final categoryData = row.readTable(_db.categories);
    final budget = budgetData.toDomain();
    budget.categoryName = categoryData.name;
    budget.categoryColor = categoryData.color;
    budget.categoryIconData = categoryData.iconData;
    return budget;
  }
}
