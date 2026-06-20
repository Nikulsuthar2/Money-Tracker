import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/features/expenses/domain/expense.dart';
import 'package:money_manager/core/database/database_provider.dart';
import 'package:money_manager/core/database/app_database.dart';
import 'package:drift/drift.dart' as drift;

final expensesRepositoryProvider = Provider<ExpensesRepository>((ref) {
  return ExpensesRepository(ref.watch(databaseProvider));
});

extension ExpenseDataMapper on ExpenseData {
  Expense toDomain() {
    return Expense()
      ..id = id
      ..transactionId = transactionId
      ..totalAmount = totalAmount
      ..categoryId = categoryId
      ..note = note
      ..date = date
      ..createdAt = createdAt;
  }
}

extension ExpenseSplitDataMapper on ExpenseSplitData {
  ExpenseSplit toDomain() {
    return ExpenseSplit()
      ..id = id
      ..expenseId = expenseId
      ..personId = personId
      ..amount = amount;
  }
}

extension SettlementDataMapper on SettlementData {
  Settlement toDomain() {
    return Settlement()
      ..id = id
      ..transactionId = transactionId
      ..fromPersonId = fromPersonId
      ..toPersonId = toPersonId
      ..amount = amount
      ..createdAt = createdAt;
  }
}

class ExpensesRepository {
  final AppDatabase _db;

  ExpensesRepository(this._db);

  // Expense Methods
  Future<int> addExpense(Expense expense) async {
    return await _db.into(_db.expenses).insert(ExpensesCompanion.insert(
      transactionId: drift.Value(expense.transactionId),
      totalAmount: expense.totalAmount,
      categoryId: drift.Value(expense.categoryId),
      note: drift.Value(expense.note),
      date: expense.date,
      createdAt: DateTime.now(),
    ));
  }

  // ExpenseSplit Methods
  Future<void> addExpenseSplits(List<ExpenseSplit> splits) async {
    await _db.batch((batch) {
      batch.insertAll(_db.expenseSplits, splits.map((s) => ExpenseSplitsCompanion.insert(
        expenseId: s.expenseId,
        personId: s.personId,
        amount: s.amount,
      )));
    });
  }

  // Settlement Methods
  Future<void> addSettlement(Settlement settlement) async {
    await _db.into(_db.settlements).insert(SettlementsCompanion.insert(
      transactionId: settlement.transactionId,
      fromPersonId: settlement.fromPersonId,
      toPersonId: settlement.toPersonId,
      amount: settlement.amount,
      createdAt: DateTime.now(),
    ));
  }
  
  // Queries
  Future<List<ExpenseSplit>> getSplitsForPerson(int personId) async {
    final list = await (_db.select(_db.expenseSplits)..where((s) => s.personId.equals(personId))).get();
    return list.map((e) => e.toDomain()).toList();
  }
  
  Future<List<Settlement>> getSettlementsForPerson(int personId) async {
    final list = await (_db.select(_db.settlements)
      ..where((s) => s.fromPersonId.equals(personId) | s.toPersonId.equals(personId))).get();
    return list.map((e) => e.toDomain()).toList();
  }
}
