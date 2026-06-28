import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/features/expenses/domain/expense.dart';
import 'package:money_manager/core/database/database_provider.dart';
import 'package:money_manager/core/database/app_database.dart';
import 'package:drift/drift.dart' as drift;

final expensesRepositoryProvider = Provider<ExpensesRepository>((ref) {
  return ExpensesRepository(ref.watch(databaseProvider));
});

final expensesStreamProvider = StreamProvider<List<Expense>>((ref) {
  return ref.watch(expensesRepositoryProvider).watchAllExpenses();
});

final expenseSplitsStreamProvider = StreamProvider<List<ExpenseSplit>>((ref) {
  return ref.watch(expensesRepositoryProvider).watchAllExpenseSplits();
});

extension ExpenseDataMapper on ExpenseData {
  Expense toDomain() {
    return Expense()
      ..id = id
      ..transactionId = transactionId
      ..paidByPersonId = paidByPersonId
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
      paidByPersonId: drift.Value(expense.paidByPersonId),
      totalAmount: expense.totalAmount,
      categoryId: drift.Value(expense.categoryId),
      note: drift.Value(expense.note),
      date: expense.date,
      createdAt: DateTime.now(),
    ));
  }

  Future<void> deleteExpense(int expenseId) async {
    await _db.transaction(() async {
      await (_db.delete(_db.expenseSplits)..where((s) => s.expenseId.equals(expenseId))).go();
      await (_db.delete(_db.expenses)..where((e) => e.id.equals(expenseId))).go();
    });
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

  Future<void> updateSettlement(Settlement settlement) async {
    await _db.update(_db.settlements).replace(SettlementData(
      id: settlement.id,
      transactionId: settlement.transactionId,
      fromPersonId: settlement.fromPersonId,
      toPersonId: settlement.toPersonId,
      amount: settlement.amount,
      createdAt: settlement.createdAt ?? DateTime.now(),
    ));
  }
  
  // Queries
  // Queries
  Stream<List<Expense>> watchAllExpenses() {
    return (_db.select(_db.expenses)..orderBy([(t) => drift.OrderingTerm.desc(t.date)])).watch().map((list) => list.map((e) => e.toDomain()).toList());
  }

  Stream<List<ExpenseSplit>> watchAllExpenseSplits() {
    return _db.select(_db.expenseSplits).watch().map((list) => list.map((e) => e.toDomain()).toList());
  }

  Stream<List<Settlement>> watchAllSettlements() {
    return (_db.select(_db.settlements)..orderBy([(t) => drift.OrderingTerm.desc(t.createdAt)])).watch().map((list) => list.map((e) => e.toDomain()).toList());
  }

  Future<List<Expense>> getAllExpenses() async {
    final list = await _db.select(_db.expenses).get();
    return list.map((e) => e.toDomain()).toList();
  }

  Future<List<ExpenseSplit>> getAllExpenseSplits() async {
    final list = await _db.select(_db.expenseSplits).get();
    return list.map((e) => e.toDomain()).toList();
  }

  Future<List<Expense>> getExpensesForTransaction(int transactionId) async {
    final list = await (_db.select(_db.expenses)..where((e) => e.transactionId.equals(transactionId))).get();
    return list.map((e) => e.toDomain()).toList();
  }

  Future<List<ExpenseSplit>> getSplitsForExpense(int expenseId) async {
    final list = await (_db.select(_db.expenseSplits)..where((s) => s.expenseId.equals(expenseId))).get();
    return list.map((e) => e.toDomain()).toList();
  }

  Future<List<ExpenseSplit>> getSplitsForPerson(int personId) async {
    final list = await (_db.select(_db.expenseSplits)..where((s) => s.personId.equals(personId))).get();
    return list.map((e) => e.toDomain()).toList();
  }
  
  Future<List<Settlement>> getSettlementsForPerson(int personId) async {
    final list = await (_db.select(_db.settlements)
      ..where((s) => s.fromPersonId.equals(personId) | s.toPersonId.equals(personId))).get();
    return list.map((e) => e.toDomain()).toList();
  }

  Future<List<Settlement>> getSettlementsForTransaction(int transactionId) async {
    final list = await (_db.select(_db.settlements)
      ..where((s) => s.transactionId.equals(transactionId))).get();
    return list.map((e) => e.toDomain()).toList();
  }

  Future<double> getPersonBalance(int personId) async {
    final owesMeSplits = await (_db.select(_db.expenseSplits).join([
      drift.innerJoin(_db.expenses, _db.expenses.id.equalsExp(_db.expenseSplits.expenseId))
    ])..where(_db.expenseSplits.personId.equals(personId) & _db.expenses.paidByPersonId.equals(0))).get();
    
    double owedToMe = owesMeSplits.fold(0.0, (sum, row) => sum + row.readTable(_db.expenseSplits).amount);
    
    final iOweSplits = await (_db.select(_db.expenseSplits).join([
      drift.innerJoin(_db.expenses, _db.expenses.id.equalsExp(_db.expenseSplits.expenseId))
    ])..where(_db.expenseSplits.personId.equals(0) & _db.expenses.paidByPersonId.equals(personId))).get();
    
    double iOwe = iOweSplits.fold(0.0, (sum, row) => sum + row.readTable(_db.expenseSplits).amount);
    
    final settlements = await getSettlementsForPerson(personId);
    double settlementsToMe = settlements.where((s) => s.toPersonId == 0 && s.fromPersonId == personId).fold(0.0, (sum, s) => sum + s.amount);
    double settlementsByMe = settlements.where((s) => s.fromPersonId == 0 && s.toPersonId == personId).fold(0.0, (sum, s) => sum + s.amount);
    
    return (owedToMe - settlementsToMe) - (iOwe - settlementsByMe);
  }
}
