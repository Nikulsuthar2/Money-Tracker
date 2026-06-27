import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/features/transactions/domain/transaction.dart';
import 'package:money_manager/features/ledger/domain/ledger_entry.dart';
import 'package:money_manager/core/database/database_provider.dart';
import 'package:money_manager/core/database/app_database.dart';
import 'package:drift/drift.dart' as drift;

final transactionsRepositoryProvider = Provider<TransactionsRepository>((ref) {
  return TransactionsRepository(ref.watch(databaseProvider));
});

final transactionsStreamProvider = StreamProvider((ref) {
  return ref.watch(transactionsRepositoryProvider).watchAllTransactions();
});

final recentTransactionsProvider = StreamProvider((ref) {
  return ref.watch(transactionsRepositoryProvider).watchRecentTransactions();
});

extension TransactionDataMapper on TransactionData {
  Transaction toDomain() {
    return Transaction()
      ..id = id
      ..type = TransactionType.values.firstWhere((e) => e.name == type)
      ..amount = amount
      ..currency = currency
      ..fromAccountId = fromAccountId
      ..toAccountId = toAccountId
      ..categoryId = categoryId
      ..title = title
      ..note = note
      ..date = date
      ..isSettlement = isSettlement
      ..hasTime = (date.toLocal().hour != 0 || date.toLocal().minute != 0 || date.toLocal().second != 0)
      ..principalAmount = principalAmount
      ..createdAt = createdAt
      ..updatedAt = updatedAt;
  }
}

class TransactionsRepository {
  final AppDatabase _db;

  TransactionsRepository(this._db);

  Stream<List<Transaction>> watchRecentTransactions() {
    return (_db.select(_db.transactions)..orderBy([(t) => drift.OrderingTerm.desc(t.date), (t) => drift.OrderingTerm.desc(t.id)])..limit(20))
        .watch()
        .map((list) => list.map((e) => e.toDomain()).toList());
  }

  Stream<List<Transaction>> watchAllTransactions() {
    return (_db.select(_db.transactions)..orderBy([(t) => drift.OrderingTerm.desc(t.date), (t) => drift.OrderingTerm.desc(t.id)]))
        .watch()
        .map((list) => list.map((e) => e.toDomain()).toList());
  }

  Future<List<Transaction>> getRefundTransactions(int id) async => [];
  Future<List<LedgerEntry>> getLedgerEntries(int id) async => [];

  Stream<void> watchTransactions() {
    return watchAllTransactions();
  }

