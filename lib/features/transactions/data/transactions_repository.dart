import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/features/transactions/domain/transaction.dart';
import 'package:money_manager/core/database/isar_service.dart';

final transactionsRepositoryProvider = Provider<TransactionsRepository>((ref) {
  return TransactionsRepository(IsarService.isar);
});

final transactionsStreamProvider = StreamProvider((ref) {
  return ref.watch(transactionsRepositoryProvider).watchAllTransactions();
});

final recentTransactionsProvider = StreamProvider((ref) {
  return ref.watch(transactionsRepositoryProvider).watchRecentTransactions();
});

class TransactionsRepository {
  final Isar _isar;

  TransactionsRepository(this._isar);

  Stream<List<Transaction>> watchRecentTransactions() {
    return _isar.transactions.where().sortByDateDesc().limit(20).watch(fireImmediately: true);
  }

  Stream<List<Transaction>> watchAllTransactions() {
    return _isar.transactions.where().sortByDateDesc().watch(fireImmediately: true);
  }

  Stream<void> watchTransactions() {
    return _isar.transactions.watchLazy();
  }

  Future<void> addTransaction(Transaction transaction) async {
    await _isar.writeTxn(() async {
      await _isar.transactions.put(transaction);
    });
  }

  Future<void> updateTransaction(Transaction transaction) async {
    await _isar.writeTxn(() async {
      await _isar.transactions.put(transaction);
    });
  }

  Future<void> deleteTransaction(Id id) async {
    await _isar.writeTxn(() async {
      await _isar.transactions.delete(id);
    });
  }
  
  // Balance Calculation Logic
  Future<double> getAccountBalance(Id accountId, double openingBalance) async {
    final income = await _isar.transactions
        .filter()
        .skipFromStatsEqualTo(false)
        .typeEqualTo(TransactionType.income)
        .and()
        .toAccountIdEqualTo(accountId)
        .amountProperty()
        .sum();
        
    final expense = await _isar.transactions
        .filter()
        .skipFromStatsEqualTo(false)
        .typeEqualTo(TransactionType.expense)
        .and()
        .fromAccountIdEqualTo(accountId)
        .amountProperty()
        .sum();
    
    final transferOut = await _isar.transactions
        .filter()
        .skipFromStatsEqualTo(false)
        .typeEqualTo(TransactionType.transfer)
        .and()
        .fromAccountIdEqualTo(accountId)
        .amountProperty()
        .sum();
        
    final transferIn = await _isar.transactions
        .filter()
        .skipFromStatsEqualTo(false)
        .typeEqualTo(TransactionType.transfer)
        .and()
        .toAccountIdEqualTo(accountId)
        .amountProperty()
        .sum();
        
    return openingBalance + income - expense - transferOut + transferIn;
  }

  Future<Map<String, double>> getAccountStats(Id accountId, double openingBalance) async {
    final income = await _isar.transactions
        .filter()
        .skipFromStatsEqualTo(false)
        .typeEqualTo(TransactionType.income)
        .and()
        .toAccountIdEqualTo(accountId)
        .amountProperty()
        .sum();
        
    final expense = await _isar.transactions
        .filter()
        .skipFromStatsEqualTo(false)
        .typeEqualTo(TransactionType.expense)
        .and()
        .fromAccountIdEqualTo(accountId)
        .amountProperty()
        .sum();
    
    final transferOut = await _isar.transactions
        .filter()
        .skipFromStatsEqualTo(false)
        .typeEqualTo(TransactionType.transfer)
        .and()
        .fromAccountIdEqualTo(accountId)
        .amountProperty()
        .sum();
        
    final transferIn = await _isar.transactions
        .filter()
        .skipFromStatsEqualTo(false)
        .typeEqualTo(TransactionType.transfer)
        .and()
        .toAccountIdEqualTo(accountId)
        .amountProperty()
        .sum();
    
    final totalBalance = openingBalance + income - expense - transferOut + transferIn;
    // Note: 'income' here strictly means Income type + Transfers In? Or just Income type?
    // User requested "Total Income/Expense" per account. 
    // Usually means: Money IN vs Money OUT.
    final totalIn = income + transferIn;
    final totalOut = expense + transferOut;

    return {
      'balance': totalBalance,
      'income': totalIn,
      'expense': totalOut,
    };
  }
}
