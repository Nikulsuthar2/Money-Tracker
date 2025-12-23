import 'package:async/async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/features/accounts/domain/account.dart';
import 'package:money_manager/features/accounts/data/accounts_repository.dart';
import 'package:money_manager/features/transactions/data/transactions_repository.dart';

class AccountStats {
  final Account account;
  final double balance;
  final double totalIncome;
  final double totalExpense;

  AccountStats(this.account, this.balance, this.totalIncome, this.totalExpense);
}

final accountsWithBalanceProvider = StreamProvider.autoDispose<List<AccountStats>>((ref) async* {
  final accountsRepo = ref.watch(accountsRepositoryProvider);
  final transactionsRepo = ref.watch(transactionsRepositoryProvider);

  // Combine streams to rebuild on any change
  final accountsStream = accountsRepo.watchAllAccounts();
  final transactionChanges = transactionsRepo.watchTransactions();
  
  // We yield initially and then on every change
  await for (final _ in StreamGroup.merge([accountsStream, transactionChanges])) {
     final accounts = await accountsRepo.getAllAccounts();
     final List<AccountStats> list = [];
     for (final account in accounts) {
       // We need a method that returns structured stats
       // For now, let's assume we update the repository to simply return a Map or similar, 
       // but since I can't see repo file here, I will rely on existing or add new ones?
       // Let's modify Repo to return Stats object later. For now, I'll call getAccountBalance, 
       // but I really need income/expense separately.
       // I'll call a new method `getAccountStats` which I will implement in Repo next.
       final stats = await transactionsRepo.getAccountStats(account.id, account.openingBalance);
       list.add(AccountStats(account, stats['balance']!, stats['income']!, stats['expense']!));
     }
     yield list;
  }
});