  Future<int> addTransaction(Transaction transaction) async {
    return await _db.into(_db.transactions).insert(TransactionsCompanion.insert(
      type: transaction.type.name,
      amount: transaction.amount,
      currency: drift.Value(transaction.currency),
      fromAccountId: drift.Value(transaction.fromAccountId),
      toAccountId: drift.Value(transaction.toAccountId),
      categoryId: drift.Value(transaction.categoryId),
      title: drift.Value(transaction.title),
      note: drift.Value(transaction.note),
      date: transaction.date,
      isSettlement: drift.Value(transaction.isSettlement),
      principalAmount: drift.Value(transaction.principalAmount),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  }

  Future<void> updateTransaction(Transaction transaction) async {
    await _db.update(_db.transactions).replace(TransactionData(
      id: transaction.id,
      type: transaction.type.name,
      amount: transaction.amount,
      currency: transaction.currency,
      fromAccountId: transaction.fromAccountId,
      toAccountId: transaction.toAccountId,
      categoryId: transaction.categoryId,
      title: transaction.title,
      note: transaction.note,
      date: transaction.date,
      isSettlement: transaction.isSettlement,
      principalAmount: transaction.principalAmount,
      createdAt: transaction.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  }

  Future<void> deleteTransaction(int id) async {
    await (_db.delete(_db.transactions)..where((t) => t.id.equals(id))).go();
  }
  
  Future<Transaction?> getTransaction(int id) async {
    final data = await (_db.select(_db.transactions)..where((t) => t.id.equals(id))).getSingleOrNull();
    return data?.toDomain();
  }

  Future<double> getAccountBalance(int accountId, double openingBalance) async {
    final list = await _db.select(_db.transactions).get();
    
    double income = list.where((t) => t.toAccountId == accountId && (t.type == 'income' || t.type == 'sellInvestment')).fold(0.0, (s, t) => s + t.amount);
    double expense = list.where((t) => t.fromAccountId == accountId && (t.type == 'expense' || t.type == 'buyInvestment')).fold(0.0, (s, t) => s + t.amount);
    double transferIn = list.where((t) => t.toAccountId == accountId && t.type == 'transfer').fold(0.0, (s, t) => s + t.amount);
    double transferOut = list.where((t) => t.fromAccountId == accountId && t.type == 'transfer').fold(0.0, (s, t) => s + t.amount);
    
    return openingBalance + income - expense + transferIn - transferOut;
  }

  Future<double> getInvestedBalance(int accountId) async {
    final list = await _db.select(_db.transactions).get();
    
    double invested = list.where((t) => t.fromAccountId == accountId && t.type == 'buyInvestment').fold(0.0, (s, t) => s + t.amount);
    double withdrawn = list.where((t) => t.toAccountId == accountId && t.type == 'sellInvestment').fold(0.0, (s, t) => s + (t.principalAmount ?? t.amount));
    
    return invested - withdrawn;
  }

  Future<Map<String, double>> getAccountStats(int accountId, double openingBalance) async {
    final list = await _db.select(_db.transactions).get();
    
    double income = list.where((t) => t.toAccountId == accountId && (t.type == 'income' || t.type == 'sellInvestment')).fold(0.0, (s, t) => s + t.amount);
    double expense = list.where((t) => t.fromAccountId == accountId && (t.type == 'expense' || t.type == 'buyInvestment')).fold(0.0, (s, t) => s + t.amount);
    double transferIn = list.where((t) => t.toAccountId == accountId && t.type == 'transfer').fold(0.0, (s, t) => s + t.amount);
    double transferOut = list.where((t) => t.fromAccountId == accountId && t.type == 'transfer').fold(0.0, (s, t) => s + t.amount);
    
    final balance = openingBalance + income - expense + transferIn - transferOut;

    return {
      'balance': balance,
      'income': income + transferIn,
      'expense': expense + transferOut,
      'reimbursed': 0.0, // Deprecated in V1
    };
  }

  Future<Map<String, double>> getAccountMonthlyStats(int accountId, double openingBalance, DateTime month) async {
    final allTxns = await _db.select(_db.transactions).get();
    
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);

    // Calculate all-time balance
    final balance = await getAccountBalance(accountId, openingBalance);

    // Filter monthly
    final monthlyList = allTxns.where((t) => t.date.isAfter(start.subtract(const Duration(milliseconds: 1))) && t.date.isBefore(end)).toList();
    
    double monthlyIncome = monthlyList.where((t) => t.toAccountId == accountId && (t.type == 'income' || t.type == 'sellInvestment')).fold(0.0, (s, t) => s + t.amount);
    double monthlyExpense = monthlyList.where((t) => t.fromAccountId == accountId && (t.type == 'expense' || t.type == 'buyInvestment')).fold(0.0, (s, t) => s + t.amount);
    double monthlyTransferIn = monthlyList.where((t) => t.toAccountId == accountId && t.type == 'transfer').fold(0.0, (s, t) => s + t.amount);
    double monthlyTransferOut = monthlyList.where((t) => t.fromAccountId == accountId && t.type == 'transfer').fold(0.0, (s, t) => s + t.amount);

    return {
      'balance': balance,
      'income': monthlyIncome + monthlyTransferIn,
      'expense': monthlyExpense + monthlyTransferOut,
      'reimbursed': 0.0, // Deprecated in V1
    };
  }
}
